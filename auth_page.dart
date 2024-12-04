import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncare/pages/signup.dart';
import 'home.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Optionally show a loading spinner while waiting for the auth state
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            // When user is logged in, navigate to the homepage and remove previous routes
            Future.microtask(() => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                ));
            return Container(); // Placeholder to prevent StreamBuilder from rebuilding
          } else {
            // If user is not logged in, show the login or register screen
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
}
