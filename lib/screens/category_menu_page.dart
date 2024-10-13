import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/menu_item_card.dart';
import 'cart_page.dart';

class CategoryMenuPage extends StatefulWidget {
  final String category;
  final String user_email;

  CategoryMenuPage({required this.category, required this.user_email});

  @override
  _CategoryMenuPageState createState() => _CategoryMenuPageState(email: user_email);
}

class _CategoryMenuPageState extends State<CategoryMenuPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String email;

  _CategoryMenuPageState({required this.email});
  List<Map<String, dynamic>> menuItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
  }

  Future<void> _fetchMenuItems() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(widget.category) // Fetch items from the specific category collection
          .get();

      setState(() {
        menuItems = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        _isLoading = false; // Data fetching is complete
      });
    } catch (e) {
      print('Error fetching menu items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${capitalize(widget.category)} Menu'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage(email: email)),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator while fetching data
          : menuItems.isEmpty
              ? Center(child: Text('No items available')) // Show message if no items found
              : ListView.builder(
                  padding: EdgeInsets.all(16.0),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    return MenuItemCard(item: menuItems[index]);
                  },
                ),
    );
  }

  String capitalize(String input) {
    if (input.isEmpty) {
      return input;
    }
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }
}
