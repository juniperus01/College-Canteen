import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:somato/screens/User_Profile/profile_screen.dart';
import 'package:somato/screens/User%20Authentication/login_page.dart';
import '../menu_page.dart'; // Import your MenuPage
import '../User_Profile/profile_screen.dart'; // Import your UserProfilePage

class RegistrationPage extends StatefulWidget {
  final bool isInside, locationAbleToTrack;

  const RegistrationPage({Key? key, required this.isInside, required this.locationAbleToTrack}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  String _selectedRole = 'Customer'; // Default role
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Email validation to ensure it belongs to Somaiya domain
  bool _isSomaiyaEmail(String email) {
    return email.endsWith('@somaiya.edu');
  }

  // Register function with role parameter
  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(_name);

        // Prepare data for Firestore
        Map<String, dynamic> userData = {
          'fullName': _name,
          'email': _email,
          'role': _selectedRole, // Store the selected role in Firestore
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Add 'authorised' field only for Admin and Counter Manager
        if (_selectedRole == 'Admin' || _selectedRole == 'Counter Manager') {
          userData['authorised'] = false; // Set default to false
        }

        // Store user data in Firestore
        await _firestore.collection('users').doc(user.uid).set(userData);

        // After registration, navigate to LoginPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(isInside: widget.isInside, locationAbleToTrack: widget.locationAbleToTrack),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred. Please try again.';
      if (e.code == 'email-already-in-use') {
        message = 'The email address is already in use.';
      } else if (e.code == 'weak-password') {
        message = 'The password is too weak.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sign Up',
          style: TextStyle(color: Colors.white), // Set text color to white
        ),
        backgroundColor: Colors.red,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                  onSaved: (value) => _name = value!,
                ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    if (!_isSomaiyaEmail(value)) {
                      return 'Please use your Somaiya email address';
                    }
                    return null;
                  },
                  onSaved: (value) => _email = value!,
                ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                  onSaved: (value) => _password = value!,
                ),
                SizedBox(height: 20),

                // Role Selection Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Select Role',
                    prefixIcon: Icon(Icons.group),
                  ),
                  items: ['Customer', 'Admin', 'Counter Manager']
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a role';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 30),

                // Register Button
                _isLoading
                    ? CircularProgressIndicator() // Show loading indicator
                    : ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            _register(); // Register with selected role
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                        ),
                        child: Text(
                          'Register',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
