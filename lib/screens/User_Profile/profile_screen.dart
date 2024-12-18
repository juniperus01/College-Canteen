import 'package:flutter/material.dart';
import 'package:somato/screens/User_Profile/appearance.dart';
import 'package:somato/screens/User_Profile/edit_profile.dart';
import 'package:somato/screens/User_Profile/expense_tracker.dart';
import 'package:somato/screens/User_Profile/user_orders.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:somato/screens/User_Authentication/login_page.dart';

class UserProfilePage extends StatelessWidget {
  final String fullName;
  final String email;
  final String? imageUrl; // Nullable URL for the user's profile image
  final bool isInside, locationAbleToTrack;
  final String user_role;

  UserProfilePage({
    required this.fullName,
    required this.email,
    required this.isInside,
    required this.locationAbleToTrack,
    required this.user_role,
    this.imageUrl, // Optional parameter
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.white), // Correctly placed within the Text widget
        ),
        backgroundColor: Colors.red,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                  ? NetworkImage(imageUrl!) // Load the user's profile image
                  : AssetImage('assets/images/default_user_icon.png') // Default user icon
                      as ImageProvider, // Cast to ImageProvider
            ),
            SizedBox(height: 20),
            Text(
              fullName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              email,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 30),
            ListTile(
              title: Text('Your Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfilePage(fullName: this.fullName, email: this.email)),
                );
              },
            ),
            ListTile(
              title: Text('Appearance'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AppearanceSettings()),
                );
              },
            ),
            // Conditionally render 'Your Orders' and 'Track Expenses'
            if (user_role == 'customer') ...[
              ListTile(
                title: Text('Your Orders'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PastOrdersPage(email: email)),
                  );
                },
              ),
              ListTile(
                title: Text('Track Expenses'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ExpenseTrackerPage(email: email)),
                  );
                },
              ),
            ],
            ListTile(
              title: Text('Log Out'),
              onTap: () async {
                await FirebaseAuth.instance.signOut(); // Log out from Firebase
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage(isInside: isInside, locationAbleToTrack: locationAbleToTrack)), // Navigate to Login Page
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
