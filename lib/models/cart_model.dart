import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartModel extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  int get itemCount => _items.length; // Get the number of items in the cart

  void addItem(Map<String, dynamic> item, BuildContext context) {
    _items.add(item);
    notifyListeners();
    _showNotification(context, 'Item added to cart!'); // Show notification
  }

  void removeItem(int index, BuildContext context) {
    _items.removeAt(index);
    notifyListeners();
    _showNotification(context, 'Item removed from cart!'); // Show notification
  }

  double get totalPrice => _items.fold(0, (sum, item) => sum + (item['price'] as num));

  Future<void> placeOrder(BuildContext context, String userEmail) async {
    if (_items.isEmpty) return;

    // Prepare order data
    final orderData = {
      'items': _items.map((item) => item['name']).toList(),
      'totalPrice': totalPrice,
      'user_email': userEmail,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      // Save the order to Firestore
      await FirebaseFirestore.instance.collection('orders').add(orderData);
      _showNotification(context, 'Order Placed Successfully!');
    } catch (e) {
      print('Error placing order: $e');
      _showNotification(context, 'Failed to place order!');
      return;
    }

    // Clear the cart after successful order placement
    clearCart(context);
  }

  void clearCart(BuildContext context) {
    _items.clear();
    notifyListeners();
    _showNotification(context, 'Cart cleared!'); // Show notification
  }

  void _showNotification(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: Colors.white), // Set text color to white
      ),
      backgroundColor: Colors.red, // Set background color to red
      duration: const Duration(seconds: 2), // Duration for the SnackBar
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar); // Show the SnackBar
  }
}
