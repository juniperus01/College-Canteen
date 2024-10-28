import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Ensure to import intl for DateFormat
import 'dart:async';

class ManageOrdersPage extends StatefulWidget {
  @override
  _ManageOrdersPageState createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<Map<String, dynamic>>> pendingOrders = {};
  Map<String, List<Map<String, dynamic>>> completedOrders = {};
  bool _isLoading = true;
  Map<String, bool> _completedOrdersVisibility = {}; // Track visibility of completed orders
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchOrders();

    // Set up the timer to call _fetchOrders every 10 seconds
    _timer = Timer.periodic(Duration(seconds: 10), (Timer t) {
      _fetchOrders();
    });
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed to avoid memory leaks
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      pendingOrders.clear();
      completedOrders.clear();
    });

    try {
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

      // Sort pending orders in ascending order for each date
      pendingOrders.forEach((key, orders) {
        orders.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
      });

      // Sort completed orders in descending order for each date
      completedOrders.forEach((key, orders) {
        orders.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
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
      setState(() {
        _isLoading = true; // Set loading state
      });
      await Future.delayed(Duration(seconds: 5));
      await _fetchOrders();
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  Future<void> _refreshOrders() async {
    await _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Orders', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white), // Set icon color to white
            onPressed: _refreshOrders, // Call refresh function on press
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16.0),
              children: [
                // Pending Orders Section
                Text('Pending Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 24.0), // Triple space above the message
                if (pendingOrders.isEmpty)
                  Center(
                    child: Text(
                      'No order is pending!',
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  ),
                SizedBox(height: 24.0), // Triple space below the message
                if (pendingOrders.isNotEmpty)
                  ...pendingOrders.entries.map((entry) {
                    String date = entry.key;
                    List<Map<String, dynamic>> orders = entry.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(date, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ...orders.asMap().entries.map((orderEntry) {
                          int orderNumber = orderEntry.key + 1; // Incremental order number
                          return _buildOrderCard(orderEntry.value, orderNumber, isPending: true);
                        }).toList(),
                        SizedBox(height: 8.0),
                      ],
                    );
                  }).toList(),



                // Completed Orders Section
                Text('Completed Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8.0),
                ...completedOrders.entries.map((entry) {
                  String date = entry.key;
                  List<Map<String, dynamic>> orders = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dropdown for completed orders visibility
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(date, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: Icon(
                              _completedOrdersVisibility[date] == true ? Icons.expand_less : Icons.expand_more,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                _completedOrdersVisibility[date] = !_completedOrdersVisibility[date]!;
                              });
                            },
                          ),
                        ],
                      ),
                      // Show completed orders only if visible
                      if (_completedOrdersVisibility[date] == true) ...orders.asMap().entries.map((orderEntry) {
                        int orderNumber = orderEntry.key + 1; // Incremental order number
                        return _buildOrderCard(orderEntry.value, orderNumber);
                      }).toList(),
                      SizedBox(height: 8.0),
                    ],
                  );
                }).toList(),
              ],
            ),
    );
  }
}
