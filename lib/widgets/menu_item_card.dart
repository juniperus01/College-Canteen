import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cart_model.dart';

// Function to call the Flask API
Future<double> fetchEstimatedWaitTime(String itemName) async {
  final now = DateTime.now();
  String orderTime = DateFormat.Hm().format(now); // Format: "HH:mm"
  String dayOfWeek = DateFormat('EEEE').format(now); // Get full day name

  Map<String, dynamic> requestBody = {
    'item_name': itemName,
    'order_time': orderTime,
    'day_of_week': dayOfWeek,
  };

  final response = await http.post(
    Uri.parse('http://192.168.0.102:5000/estimate_wait_time'), // Replace with your server's URL if different
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(requestBody),
  );

  if (response.statusCode == 200) {
    var responseData = jsonDecode(response.body);
    return responseData['estimated_wait_time'];
  } else {
    throw Exception('Failed to get estimated wait time');
  }
}

class MenuItemCard extends StatelessWidget {
  final String category;
  final Map<String, dynamic> item;
  final bool isAdmin, isInside;

  MenuItemCard({required this.category, required this.item, required this.isAdmin, required this.isInside});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMenuItemCard(context),
      ],
    );
  }

   Widget _buildMenuItemCard(BuildContext context) {
    final String name = item['name'] ?? 'Unnamed Item'; // Default if 'name' is null
    final double price = item['price'] != null ? item['price'].toDouble() : 0.0; // Default price
    final String itemId = item['id'] ?? ''; // Handle null 'id'
    bool isAvailable = item['available'] ?? true; // Default to true if not set
    Color textColor = isAvailable ? Colors.black : Colors.grey.shade600; // Original color if available, lighter if unavailable

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            isAdmin
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAvailable ? Colors.red.withOpacity(0.7) : Colors.red.withOpacity(0.7),
                    ),
                    child: IconButton(
                      icon: Icon(isAvailable ? Icons.remove : Icons.add, color: Colors.white),
                      onPressed: () {
                        if (isAvailable) {
                          _showDeleteConfirmation(context, category, itemId, name);
                        } else {
                          _markItemAsAvailable(context, category, itemId);
                        }
                      },
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      item['image'] ?? 'assets/images/default_image.jpg',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Price: ₹$price',
                    style: TextStyle(color: textColor),
                  ),
                  // Display estimated wait time only for non-admin users and available items
                  if (!isAdmin && isAvailable) ...[
                    FutureBuilder<double>(
                      future: fetchEstimatedWaitTime(name),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Text('Estimating...', style: TextStyle(color: textColor));
                        } else if (snapshot.hasError) {
                          print(snapshot.error);
                          return Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red));
                        } else {
                          return Text(
                            'Estimated Time: ${snapshot.data?.toStringAsFixed(2)} mins',
                            style: TextStyle(color: textColor),
                          );
                        }
                      },
                    ),
                  ] else if (!isAvailable) ...[
                    Text(
                      'Unavailable',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
            isAdmin
                ? ElevatedButton(
                    onPressed: () {
                      _showModifyDialog(context, category, itemId, item);
                    },
                    child: Text('Modify'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  )
                : ElevatedButton(
                    onPressed: isInside && isAvailable
                        ? () {
                            Provider.of<CartModel>(context, listen: false).addItem(item, context);
                          }
                        : null,
                    child: Text('Add'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: isInside && isAvailable ? Colors.red : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

Future<void> _markItemAsAvailable(BuildContext context, String category, String itemId) async {
  try {
    CollectionReference collectionRef = FirebaseFirestore.instance.collection(category);
    DocumentReference documentRef = collectionRef.doc(itemId);

    // Use a transaction to ensure the update is atomic
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(documentRef);

      if (snapshot.exists) {
        // Update the 'available' field to true
        transaction.update(documentRef, {'available': true});
      } else {
        _showSnackBar(context, 'Item does not exist!');
      }
    });

    _showSnackBar(context, 'Item is available now!');
  } catch (e) {
    print('Error marking item as available: $e');
    _showSnackBar(context, 'Error marking item as available: $e');
  }
}


  void _showModifyDialog(BuildContext context, String category, String itemId, Map<String, dynamic> item) {
    // Prevent modification if itemId is null or empty
    if (itemId.isEmpty) {
      _showSnackBar(context, 'Error: Item ID is missing');
      return;
    }

    final TextEditingController nameController = TextEditingController(text: item['name']);
    final TextEditingController priceController = TextEditingController(text: item['price']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modify ${item['name'] ?? 'Unnamed Item'}'),
          content: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _updateItemInFirestore(context, category, itemId, {
                  'name': nameController.text,
                  'price': double.tryParse(priceController.text) ?? item['price'],
                });
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateItemInFirestore(BuildContext context, String category, String itemId, Map<String, dynamic> updatedData) async {
    try {
      CollectionReference collectionRef = FirebaseFirestore.instance.collection(category);
      await collectionRef.doc(itemId).update(updatedData);
      _showSnackBar(context, 'Item updated successfully!');
    } catch (e) {
      print('Error updating item: $e');
      _showSnackBar(context, 'Error updating item: $e');
    }
  }

  void _showDeleteConfirmation(BuildContext context, String category, String itemId, String itemName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hide $itemName'),
          content: Text("Are you sure you want to mark it as 'Unavailable'?"),
          actions: [
            TextButton(
              onPressed: () async {
                await _markItemAsUnavailable(context, category, itemId);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItemFromFirestore(BuildContext context, String category, String itemId) async {
    try {
      CollectionReference collectionRef = FirebaseFirestore.instance.collection(category);
      await collectionRef.doc(itemId).delete();
      _showSnackBar(context, 'Item deleted successfully!');
    } catch (e) {
      print('Error deleting item: $e');
      _showSnackBar(context, 'Error deleting item: $e');
    }
  }

  Future<void> _markItemAsUnavailable(BuildContext context, String category, String itemId) async {
  try {
    CollectionReference collectionRef = FirebaseFirestore.instance.collection(category);
    DocumentReference documentRef = collectionRef.doc(itemId);

    // Use a transaction to ensure the update is atomic
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(documentRef);

      if (snapshot.exists) {
        // Update the 'available' field to false regardless of its prior existence
        transaction.update(documentRef, {'available': false});
      } else {
        _showSnackBar(context, 'Item does not exist!');
      }
    });

    _showSnackBar(context, 'Item is not available now!');
  } catch (e) {
    print('Error marking item as unavailable: $e');
    _showSnackBar(context, 'Error marking item as unavailable: $e');
  }
}


  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red, // Red background
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white, // White action text
          onPressed: () {},
        ),
      ),
    );
  }
}
