import 'package:flutter/material.dart';


class FoodOrdersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Orders'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Text('Your Orders'), // Display user's food orders here
      ),
    );
  }
}
