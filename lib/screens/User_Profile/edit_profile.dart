import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this line for FirebaseAuth

class EditProfilePage extends StatefulWidget {
  final String fullName;
  final String email;

  EditProfilePage({required this.fullName, required this.email});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late String fullName;
  late String password;

  @override
  void initState() {
    super.initState();
    fullName = widget.fullName;
    password = ''; // Initialize password with an empty string
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: fullName,
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onSaved: (value) => fullName = value!,
              ),
              TextFormField(
                initialValue: widget.email,
                decoration: InputDecoration(
                  labelText: 'Email',
                  enabled: false, // Disable email field
                ),
                readOnly: true, // Make email field read-only
                onTap: () {
                  // Show error message when the email field is tapped
                  _showEmailEditError();
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                onSaved: (value) => password = value!,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _updateUserProfile(); // Call the function to update the profile
                  }
                },
                child: Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmailEditError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email cannot be edited.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _updateUserProfile() async {
    try {
      // First, find the user document ID using email
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Get the document ID
        String docId = snapshot.docs.first.id;

        // Update user full name in Firestore
        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'fullName': fullName,
          // Remove password here since we don't save it in Firestore anymore
        });

        // Update user password in Firebase Authentication
        User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          await user.updatePassword(password);
          // Password successfully updated in Firebase Auth

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );

          // Optionally navigate back or refresh the page
          Navigator.pop(context);
        } else {
          // Handle the case where the user is not logged in
          _showErrorMessage('User is not logged in.');
        }
      } else {
        // Handle case when user document is not found
        _showErrorMessage('User not found.');
      }
    } catch (e) {
      print('Error updating profile: $e');
      _showErrorMessage('Error updating profile: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
