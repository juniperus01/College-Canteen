import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:somato/models/cart_model.dart'; // Ensure you have the CartModel imported

class PastOrdersPage extends StatefulWidget {
  @override
  _PastOrdersPageState createState() => _PastOrdersPageState();
}

class _PastOrdersPageState extends State<PastOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> pastOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPastOrders();
  }

  Future<void> _fetchPastOrders() async {
    try {
      // Assuming you have a 'past_orders' collection in Firestore
      QuerySnapshot snapshot = await _firestore.collection('past_orders').get();

      setState(() {
        pastOrders = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        _isLoading = false; // Data fetching is complete
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
        title: Text('Past Orders'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator while fetching data
          : pastOrders.isEmpty
              ? Center(child: Text('No past orders available')) // Show message if no orders found
              : ListView.builder(
                  padding: EdgeInsets.all(16.0),
                  itemCount: pastOrders.length,
                  itemBuilder: (context, index) {
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
                            ...pastOrders[index]['items'].map<Widget>((item) {
                              return Text('${item['name']} - ₹${item['price']}');
                            }).toList(),
                            SizedBox(height: 4),
                            Text('Total: ₹${pastOrders[index]['totalPrice']}'),
                            Text('Order Date: ${pastOrders[index]['orderDate'].toDate().toString()}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
