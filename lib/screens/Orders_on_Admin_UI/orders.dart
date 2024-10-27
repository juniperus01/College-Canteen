import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Ensure to import intl for DateFormat

class OrdersOnAdminPage extends StatefulWidget {
  @override
  _OrdersOnAdminPageState createState() => _OrdersOnAdminPageState();
}

class _OrdersOnAdminPageState extends State<OrdersOnAdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<Map<String, dynamic>>> pendingOrders = {};
  Map<String, List<Map<String, dynamic>>> completedOrders = {};
  bool _isLoading = true;
  Map<String, bool> _completedOrdersVisibility = {}; // Track visibility of completed orders

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      // Reset loading state and clear previous orders
      _isLoading = true;
      pendingOrders.clear();
      completedOrders.clear();
    });

    try {
      // Fetching all orders
      QuerySnapshot ordersSnapshot = await _firestore.collection('orders').get();

      for (var doc in ordersSnapshot.docs) {
        Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;
        orderData['id'] = doc.id;
        String formattedDate = _formatDate(orderData['timestamp']);
        
        // Organize orders by status and date
        if (orderData['status'] == 'pending') {
          pendingOrders.putIfAbsent(formattedDate, () => []).add(orderData);
        } else if (orderData['status'] == 'completed') {
          completedOrders.putIfAbsent(formattedDate, () => []);
          completedOrders[formattedDate]!.add(orderData);
          _completedOrdersVisibility[formattedDate] = false; // Initialize visibility state
        }
      }

      // Sort pending orders in ascending order
      pendingOrders.forEach((key, orders) {
        orders.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
      });

      // Sort completed orders in descending order (recent dates on top)
      completedOrders = Map.fromEntries(
        completedOrders.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key)), // Sort by keys (dates) in descending order
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _fetchCustomerName(String email) async {
    try {
      QuerySnapshot userSnapshot = await _firestore.collection('users').where('email', isEqualTo: email).get();
      if (userSnapshot.docs.isNotEmpty) {
        return userSnapshot.docs.first['fullName']; // Assuming 'fullName' is the field containing the customer name
      }
    } catch (e) {
      print('Error fetching customer name: $e');
    }
    return 'Unknown Customer';
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('d MMMM yyyy').format(date);
  }

  String _formatTime(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('hh:mm a').format(date); // Format time as hh:mm AM/PM
  }

  Widget _buildOrderCard(Map<String, dynamic> order, int orderNumber, {bool isPending = false}) {
    final items = List<Map<String, dynamic>>.from(order['items']);
    final double totalPrice = order['totalPrice'];
    final String userEmail = order['user_email']; // Assuming the email field in the order document

    return FutureBuilder<String>(
      future: _fetchCustomerName(userEmail),
      builder: (context, snapshot) {
        String customerName = snapshot.connectionState == ConnectionState.waiting ? 'Loading...' : snapshot.data ?? 'Unknown Customer';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0), // Increased spacing
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Order number heading with red background and white font
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.red,
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
                      Row(
                        children: [
                          Text(
                            _formatTime(order['timestamp']),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 8),
                          if (isPending) // Show edit icon only for pending orders
                            InkWell(
                              onTap: () {
                                _showEditDialog(order); // Show edit dialog on tap
                              },
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(customerName, style: TextStyle(fontWeight: FontWeight.bold)), // Display customer name
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
                                  Icon(Icons.fastfood, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text(itemName),
                                ],
                              ),
                              Text('x$itemQuantity', style: TextStyle(color: Colors.grey)),
                            ],
                          );
                        }).toList(),
                        SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
                // Total Price with red background and white font at the bottom
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Total: ₹${totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Order'),
          content: Text('Is the order ready?'),
          actions: [
            TextButton(
              onPressed: () {
                // Handle update order status
                _updateOrderStatus(order['id']);
                Navigator.of(context).pop();
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateOrderStatus(String documentId) async {
    try {
      await _firestore.collection('orders').doc(documentId).update({'status': 'completed'});
      // Set loading state before fetching orders again
      setState(() {
        _isLoading = true; // Set loading state
      });
      // Delay for 5 seconds before refreshing
      await Future.delayed(Duration(seconds: 5));
      // Refresh orders after update
      await _fetchOrders();
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(' All Orders', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16.0),
              children: [
                // Pending Orders Section
                Text('Pending Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                // Check if there are pending orders
                if (pendingOrders.isEmpty)
                  Center(
                    child: Text(
                      'No pending orders',
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  )
                else
                  ...pendingOrders.entries.expand((entry) {
                    String dateKey = entry.key;
                    List<Map<String, dynamic>> ordersForDate = entry.value;
                    return [
                      Text(dateKey, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ...ordersForDate.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> order = entry.value;
                        return _buildOrderCard(order, index + 1, isPending: true);
                      }).toList(),
                    ];
                  }).toList(),
                SizedBox(height: 16),
                // Completed Orders Section
                Text('Completed Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                // Check if there are completed orders
                if (completedOrders.isEmpty)
                  Center(
                    child: Text(
                      'No completed orders',
                      style: TextStyle(color: Colors.green, fontSize: 14),
                    ),
                  )
                else
                  ...completedOrders.entries.map((entry) {
                    String dateKey = entry.key;
                    List<Map<String, dynamic>> ordersForDate = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dateKey, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: Icon(
                                _completedOrdersVisibility[dateKey] == true ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  _completedOrdersVisibility[dateKey] = !_completedOrdersVisibility[dateKey]!;
                                });
                              },
                            ),
                          ],
                        ),
                        if (_completedOrdersVisibility[dateKey] == true)
                          ...ordersForDate.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map<String, dynamic> order = entry.value;
                            return _buildOrderCard(order, index + 1);
                          }).toList(),
                      ],
                    );
                  }).toList(),
              ],
            ),
    );
  }
}
