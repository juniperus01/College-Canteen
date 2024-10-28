import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageStaffPage extends StatefulWidget {
  @override
  _ManageStaffPageState createState() => _ManageStaffPageState();
}

class _ManageStaffPageState extends State<ManageStaffPage> {
  // Fetch the list of staff members from Firestore
  Future<List<Map<String, dynamic>>> _fetchStaff() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['admin', 'counter manager']) // Fetching users with role 'admin' or 'counter manager'
          .orderBy('createdAt') // Sorting by 'createdAt' in ascending order
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id, // Store the document ID for updates
          'email': doc['email'],
          'fullName': doc['fullName'],
          'authorised': doc['authorised'], // Fetching the 'authorised' field
          'role': doc['role'], // Fetching the 'role' field
        };
      }).toList();
    } catch (e) {
      print(e);
      throw Exception('Failed to fetch staff: $e'); // Throwing a specific error
    }
  }

  // Authorize a user
  Future<void> _authorizeUser(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'authorised': true}); // Set 'authorised' field to true
    } catch (e) {
      throw Exception('Failed to authorise user: $e'); // Handle any errors during authorization
    }
  }

  // Remove a member
  Future<void> _removeMember(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'authorised': false}); // Set 'authorised' field to false
    } catch (e) {
      throw Exception('Failed to remove member: $e'); // Handle any errors during removal
    }
  }

  // Show edit access dialog
  void _showEditAccessDialog(BuildContext context, String userId, String currentRole) {
    String? selectedRole = currentRole; // Store the currently selected role

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Access'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text('Admin'),
                value: 'admin',
                groupValue: selectedRole,
                onChanged: (value) {
                  setState(() {
                    selectedRole = value;
                  });
                },
              ),
              RadioListTile<String>(
                title: Text('Counter Manager'),
                value: 'counter manager',
                groupValue: selectedRole,
                onChanged: (value) {
                  setState(() {
                    selectedRole = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (selectedRole != null && selectedRole != currentRole) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .update({'role': selectedRole}); // Update role in Firestore
                    Navigator.of(context).pop(); // Close the dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('User role updated successfully!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    setState(() {}); // Refresh the staff list
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update role: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without saving
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(
          'Manage Staff',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(
          color: Colors.white, // Sets back arrow icon color to white
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchStaff(), // Fetching staff data
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return Center(child: Text('No staff members found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final staffMember = snapshot.data![index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4, // Add shadow effect
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
                child: ListTile(
                  title: Text(
                    staffMember['fullName'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Bold text
                      color: Colors.red, // Red color for full name
                      fontSize: 16, // Increased font size
                    ),
                  ),
                  subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Display email in italic
    Text(
      staffMember['email'],
      style: TextStyle(
        fontStyle: FontStyle.italic, // Italics for email
      ),
    ),
    SizedBox(height: 16), // Add space above the role block

    // Role display with red background and white text
    Container(
      padding: EdgeInsets.all(8), // Padding around the text
      color: Colors.white, // Red background
      child: Text(
        'Role  :   ${staffMember['role']?.toLowerCase().split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' ') ?? ''}', // Format role to lower case with capitalized first letter
        style: TextStyle(
          color: Colors.black, // White text color
          fontWeight: FontWeight.bold,
          fontSize: 16, // Increased font size for better visibility
        ),
      ),
    ),
  ],
),


                  trailing: staffMember['authorised'] == false
                      ? ElevatedButton(
                          onPressed: () async {
                            await _authorizeUser(staffMember['id']);
                            setState(() {}); // Refresh the staff list
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('User authorised successfully!'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          child: Text('Authorise'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red, // Red background
                            foregroundColor: Colors.white, // White text
                          ),
                        )
                      : PopupMenuButton(
                          icon: Icon(Icons.more_horiz),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit Access'),
                            ),
                            PopupMenuItem(
                              value: 'remove',
                              child: Text('Remove Member'),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _showEditAccessDialog(context, staffMember['id'], staffMember['role']);
                            } else if (value == 'remove') {
                              await _removeMember(staffMember['id']);
                              setState(() {}); // Refresh the staff list
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('User removed successfully!'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
