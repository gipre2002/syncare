import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncare/home_function/appointment.dart';
import 'package:syncare/home_function/availablemedicine.dart';
import 'package:syncare/home_function/medicinerequest.dart';
import 'package:syncare/home_function/studentinfo.dart';
import 'package:syncare/home_reusable/categories.dart';
import 'package:syncare/home_reusable/nurse.dart';
import 'package:syncare/home_function/profile.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userName = '';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {
      'label': 'Student Info',
      'icon': Icons.person,
      'route': '/student-info',
      'colors': [Colors.blue, Colors.blueAccent],
    },
    {
      'label': 'Request Medicine',
      'icon': Icons.medical_services_outlined,
      'route': '/request-medicine',
      'colors': [Colors.green, Colors.greenAccent],
    },
    {
      'label': 'Available Medicine',
      'icon': Icons.inventory,
      'route': '/available-medicine',
      'colors': [Colors.orange, Colors.orangeAccent],
    },
  ];

  @override
  void initState() {
    super.initState();
    _listenToAuthChanges();
  }

  // Listen to Firebase Authentication state changes
  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          _userName = user.displayName ?? '';
        });
        // Once user is authenticated, navigate to the HomePage if not already there
        if (Navigator.canPop(context)) {
          Navigator.popUntil(context, ModalRoute.withName('/'));
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  // Sign out method
  void _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }

  void _handleCategorySelection(String label) {
    switch (label) {
      case 'Student Info':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StudentInfo()),
        );
        break;
      case 'Request Medicine':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MedicineRequestPage()),
        );
        break;
      case 'Available Medicine':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AvailableMedicinePage()),
        );
        break;
      default:
        debugPrint('No route found for $label');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      body: SafeArea(
        child: _buildHomePageContent(),
      ),
    );
  }

  Widget _buildHomePageContent() {
    return Column(
      children: [
        _buildHeaderAndContent(),
      ],
    );
  }

  Widget _buildHeaderAndContent() {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF64B5F6),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContentSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome to Syncare,',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (context) {
                  return IconButton(
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    icon: const Icon(Icons.menu, color: Colors.white),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildCategoriesSection(),
            const SizedBox(height: 40),
            _buildNurseSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey),
          hintText: 'Search for categories',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final filteredCategories = _categories.where((category) {
      final label = category['label'] as String;
      return label.toLowerCase().contains(_searchQuery);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 30),
        filteredCategories.isEmpty
            ? const Center(
                child: Text(
                  'No categories match your search.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 5,
                  childAspectRatio: 1.0,
                ),
                itemCount: filteredCategories.length,
                itemBuilder: (context, index) {
                  var category = filteredCategories[index];
                  return CategoryRoundedRectangle(
                    icon: category['icon'] as IconData,
                    label: category['label'] as String,
                    gradientColors: category['colors'] as List<Color>,
                    onTap: () => _handleCategorySelection(
                        category['label'] as String),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildNurseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'USTP Campus Nurse',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 5),
        _buildNurseCard(
          name: 'Annie Lee',
          specialization: 'Nurse',
          iconColor: Colors.green,
          appointmentName: 'Book Appointment',
          imagePath: 'assets/nurse1.png',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Appointment()),
          ),
        ),
        const SizedBox(height: 15),
        _buildNurseCard(
          name: 'Johny Bravo',
          specialization: 'Nurse',
          iconColor: Colors.blue,
          appointmentName: 'Book Appointment',
          imagePath: 'assets/nurse2.png',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Appointment()),
          ),
        ),
      ],
    );
  }

  Widget _buildNurseCard({
    required String name,
    required String specialization,
    required Color iconColor,
    required String appointmentName,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return DoctorCard(
      name: name,
      specialization: specialization,
      image: imagePath,
      onTap: onTap,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: iconColor),
            onPressed: onTap,
          ),
          Text(
            appointmentName,
            style: const TextStyle(fontSize: 11, color: Colors.black),
          ),
        ],
      ),
    );
  }

 // Custom Drawer Implementation
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF64B5F6),
            ),
            child: Center(
              child: Text(
                'Welcome to Syncare',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Profile()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Sign Out'),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}