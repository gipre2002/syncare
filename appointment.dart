import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

class Appointment extends StatefulWidget {
  const Appointment({super.key});

  @override
  State<Appointment> createState() => _AppointmentState();
}

class _AppointmentState extends State<Appointment> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedReason;
  String? _selectedNurse;
  final List<String> _reasons = ['Checkup', 'Consultation', 'Medicine Request'];
  final List<String> _nurseNames = ['Mrs. Annie Lee', 'Mrs. John Smith'];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _approvedAppointmentCount = 0;

  @override
  void initState() {
    super.initState();
    _getApprovedAppointmentCount();
  }

  // Fetch count of approved appointments for the user
  Future<void> _getApprovedAppointmentCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final snapshot = await _firestore
        .collection('appointments')
        .doc(user.uid)
        .collection('history')
        .where('status', isEqualTo: 'approve') // Only approved appointments
        .get();

    setState(() {
      _approvedAppointmentCount = snapshot.size;
    });
  }

  Future<void> _submitAppointment() async {
    if (_formKey.currentState!.validate() &&
        _selectedReason != null &&
        _selectedNurse != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in first.')),
        );
        return;
      }

      try {
        await _firestore
            .collection('appointments')
            .doc(user.uid)
            .collection('history')
            .add({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'reason': _selectedReason,
          'date': Timestamp.fromDate(_selectedDate),
          'nurseName': _selectedNurse,
          'status': 'pending', // Keep the status as 'pending' by default
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment scheduled successfully!')),
        );
        // Reset the form after submission
        _nameController.clear();
        _phoneController.clear();
        setState(() {
          _selectedReason = null;
          _selectedNurse = null;
        });

        // Refresh the approved appointment count
        _getApprovedAppointmentCount();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule appointment: $e')),
        );
      }
    }
  }

  Stream<List<Map<String, dynamic>>> _fetchAppointments() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('appointments')
        .doc(user.uid)
        .collection('history')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList());
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('appointments')
          .doc(user.uid)
          .collection('history')
          .doc(appointmentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete appointment: $e')),
      );
    }
  }

  Widget _buildRequestForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TableCalendar(
              focusedDay: _selectedDate,
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              onDaySelected: (selectedDay, _) {
                setState(() {
                  _selectedDate = selectedDay;
                });
              },
              calendarStyle: const CalendarStyle(
                selectedDecoration:
                    BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                todayDecoration:
                    BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter your phone number' : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: const InputDecoration(
                labelText: 'Reason for Appointment',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
              ),
              items: _reasons
                  .map((reason) =>
                      DropdownMenuItem(value: reason, child: Text(reason)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedReason = value),
              validator: (value) =>
                  value == null ? 'Please select a reason' : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedNurse,
              decoration: const InputDecoration(
                labelText: 'Select Nurse',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
              ),
              items: _nurseNames
                  .map((nurse) =>
                      DropdownMenuItem(value: nurse, child: Text(nurse)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedNurse = value),
              validator: (value) =>
                  value == null ? 'Please select a nurse' : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _submitAppointment,
              icon: const Icon(Icons.send),
              label: const Text('Submit Appointment'),
              style: ElevatedButton.styleFrom(
                minimumSize:
                    const Size(double.infinity, 50), // Full width button
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentHistory() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _fetchAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No appointments found.'));
        }

        final appointments = snapshot.data!;

        // Loop through the appointments to check for status changes
        for (var appointment in appointments) {
          String status = appointment['status'] ?? 'pending';
          if (status == 'approve') {
            // Show popup if status is approved
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Your appointment has been approved!')),
              );
            });
          }
        }

        return ListView.builder(
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            DateTime appointmentDate = appointment['date'].toDate();
            DateTime twoWeeksLater =
                appointmentDate.add(const Duration(days: 14)); // 2 weeks later

            return ListTile(
              title: Text(
                appointment['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${appointment['name']}'),
                  Text('Reason: ${appointment['reason']}'),
                  Text('Nurse: ${appointment['nurseName']}'),
                  Text('Date: ${appointmentDate.toLocal()}'),
                  Text('Follow-up: ${twoWeeksLater.toLocal()}'),
                ],
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    appointment['status'] ?? 'Pending',
                    style: TextStyle(
                      color: appointment['status'] == 'approve'
                          ? Colors.green
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteAppointment(appointment['id']),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Appointment Schedule'),
          backgroundColor: const Color(0xFF64B5F6),
          bottom: TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black,
            tabs: [
              const Tab(
                  text: 'Schedule Appointment', icon: Icon(Icons.schedule)),
              Tab(
                text: 'Appointment History',
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.history),
                    if (_approvedAppointmentCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$_approvedAppointmentCount',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRequestForm(),
            _buildAppointmentHistory(),
          ],
        ),
      ),
    );
  }
}
