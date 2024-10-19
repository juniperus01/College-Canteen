import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_model.dart';

class MenuItemCard extends StatelessWidget {
  final String category;
  final Map<String, dynamic> item;
  final bool isAdmin;

  MenuItemCard({required this.category, required this.item, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add New Item button
        isAdmin
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () {
                    _showAddItemDialog(context, category);
                  },
                  child: Text('Add New Item'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            : SizedBox.shrink(), // Hide the button for non-admin users
        // Existing item card
        _buildMenuItemCard(context),
      ],
    );
  }

  Widget _buildMenuItemCard(BuildContext context) {
    // Use null-aware operators to handle missing data
    final String name = item['name'] ?? 'Unnamed Item'; // Default if 'name' is null
    final double price = item['price'] != null ? item['price'].toDouble() : 0.0; // Default price
    final String itemId = item['id'] ?? ''; // Handle null 'id'

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Minus icon enclosed in a red circle for admin
            isAdmin
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.7), // Red opaque background
                    ),
                    child: IconButton(
                      icon: Icon(Icons.remove, color: Colors.white),
                      onPressed: () {
                        _showDeleteConfirmation(context, category, itemId, name);
                      },
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      item['image'] ?? 'assets/images/default_image.jpg', // Default image
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
                    name, // Use the default name if null
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('Price: ₹$price'),
                  Text('Estimated Time: 20'), // You may want to make this dynamic too
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
                    onPressed: () {
                      Provider.of<CartModel>(context, listen: false).addItem(item, context);
                    },
                    child: Text('Add'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, String category) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController estimatedTimeController = TextEditingController(text: '20'); // Placeholder

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Item'),
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
                TextField(
                  controller: estimatedTimeController,
                  decoration: InputDecoration(labelText: 'Estimated Time'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _addItemToFirestore(context, category, {
                  'name': nameController.text,
                  'price': double.tryParse(priceController.text) ?? 0.0,
                  'estimated_time': estimatedTimeController.text,
                });
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Add'),
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

  Future<void> _addItemToFirestore(BuildContext context, String category, Map<String, dynamic> newItemData) async {
    try {
      CollectionReference collectionRef = FirebaseFirestore.instance.collection(category);
      await collectionRef.add(newItemData);
      _showSnackBar(context, 'Item added successfully!');
    } catch (e) {
      print('Error adding item: $e');
      _showSnackBar(context, 'Error adding item: $e');
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
    final TextEditingController estimatedTimeController = TextEditingController(text: '20'); // Placeholder

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
                TextField(
                  controller: estimatedTimeController,
                  decoration: InputDecoration(labelText: 'Estimated Time'),
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
                  'estimated_time': estimatedTimeController.text, // Add estimated time
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
          title: Text('Delete $itemName'),
          content: Text('Are you sure you want to remove this item from the menu?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteItemFromFirestore(context, category, itemId);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Delete'),
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

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
