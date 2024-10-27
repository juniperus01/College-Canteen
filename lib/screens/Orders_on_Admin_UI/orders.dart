import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';




class OrdersOnAdminPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orders'),
        backgroundColor: Colors.red, // Set your preferred color
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return Center(child: Text('No orders found.'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('Order ID: ${order['orderId']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer: ${order['customerName']}'),
                      Text('Items: ${order['items'].join(', ')}'),
                      Text('Status: ${order['status']}'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // _deleteOrder(order['orderId']);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
