import 'package:flutter/material.dart';

class CartModel extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

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
