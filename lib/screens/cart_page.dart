import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_model.dart';

class CartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: cart.items.isEmpty
          ? Center(child: Text('Your cart is empty'))
          : ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Text(cart.items[index]['name']),
                    subtitle: Text('Price: ₹${cart.items[index]['price']}'),
                    trailing: IconButton(
                      icon: Icon(Icons.remove_circle),
                      onPressed: () {
                        // Pass BuildContext to removeItem method
                        cart.removeItem(index, context);
                      },
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total: ₹${cart.totalPrice.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: cart.items.isEmpty
                  ? null
                  : () async {
                      // Replace with actual user ID logic
                      final String userId = "YOUR_USER_ID";
                      
                      // Place the order and handle the result
                      await cart.placeOrder(context, userId);
                      
                      // Navigate back after placing the order
                      Navigator.pop(context);
                    },
              child: Text('Place Order'),
            ),
          ],
        ),
      ),
    );
  }
}
