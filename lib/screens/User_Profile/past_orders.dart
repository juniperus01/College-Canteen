import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class PastOrdersPage extends StatefulWidget {
  final String email;

  PastOrdersPage({required this.email});

  @override
  _PastOrdersPageState createState() => _PastOrdersPageState(email: email);
}

class _PastOrdersPageState extends State<PastOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> orders = [];
  bool _isLoading = true;

  final String email;

  _PastOrdersPageState({required this.email});

  @override
  void initState() {
    super.initState();
    _fetchPastOrders();
  }

  Future<void> _fetchPastOrders() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('user_email', isEqualTo: email) // Fetch only the orders of the current user
          .where('status', isEqualTo: 'completed') // Filter for completed orders
          .orderBy('timestamp', descending: true) // Sort by timestamp in descending order
          .get();

      setState(() {
        // Directly populate the orders list
        orders = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching past orders: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('d MMM yyyy, hh:mm a').format(date); // Format date as '26 Oct 2024, 12:30 PM'
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Past Orders', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(child: Text('No past orders available'))
              : ListView.builder(
                  padding: EdgeInsets.all(16.0),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final items = List<Map<String, dynamic>>.from(order['items']);
                    final formattedDate = _formatDate(order['timestamp']);
                    final double totalPrice = order['totalPrice'];

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Date and time heading with red background and white font, left-aligned
                          Container(
                            padding: EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                              ),
                            ),
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.left, // Left-aligned text
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListTile(
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Display all items in the order
                                  ...items.map((item) {
                                    final itemName = item['name'];
                                    final itemQuantity = item['quantity'] ?? 1; // Default to 1 if quantity is missing
                                    final itemPrice = item['price'] ?? 0.0; // Default to 0.0 if price is missing
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.fastfood, color: Colors.grey), // Food icon
                                            SizedBox(width: 8),
                                            Text(itemName),
                                          ],
                                        ),
                                        Text('x$itemQuantity', style: TextStyle(color: Colors.grey)), // Quantity on the right
                                      ],
                                    );
                                  }).toList(),
                                  SizedBox(height: 4),
                                ],
                              ),
                            ),
                          ),
                          // Total Price with grey background and red font at the bottom
                          Container(
                            padding: EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                            ),
                            child: Text(
                              'Total: ₹${totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right, // Right-aligned text
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
