import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MedicineRequestPage extends StatefulWidget {
  const MedicineRequestPage({super.key});

  @override
  _MedicineRequestPageState createState() => _MedicineRequestPageState();
}

class _MedicineRequestPageState extends State<MedicineRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _medicines = [
    'Paracetamol',
    'Ibuprofen',
    'Aspirin',
    'Amoxicillin'
  ];

  String _selectedMedicine = '';
  String _requestReason = '';
  bool _isSubmitting = false;

  // Submit medicine request
  Future<void> _submitRequest() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please log in first')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _firestore
          .collection('medicine_requests')
          .doc(user.uid)
          .collection('requests')
          .add({
        'medicine_name': _selectedMedicine,
        'reason': _requestReason,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine request submitted!')));

      // Reset form after submission
      _selectedMedicine = '';
      _requestReason = '';
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // Fetch count of approved requests
  Future<int> _getApprovedRequestCount() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final querySnapshot = await _firestore
        .collection('medicine_requests')
        .doc(user.uid)
        .collection('requests')
        .where('status', isEqualTo: 'approve') // Only approved requests
        .get();

    return querySnapshot.size;
  }

  Future<bool> _isAdmin(User user) async {
    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(user.uid).get();
      return userSnapshot.exists && userSnapshot['is_admin'] == true;
    } catch (e) {
      return false;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text('Medicine Request'),
          ),
          backgroundColor: Colors.lightBlue,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48.0),
            child: FutureBuilder<int>(
              future:
                  _getApprovedRequestCount(), // Get the approved request count
              builder: (context, snapshot) {
                int requestCount = snapshot.data ?? 0;
                return TabBar(
                  tabs: [
                    const Tab(
                      text: 'Request Medicine',
                      icon: Icon(Icons.request_page),
                    ),
                    Tab(
                      text: 'Request History',
                      icon: Stack(
                        children: [
                          const Icon(Icons.history),
                          if (requestCount > 0)
                            Positioned(
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$requestCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _buildRequestForm(),
                  _buildRequestHistory(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build request form UI
  Widget _buildRequestForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedMedicine.isEmpty ? null : _selectedMedicine,
              items: _medicines.map((medicine) {
                return DropdownMenuItem(
                  value: medicine,
                  child: Row(
                    children: [
                      const Icon(Icons.local_pharmacy),
                      const SizedBox(width: 8),
                      Text(medicine),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() => _selectedMedicine = newValue!);
              },
              decoration: const InputDecoration(
                labelText: 'Select Medicine',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a medicine';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              onChanged: (value) {
                setState(() => _requestReason = value);
              },
              decoration: const InputDecoration(
                labelText: 'Reason for Request',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a reason';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        _submitRequest();
                      }
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }

  // Build request history UI
  Widget _buildRequestHistory() {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Please log in to view requests'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('medicine_requests')
          .doc(user.uid)
          .collection('requests')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No requests submitted yet'));
        }

        final requests = snapshot.data!.docs;
        for (var request in requests) {
          String status = request['status'] ?? 'pending';
          if (status == 'approve') {
            // Show popup if status is approved
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Your request has been approved!')),
              );
            });
          }
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            String status = request['status'] ?? 'pending';
            Timestamp timestamp = request['timestamp'];

            // Apply different colors based on the status
            Color statusColor;
            if (status == 'approve') {
              statusColor = Colors.green; // Green for approved
            } else {
              statusColor = Colors.black; // Default status text color
            }

            return ListTile(
              title: Text(
                request['medicine_name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request['reason'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      bool? confirmDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: const Text(
                              'Are you sure you want to delete this request?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirmDelete == true) {
                        await request.reference.delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request deleted')));
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
