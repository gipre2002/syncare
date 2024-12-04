import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentInfo extends StatefulWidget {
  const StudentInfo({super.key});

  @override
  _StudentInfoState createState() => _StudentInfoState();
}

class _StudentInfoState extends State<StudentInfo> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();

  // Dropdown Options
  String? _selectedGender;
  String? _selectedYearLevel;
  String? _selectedCourse;

  // Loading State
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFirestoreData();
  }

  // Load Data from Firestore
  Future<void> _loadFirestoreData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('students')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      if (mounted) {
        setState(() {
          _firstNameController.text = data['first_name'] ?? '';
          _middleNameController.text = data['middle_name'] ?? '';
          _lastNameController.text = data['last_name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _birthdateController.text = data['birthdate'] ?? '';
          _studentIdController.text = data['student_id'] ?? '';
          _selectedYearLevel = data['year_level'];
          _selectedCourse = data['course'];
          _semesterController.text = data['semester'] ?? '';
          _selectedGender = data['gender'];
        });
      }
    }
  }

  // Save Data to Firestore
  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("User not authenticated");

        await FirebaseFirestore.instance
            .collection('students')
            .doc(_studentIdController.text.trim())
            .set({
          'first_name': _firstNameController.text.trim(),
          'middle_name': _middleNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'birthdate': _birthdateController.text.trim(),
          'gender': _selectedGender,
          'student_id': _studentIdController.text.trim(),
          'year_level': _selectedYearLevel,
          'course': _selectedCourse,
          'semester': _semesterController.text.trim(),
          'added_by': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data saved successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Clear Form Data
  void _clearForm() {
    setState(() {
      _firstNameController.clear();
      _middleNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _birthdateController.clear();
      _studentIdController.clear();
      _semesterController.clear();
      _selectedGender = null;
      _selectedYearLevel = null;
      _selectedCourse = null;
    });
  }

  // Build Input Field
  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      bool readOnly = false,
      VoidCallback? onTap}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
      readOnly: readOnly,
      onTap: onTap,
    );
  }

  // Dropdown Fields
  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select $label';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Information'),
        backgroundColor: const Color(0xFF64B5F6),
        actions: [
          IconButton(
            onPressed: _clearForm,
            icon: const Icon(Icons.clear),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'General Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Student ID', _studentIdController),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Year Level',
                      items: ['1st Year', '2nd Year', '3rd Year', '4th Year'],
                      selectedValue: _selectedYearLevel,
                      onChanged: (value) => setState(() {
                        _selectedYearLevel = value;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Course',
                items: ['BSIT', 'BFPT', 'EDUC-HE', 'EDUC-ICT', 'EDUC-AI'],
                selectedValue: _selectedCourse,
                onChanged: (value) => setState(() {
                  _selectedCourse = value;
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('First Name', _firstNameController),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child:
                        _buildTextField('Middle Name', _middleNameController),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField('Last Name', _lastNameController),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Email', _emailController),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField('Phone', _phoneController,
                        keyboardType: TextInputType.phone),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Birthdate',
                      _birthdateController,
                      readOnly: true,
                      onTap: () async {
                        DateTime? selectedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (selectedDate != null) {
                          _birthdateController.text =
                              "${selectedDate.toLocal()}".split(' ')[0];
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Gender',
                      items: ['Male', 'Female', 'Other'],
                      selectedValue: _selectedGender,
                      onChanged: (value) => setState(() {
                        _selectedGender = value;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('Semester', _semesterController),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveData,
                      child: const Text('Save Data'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
