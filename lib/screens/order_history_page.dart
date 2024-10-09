import 'package:flutter/material.dart';

class OrderHistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> orders = [
    {
      'id': '1',
      'date': '2024-03-15',
      'total': 25.99,
      'status': 'Delivered',
      'items': ['Dosa', 'Chaat', 'Lassi']
    },
    {
      'id': '2',
      'date': '2024-03-14',
      'total': 18.50,
      'status': 'Processing',
      'items': ['Biryani', 'Naan', 'Raita']
    },
    // Add more sample orders as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order History'),
      ),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text('Order #${order['id']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${order['date']}'),
                  Text('Total: \$${order['total']}'),
                  Text('Status: ${order['status']}'),
                  Text('Items: ${order['items'].join(', ')}'),
                ],
              ),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Implement order details page
              },
            ),
          );
        },
      ),
    );
  }
}