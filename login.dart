import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncare/Reusable_for_login_register_forgetPass/google_button.dart';
import 'package:syncare/pages/home.dart';
import 'resetpassword.dart';
import 'package:syncare/login_signup_forgetpass_reusable/my_button.dart';
import 'package:syncare/login_signup_forgetpass_reusable/my_textfield.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onTap;

  const LoginPage({required this.onTap, super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;

  Future<void> fetchAndSaveUserData(User user) async {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      DocumentSnapshot userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        await userDocRef.set({
          'email': user.email ?? '',
          'fullName': user.displayName ?? 'No Name',
          'createdAt': FieldValue.serverTimestamp(),
        });
        log("User data saved to Firestore.");
      } else {
        bool needsUpdate = false;
        Map<String, dynamic> updatedData = {};

        if (user.displayName != userDoc['fullName']) {
          updatedData['fullName'] = user.displayName ?? 'No Name';
          needsUpdate = true;
        }

        if (user.email != userDoc['email']) {
          updatedData['email'] = user.email ?? '';
          needsUpdate = true;
        }

        if (needsUpdate) {
          await userDocRef.update(updatedData);
          log("User data updated in Firestore.");
        } else {
          log("User data is already up-to-date.");
        }
      }
    } catch (e) {
      log("Error saving/updating user data: $e");
      showErrorMessage("An error occurred while saving or updating user data.");
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        log("Google Sign-In canceled.");
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user != null) {
        log("Google Sign-In successful: ${user.displayName}");
        await fetchAndSaveUserData(user);
        _navigateToHomePage();
      }
    } catch (e) {
      log("Google Sign-In Error: $e");
      showErrorMessage("Google Sign-In failed. Please try again.");
    }
  }

  void signUserIn() async {
    if (usernameController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      showErrorMessage('Please fill in all fields.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );

      Navigator.pop(context);

      if (userCredential.user != null) {
        await fetchAndSaveUserData(userCredential.user!);
        _navigateToHomePage();
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      handleAuthError(e);
    }
  }

  void handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        showErrorMessage('No user found with this email.');
        break;
      case 'wrong-password':
        showErrorMessage('Incorrect password.');
        break;
      default:
        showErrorMessage(e.message ?? 'An authentication error occurred.');
    }
  }

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: screenHeight * 0.2,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'School Clinic Login',
                    style: TextStyle(
                      color: Colors.lightBlue,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Welcome to the School Clinic. Please log in to access your account.',
                    style: TextStyle(color: Colors.black, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  MyTextfield(
                    controller: usernameController,
                    hinText: 'Email',
                    obsecureText: false,
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 20),
                  MyTextfield(
                    controller: passwordController,
                    hinText: 'Password',
                    obsecureText: _obscurePassword,
                    icon: Icons.lock,
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
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ResetPasswordPage()),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  MyButton(onTap: signUserIn),
                  const SizedBox(height: 50),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GoogleSignInButton(onTap: signInWithGoogle),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don’t have an account?',
                        style: TextStyle(color: Colors.black),
                      ),
                      TextButton(
                        onPressed: widget.onTap,
                        child: const Text('Sign up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
