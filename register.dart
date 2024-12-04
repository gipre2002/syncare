import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncare/login_signup_forgetpass_reusable/my_button.dart';
import 'package:syncare/login_signup_forgetpass_reusable/my_textfield.dart';

class Register extends StatefulWidget {
  final VoidCallback onTap;

  const Register({required this.onTap, super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  // Text editing controllers
  final emailController = TextEditingController();
  final usernameController = TextEditingController(); // Add username controller
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Track password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Track if user has agreed to the terms
  bool _agreedToTerms = false;

  // Sign user up method
  void signUserUp() async {
    // Check if any of the fields are empty
    if (emailController.text.isEmpty ||
        usernameController.text.isEmpty || // Check for username
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        !_agreedToTerms) {
      // Check if terms are agreed
      showErrorDialog("Please fill out all fields and agree to the terms.");
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // Check if passwords match
      if (passwordController.text == confirmPasswordController.text) {
        // Attempt to create user
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // After user is created, store username in Firestore (or another backend service)
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updateDisplayName(usernameController.text.trim());
        }

        // ignore: use_build_context_synchronously
        Navigator.of(context).pop(); // Close loading dialog on success
        // Navigate to home screen or show success message
      } else {
        // Close loading dialog if passwords do not match
        Navigator.of(context).pop();
        showErrorDialog("Passwords do not match. Please re-enter.");
      }
    } on FirebaseAuthException catch (e) {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(); // Close loading dialog on error

      // Handle specific Firebase error codes
      switch (e.code) {
        case 'email-already-in-use':
          showErrorDialog(
              "This email is already registered. Try logging in or use a different email.");
          break;
        case 'invalid-email':
          showErrorDialog(
              "The email address is not valid. Please check and try again.");
          break;
        case 'weak-password':
          showErrorDialog(
              "The password is too weak. Please enter a stronger password.");
          break;
        default:
          showErrorDialog(
              e.message ?? "An unexpected error occurred. Please try again.");
      }
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image with height and width
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset('assets/logo.png', height: 150),
                  const SizedBox(height: 30),

                  // 'School Clinic Registration' title
                  const Text(
                    'School Clinic Registration',
                    style: TextStyle(
                      color: Colors.lightBlue,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Username text field
                  MyTextfield(
                    controller: usernameController, // Use usernameController
                    hinText: 'Username',
                    obsecureText: false,
                    icon: Icons.account_circle,
                    inputFormatters: const [],
                    focusNode: null,
                  ),
                  const SizedBox(height: 10),

                  // Email text field
                  MyTextfield(
                    controller: emailController,
                    hinText: 'Email',
                    obsecureText: false,
                    icon: Icons.email,
                    inputFormatters: const [],
                    focusNode: null,
                  ),
                  const SizedBox(height: 10),

                  // Password text field with visibility toggle
                  MyTextfield(
                    controller: passwordController,
                    hinText: 'Password',
                    obsecureText: _obscurePassword,
                    icon: Icons.lock,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                          8), // Limit password length to 8 characters
                    ],
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    focusNode: null,
                  ),
                  const SizedBox(height: 10),

                  // Confirm password text field with visibility toggle
                  MyTextfield(
                    controller: confirmPasswordController,
                    hinText: 'Confirm Password',
                    obsecureText: _obscureConfirmPassword,
                    icon: Icons.lock_outline,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                          8), // Limit confirm password length to 8 characters
                    ],
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    focusNode: null,
                  ),
                  const SizedBox(height: 10),

                  // Terms and Conditions Checkbox with Label
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          onChanged: (bool? value) {
                            setState(() {
                              _agreedToTerms = value!;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'I agree to the Terms & Conditions',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Register Now button
                  MyButton(onTap: signUserUp),
                  const SizedBox(height: 100),

                  // Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(color: Colors.black),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
