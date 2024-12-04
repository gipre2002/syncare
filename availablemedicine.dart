import 'package:flutter/material.dart';

class AvailableMedicinePage extends StatefulWidget {
  const AvailableMedicinePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AvailableMedicinePageState createState() => _AvailableMedicinePageState();
}

class _AvailableMedicinePageState extends State<AvailableMedicinePage> {
  // Example data to simulate available medicines with quantities
  final List<Map<String, dynamic>> availableMedicines = [
    {
      'name': 'Paracetamol',
      'description': 'Pain reliever and fever reducer',
      'quantity': 5
    },
    {
      'name': 'Aspirin',
      'description': 'Used to reduce fever and inflammation',
      'quantity': 3
    },
    {
      'name': 'Ibuprofen',
      'description': 'Anti-inflammatory medication',
      'quantity': 7
    },
    {
      'name': 'Amoxicillin',
      'description': 'Antibiotic used to treat infections',
      'quantity': 2
    },
  ];

  // Filtered list based on search query
  List<Map<String, dynamic>> filteredMedicines = [];

  // Controller for the search bar
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initially show all medicines
    filteredMedicines = availableMedicines;

    // Listen for changes in the search text
    searchController.addListener(() {
      filterMedicines();
    });
  }

  // Method to filter medicines based on search query
  void filterMedicines() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredMedicines = availableMedicines.where((medicine) {
        final medicineName = medicine['name']!.toLowerCase();
        return medicineName.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Medicines'),
        centerTitle: true,
        backgroundColor: const Color(0xFF64B5F6),
      ),
      body: Column(
        children: [
          // Subtle rounded rectangle search bar widget
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20), // Moderate rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                        0.08), // Lighter shadow for a subtle effect
                    blurRadius: 8, // Softer blur
                    offset: const Offset(0, 4), // Position of the shadow
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Search Medicines...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ),
          // Medicine list view
          Expanded(
            child: ListView.builder(
              itemCount: filteredMedicines.length,
              itemBuilder: (context, index) {
                final medicine = filteredMedicines[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  elevation: 5,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    title: Row(
                      children: [
                        Text(
                          medicine['name']!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${medicine['quantity']} available)',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(medicine['description']!),
                    leading: const Icon(Icons.local_pharmacy,
                        size: 40, color: Colors.green),
                    onTap: () {
                      // Handle on tap event (e.g., show details)
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
