import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Ensure to import intl for DateFormat

import '../User_Profile/profile_screen.dart';

class ManageOrdersPage extends StatefulWidget {
  final String fullName;
  final String email;
  final String? imageUrl; // Nullable URL for the user's profile image

  ManageOrdersPage({
    required this.fullName,
    required this.email,
    this.imageUrl, // Optional parameter
  });

  
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
  int _selectedIndex = 0; // Track the selected index for BottomNavigationBar

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

      // Convert the Timestamp to DateTime
      DateTime timestamp = (orderData['timestamp'] as Timestamp).toDate();
      String formattedDate = _formatDate(timestamp); // Now this will work as _formatDate accepts DateTime

      if (orderData['status'] == 'pending') {
        pendingOrders.putIfAbsent(formattedDate, () => []).add(orderData);
      } else if (orderData['status'] == 'completed') {
        completedOrders.putIfAbsent(formattedDate, () => []);
        completedOrders[formattedDate]!.add(orderData);
        _completedOrdersVisibility[formattedDate] = false;
      }
    }

    // Sort pending orders by timestamp
    pendingOrders.forEach((key, orders) {
      orders.sort((a, b) => (b['timestamp'] as Timestamp).toDate().compareTo((a['timestamp'] as Timestamp).toDate()));
    });

    // Sort completed orders by timestamp
    completedOrders.forEach((key, orders) {
      orders.sort((a, b) => (b['timestamp'] as Timestamp).toDate().compareTo((a['timestamp'] as Timestamp).toDate()));
    });

    // Sort completed orders map by date
    completedOrders = Map.fromEntries(
      completedOrders.entries.toList()
        ..sort((a, b) => DateTime.parse(b.key).compareTo(DateTime.parse(a.key))),
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
        return userSnapshot.docs.first['fullName'];
      }
    } catch (e) {
      print('Error fetching customer name: $e');
    }
    return 'Unknown Customer';
  }

  String _formatDate(DateTime dateTime) {
    // Use DateFormat to format the DateTime to your desired format
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  String convertDateFormat(String date) {
    // Parse the input string into a DateTime object
    DateTime dateTime = DateTime.parse(date);
    // Format the DateTime object into the desired string format
    return DateFormat('d MMMM yyyy').format(dateTime);
  }


  String _formatTime(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('hh:mm a').format(date);
  }

  Widget _buildOrderCard(Map<String, dynamic> order, int orderNumber, {bool isPending = false}) {
    final items = List<Map<String, dynamic>>.from(order['items']);
    final double totalPrice = order['totalPrice'];
    final String userEmail = order['user_email'];
    final int _orderNumber = order.containsKey('orderNumber') ? order['orderNumber'] : orderNumber;

    return FutureBuilder<String>(
      future: _fetchCustomerName(userEmail),
      builder: (context, snapshot) {
        String customerName = snapshot.connectionState == ConnectionState.waiting ? 'Loading...' : snapshot.data ?? 'Unknown Customer';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                        'Order #$_orderNumber',
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
                          if (isPending)
                            InkWell(
                              onTap: () {
                                _showEditDialog(order);
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
                    title: Text(customerName, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...items.map((item) {
                          final itemName = item['name'];
                          final itemQuantity = item['quantity'] ?? 1;
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
        _isLoading = true;
      });
      await Future.delayed(Duration(seconds: 5));
      await _fetchOrders();
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  Future<void> _refreshOrders(BuildContext context) async {
    await Future.delayed(Duration(seconds: 1)); // Simulate a delay for loading
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Orders', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
          icon: Icon(Icons.refresh, color: Colors.white),
          onPressed: () => _refreshOrders(context),
        ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                if (_selectedIndex == 0)
                  _buildOrderSection(
                    sectionTitle: 'Pending Orders',
                    orders: pendingOrders,
                    isPending: true,
                  ),
                if (_selectedIndex == 1)
                  _buildOrderSection(
                    sectionTitle: 'Completed Orders',
                    orders: completedOrders,
                    isPending: false,
                  ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
            if (index == 2) { // Profile tab
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => UserProfilePage(
                  fullName: widget.fullName,
                  email: widget.email,
                  imageUrl: widget.imageUrl,
                  isInside: true,
                  locationAbleToTrack: true,
                  user_role: "counter manager",
                ),
              ));
            }
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pending),
            label: 'Pending Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Completed Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

Widget _buildOrderSection({
  required String sectionTitle,
  required Map<String, List<Map<String, dynamic>>> orders,
  bool isPending = false,
}) {
  // Check if there are no pending orders and display the message accordingly
  if (isPending && orders.isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text(
          'No pending orders!',
          style: TextStyle(fontSize: 16, color: Colors.red, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  List<Widget> orderWidgets = [];

  orders.forEach((date, ordersList) {
    int pendingOrdersCnt = 0;
    int completedOrdersCnt = 0;

    for (var order in ordersList) {
      if (order['status'] == 'pending') {
        pendingOrdersCnt++;
      } else {
        completedOrdersCnt++;
      }
    }
    // Sort orders by timestamp (assuming 'timestamp' is the key for the order time)
    ordersList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    // Add a header for each date with an inline dropdown icon for completed orders
    orderWidgets.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              convertDateFormat(date),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Show the dropdown icon for completed orders
          if (!isPending)
            IconButton(
              icon: Icon(
                _completedOrdersVisibility[date] == true ? Icons.expand_less : Icons.expand_more,
              ),
              onPressed: () {
                setState(() {
                  _completedOrdersVisibility[date] = !_completedOrdersVisibility[date]!;
                });
              },
            ),
        ],
      ),
    );

    // Show orders under this date
    if (isPending || (_completedOrdersVisibility[date] == true)) {
      // Initialize order number for each date
      int orderNumber = ordersList.length; // Start from 1 for each date
      for (var order in ordersList) {
        if (order['status'] == 'pending'){
          orderWidgets.add(_buildOrderCard(order, completedOrdersCnt + orderNumber, isPending: isPending));
        }
        else {
          orderWidgets.add(_buildOrderCard(order, orderNumber, isPending: isPending));
        }
        orderNumber--; // Increment for each order
      }
    }
  });

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: orderWidgets,
  );
}


}
