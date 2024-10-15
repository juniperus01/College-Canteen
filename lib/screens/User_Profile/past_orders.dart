import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PastOrdersPage extends StatefulWidget {
  final String email;

  PastOrdersPage({required this.email});
  
  @override
  _PastOrdersPageState createState() => _PastOrdersPageState(email: email);
}

class _PastOrdersPageState extends State<PastOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> pastOrders = [];
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
          .get();

      setState(() {
        pastOrders = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching past orders: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
<<<<<<< HEAD
        title: Text('Past Orders'),
      ),
=======
        title: Text('Past Orders', style: TextStyle(color: Colors.white)),
       backgroundColor: Colors.red),
>>>>>>> risha
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : pastOrders.isEmpty
              ? Center(child: Text('No past orders available'))
              : ListView.builder(
                  padding: EdgeInsets.all(16.0),
                  itemCount: pastOrders.length,
                  itemBuilder: (context, index) {
                    final order = pastOrders[index];
                    final items = List<String>.from(order['items']); // Ensure items are a list of strings

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        title: Text('Order ${index + 1}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...items.map((item) => Text(item)).toList(),
                            SizedBox(height: 4),
                            Text('Total: ₹${order['totalPrice']}'),
                            Text('Order Date: ${order['timestamp'].toDate()}'), // Assuming timestamp is a Firestore Timestamp
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
