import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CartModel extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  int get itemCount => _items.length;

  void addItem(Map<String, dynamic> item, BuildContext context) {
  final existingItemIndex = _items.indexWhere((existingItem) =>
    existingItem['name'] == item['name'] && existingItem['name_hi'] == item['name_hi']);

  if (existingItemIndex >= 0) {
    _items[existingItemIndex]['quantity']++;
  } else {
    _items.add({
      'name': item['name'],      // English name
      'name_hi': item['name_hi'],  // Hindi name
      'price': item['price'],
      'quantity': 1,
    });
  }
  notifyListeners();
  _showNotification(context, 
    AppLocalizations.of(context)?.addedToCart ?? 'Item added to cart!');
}


  void decreaseQuantity(int index, BuildContext context) {
    if (_items[index]['quantity'] > 1) {
      _items[index]['quantity']--;
      _showNotification(context, 
        AppLocalizations.of(context)?.quantityDecreased ?? 'Item quantity decreased!');
    } else {
      removeItem(index, context);
    }
    notifyListeners();
  }

  void removeItem(int index, BuildContext context) {
    _items.removeAt(index);
    notifyListeners();
    _showNotification(context, 
      AppLocalizations.of(context)?.removedFromCart ?? 'Item removed from cart!');
  }

  double get totalPrice => _items.fold(0, 
    (sum, item) => sum + (item['price'] as num) * item['quantity']);

  Future<int> getNextOrderNumber() async {
    final String today = DateTime.now().toIso8601String().split('T')[0];
    DocumentReference orderCountRef =
        FirebaseFirestore.instance.collection('orderCounts').doc(today);

    int orderNumber = 0;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(orderCountRef);

      if (!snapshot.exists) {
        transaction.set(orderCountRef, {'date': today, 'count': 1});
        orderNumber = 1;
      } else {
        int currentCount = snapshot['count'];
        orderNumber = currentCount + 1;
        transaction.update(orderCountRef, {'count': orderNumber});
      }
    });

    return orderNumber;
  }

  Future<void> placeOrder(BuildContext context, String userEmail, String razorpayPaymentId) async {
    if (_items.isEmpty) return;

    int orderNumber = await getNextOrderNumber();

    final orderData = {
      'items': _items.map((item) => {
        'name': item['name'],
        'name_hi': item['name_hi'],
        'quantity': item['quantity'],
        'price': item['price'],
      }).toList(),
      'totalPrice': totalPrice,
      'user_email': userEmail,
      'timestamp': FieldValue.serverTimestamp(),
      'status': "pending",
      'orderNumber': orderNumber,
      'razorpay_payment_id': razorpayPaymentId,
    };

    try {
      await FirebaseFirestore.instance.collection('orders').add(orderData);
      _showNotification(context, 
        AppLocalizations.of(context)?.orderPlaced ?? 'Order Placed Successfully!');
    } catch (e) {
      print('Error placing order: $e');
      _showNotification(context, 
        AppLocalizations.of(context)?.orderFailed ?? 'Failed to place order!');
      return;
    }

    clearCart();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void _showNotification(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 2),
    ));
  }
}