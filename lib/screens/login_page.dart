import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_page.dart'; // For Admin
import 'menu_page.dart'; // For Customer
import 'registration_page.dart';

class LoginPage extends StatefulWidget {
  final bool isInside; // Add the isInside parameter

  // Constructor to accept the isInside value
  const LoginPage({Key? key, required this.isInside}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _loginRole = 'customer'; // By default, user logs in as customer

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch the role and name (customer/admin) from Firestore
  Future<Map<String, dynamic>> _fetchUserDetails(String uid) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
    return {
      'role': userDoc['role'],   // Assuming Firestore stores 'role' as a field
      'name': userDoc['fullName'],   // Assuming Firestore stores 'name' as a field
    };
  }

  // Email validation to ensure it belongs to Somaiya domain
  bool _isSomaiyaEmail(String email) {
    return email.endsWith('@somaiya.edu');
  }

  // Login method that checks the user role and navigates accordingly
  Future<void> _login(String role) async {
    if (_formKey.currentState!.validate()) {
      // Validate email domain
      if (!_isSomaiyaEmail(_emailController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Please use a Somaiya email address (@somaiya.edu)',
            style: TextStyle(color: Colors.red), // Red text color
          ),
          backgroundColor: Colors.white, // White background
          duration: Duration(seconds: 2),
        ));
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        User? user = userCredential.user;
        if (user != null) {
          // Fetch user role and name
          Map<String, dynamic> userDetails = await _fetchUserDetails(user.uid);
          String userRole = userDetails['role'];
          String userName = userDetails['name'];

          // Check if user wants to log in with the correct role
          if (userRole == role) {
            // Redirect to respective pages based on the role
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MenuPage(
                  email: user.email!,
                  fullName: userName,
                  role: userRole,
                  isInside: widget.isInside,
                ), // Passing name to MenuPage
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  userRole == 'customer' ? 'Please login as Customer' : 'Please login as Admin',
                  style: TextStyle(color: Colors.red), // Red text color
                ),
                backgroundColor: Colors.white, // White background
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Invalid Credentials. Please try again.',
            style: TextStyle(color: Colors.red), // Red text color
          ),
          backgroundColor: Colors.white, // White background
          duration: Duration(seconds: 2),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'An error occurred. Please try again!',
            style: TextStyle(color: Colors.red), // Red text color
          ),
          backgroundColor: Colors.white, // White background
          duration: Duration(seconds: 2),
        ));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFF5252),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 80),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/somato_logo.webp',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 60),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email, color: Color(0xFFFF5252)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color(0xFFFF5252)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock, color: Color(0xFFFF5252)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color(0xFFFF5252)),
                              ),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _isLoading ? null : () => _login('customer'),
                                child: _isLoading
                                    ? CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        'Login as Customer',
                                        style: TextStyle(color: Colors.white), // White text color
                                      ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFF5252),
                                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(width: 20),
                              ElevatedButton(
                                onPressed: _isLoading ? null : () => _login('admin'),
                                child: _isLoading
                                    ? CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        'Login as Admin',
                                        style: TextStyle(color: Colors.white), // White text color
                                      ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFF5252),
                                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  child: Text(
                    'Don\'t have an account? Sign Up',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegistrationPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
