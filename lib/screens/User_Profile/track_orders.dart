import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TrackOrdersPage extends StatelessWidget {
  final String email;

  TrackOrdersPage({required this.email});

  Future<void> _refreshOrders(BuildContext context) async {
    await Future.delayed(Duration(seconds: 1)); // Simulate a delay for loading
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Your Orders', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous page
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _refreshOrders(context);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshOrders(context),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('user_email', isEqualTo: email)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No orders found'));
            }

            final orders = snapshot.data!.docs;

            // Sort orders by status (pending first) and then by timestamp (latest first)
            orders.sort((a, b) {
              var orderA = a.data() as Map<String, dynamic>;
              var orderB = b.data() as Map<String, dynamic>;
              Timestamp timestampA = orderA['timestamp'] as Timestamp;
              Timestamp timestampB = orderB['timestamp'] as Timestamp;

              int statusComparison = (orderA['status'] == 'pending' ? 0 : 1)
                  .compareTo(orderB['status'] == 'pending' ? 0 : 1);
              if (statusComparison != 0) {
                return statusComparison; // Sort by status first
              }
              return timestampB.compareTo(timestampA); // Then sort by timestamp (latest first)
            });

            return ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                var order = orders[index].data() as Map<String, dynamic>;
                Timestamp timestamp = order['timestamp'] as Timestamp;
                String formattedDate = DateFormat('d MMM yyyy, hh:mm a').format(timestamp.toDate());
                double totalPrice = order['totalPrice'] ?? 0.0;
                List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(order['items']);
                String status = order['status'] ?? 'pending';
                int orderNumber = order['orderNumber'] ?? 0; // Replace with your field name

                // Determine heading color based on status
                Color headingColor = status == 'completed' ? Colors.green : Colors.orange;

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Heading with dynamic background color, order number, and formatted date or Processing message
                      Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: headingColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #$orderNumber',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              status == 'pending' ? 'Processing...' : formattedDate,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
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
            );
          },
        ),
      ),
    );
  }
}
