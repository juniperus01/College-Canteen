import 'package:flutter/material.dart';
import '../widgets/menu_item_card.dart';
import 'cart_page.dart';

class CategoryMenuPage extends StatelessWidget {
  final String category;

  CategoryMenuPage({required this.category});

  // Dummy data for menu items
  final List<Map<String, dynamic>> menuItems = [
    {'name': 'Item 1', 'price': 50.0, 'time': '10 min', 'image': 'assets/images/dosa.webp'},
    {'name': 'Item 2', 'price': 60.0, 'time': '15 min', 'image': 'assets/images/beverages.webp'},
    {'name': 'Item 3', 'price': 70.0, 'time': '12 min', 'image': 'assets/images/chaats.webp'},
    {'name': 'Item 4', 'price': 80.0, 'time': '18 min', 'image': 'assets/images/franky.webp'},
    {'name': 'Item 5', 'price': 90.0, 'time': '20 min', 'image': 'assets/images/snacks.webp'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$category Menu'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          return MenuItemCard(item: menuItems[index]);
        },
      ),
    );
  }
}