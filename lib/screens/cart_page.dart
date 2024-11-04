import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/cart_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js; // Import js for web support

class CartPage extends StatefulWidget {
  final String email;

  CartPage({required this.email});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _razorpay.clear();
    }
    super.dispose();
  }

  void openCheckout(int amount) {
    var options = {
      'key': 'rzp_test_iRK7aDGG0C6UAR', // Replace with your Razorpay API key
      'amount': amount * 100, // Amount is in paise
      'name': 'College Canteen',
      'description': 'Order Payment',
      'prefill': {
        'contact': '9876543210',
        'email': widget.email,
      },
      'external': {
        'wallets': ['paytm'],
      },
    };

    if (kIsWeb) {
      // Web Platform: Use JavaScript SDK via dart:js
      try {
        final razorpayOptions = js.JsObject.jsify({
          'key': options['key'],
          'amount': options['amount'],
          'name': options['name'],
          'description': options['description'],
          'prefill': {
            'contact': (options['prefill'] as Map<String, dynamic>)['contact'],
            'email': (options['prefill'] as Map<String, dynamic>)['email'],
          },
          'handler': js.allowInterop((response) {
            // Call Dart callback on successful payment
            _handlePaymentSuccessWeb(response);
          }),
          'modal': {
            'ondismiss': js.allowInterop(() {
              print("Payment form closed");
            }),
          },
        });

        js.context.callMethod('Razorpay', [razorpayOptions]).callMethod('open');
      } catch (e) {
        debugPrint(e.toString());
      }
    } else {
      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  void _handlePaymentSuccessWeb(dynamic response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Payment successful! Payment ID: ${response['razorpay_payment_id']}"),
    ));
    // Clear cart after successful payment
    Provider.of<CartModel>(context, listen: false).clearCart();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Payment successful! Payment ID: ${response.paymentId}"),
    ));
    // Clear cart after successful payment
    Provider.of<CartModel>(context, listen: false).clearCart();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Payment failed. Error: ${response.message}"),
    ));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("External Wallet Selected: ${response.walletName}"),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        iconTheme: IconThemeData(color: Colors.white),
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
                    contentPadding: EdgeInsets.all(16.0),
                    title: Text(cart.items[index]['name']),
                    subtitle: Text('Price: ₹${cart.items[index]['price']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildIconButton(
                          icon: Icons.remove,
                          onPressed: () {
                            cart.decreaseQuantity(index, context);
                          },
                        ),
                        SizedBox(width: 10),
                        Text(
                          '${cart.items[index]['quantity']}',
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(width: 10),
                        _buildIconButton(
                          icon: Icons.add,
                          onPressed: () {
                            cart.addItem(cart.items[index], context);
                          },
                        ),
                      ],
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
                  : () {
                      openCheckout(cart.totalPrice.round());
                    },
              child: Text('Place Order', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}
