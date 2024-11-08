import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/cart_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CartPage extends StatefulWidget {
  final String email;
  final String language;

  CartPage({required this.email, this.language = 'english'});

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
      'key': 'rzp_test_iRK7aDGG0C6UAR',
      'amount': amount * 100,
      'name': 'Somato',
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

  void _handlePaymentSuccessWeb(dynamic response) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.paymentReceived ?? "We received your payment!",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
    
    final cart = Provider.of<CartModel>(context, listen: false);
    await cart.placeOrder(context, widget.email, response['razorpay_payment_id']);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${AppLocalizations.of(context)?.paymentSuccessful ?? 'Payment successful!'} ID: ${response.paymentId}",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${AppLocalizations.of(context)?.paymentFailed ?? 'Payment failed.'} ${response.message}",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${AppLocalizations.of(context)?.walletSelected ?? 'Wallet selected:'} ${response.walletName}",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cart, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    l10n.cartEmpty,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final currentLocale = Localizations.localeOf(context);
                final itemName = currentLocale.languageCode == 'hi' 
                    ? cart.items[index]['name_hi'] 
                    : cart.items[index]['name'];

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16.0),
                    title: Text(itemName),
                    subtitle: Text('${l10n.price}: ₹${cart.items[index]['price']}'),
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
        child: Text(l10n.placeOrder, style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
        ),
      ),
    ],
  ),
),
    );
  }
}