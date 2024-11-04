import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class CartModel extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  int get itemCount => _items.length;

  void addItem(Map<String, dynamic> item, BuildContext context) {
    // Check if the item already exists in the cart
    final existingItemIndex = _items.indexWhere((existingItem) => existingItem['name'] == item['name']);

    if (existingItemIndex >= 0) {
      // If the item exists, increment the quantity
      _items[existingItemIndex]['quantity']++;
    } else {
      // If it doesn't exist, add it to the cart with quantity 1
      _items.add({
        'name': item['name'],
        'price': item['price'],
        'quantity': 1,
      });
    }
    notifyListeners();
    _showNotification(context, 'Item added to cart!');
  }

  void decreaseQuantity(int index, BuildContext context) {
    if (_items[index]['quantity'] > 1) {
      // If quantity is more than 1, decrement it
      _items[index]['quantity']--;
      _showNotification(context, 'Item removed from cart!');
    } else {
      // If quantity is 1, remove the item
      removeItem(index, context);
    }
    notifyListeners();
  }

  void removeItem(int index, BuildContext context) {
    _items.removeAt(index);
    notifyListeners();
    _showNotification(context, 'Item removed from cart!'); // Show notification
  }

  double get totalPrice => _items.fold(0, (sum, item) => sum + (item['price'] as num) * item['quantity']);

  Future<int> getNextOrderNumber() async {
    // Get the current date in a consistent format
    final String today = DateTime.now().toIso8601String().split('T')[0];

    // Reference to the document for today's order count
    DocumentReference orderCountRef =
        FirebaseFirestore.instance.collection('orderCounts').doc(today);

    int orderNumber = 0;

    // Run transaction
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Try to get the document for today
      DocumentSnapshot snapshot = await transaction.get(orderCountRef);

      if (!snapshot.exists) {
        // If the document does not exist, create it with count 1
        transaction.set(orderCountRef, {'date': today, 'count': 1});
        orderNumber = 1;
      } else {
        // Increment the count field
        int currentCount = snapshot['count'];
        orderNumber = currentCount + 1;
        transaction.update(orderCountRef, {'count': orderNumber});
      }
    });

    return orderNumber;
  }

  Future<void> placeOrder(BuildContext context, String userEmail) async {
    if (_items.isEmpty) return;
    int orderNumber = await getNextOrderNumber();

    // Prepare order data with quantities
    final orderData = {
      'items': _items.map((item) => {
        'name': item['name'],
        'quantity': item['quantity'], // Include quantity here
        'price': item['price'], // Optionally include the price for reference
      }).toList(),
      'totalPrice': totalPrice,
      'user_email': userEmail,
      'timestamp': FieldValue.serverTimestamp(),
      'status' : "pending",
      'orderNumber' : orderNumber,
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
    // _showNotification(context, 'Cart cleared!'); // Show notification
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
