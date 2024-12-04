import 'package:flutter/material.dart';

class DoctorCard extends StatelessWidget {
  final String name;
  final String specialization;
  final String image;
  final VoidCallback onTap;
  final Widget? child; // Allows adding child widgets like the appointment icon.

  const DoctorCard({
    super.key,
    required this.name,
    required this.specialization,
    required this.image,
    required this.onTap,
    this.child, // Optional child widget
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Doctor's image and details
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage(image),
                    radius: 30,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        specialization,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Optional child (like an appointment icon)
              if (child != null) child!,
            ],
          ),
        ),
      ),
    );
  }
}
