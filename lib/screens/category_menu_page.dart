import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/custom_search_bar.dart';
import 'cart_page.dart';

class CategoryMenuPage extends StatefulWidget {
  final String category;
  final String user_email;
  final String user_role;

  CategoryMenuPage({required this.category, required this.user_email, required this.user_role});

  @override
  _CategoryMenuPageState createState() => _CategoryMenuPageState(email: user_email, role: user_role);
}

class _CategoryMenuPageState extends State<CategoryMenuPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String email, role;
  _CategoryMenuPageState({required this.email, required this.role});

  List<Map<String, dynamic>> menuItems = [];
  List<Map<String, dynamic>> filteredMenuItems = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
  }

  Future<void> _fetchMenuItems() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(widget.category).get();
      setState(() {
        // Map the Firestore documents into the menuItems list, including document ID
        menuItems = snapshot.docs.map((doc) {
          // Add the document ID to the item data
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;  // Set the document ID as 'id'
          return data;
        }).toList();

        filteredMenuItems = menuItems;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching menu items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterMenuItems(String query) {
    setState(() {
      filteredMenuItems = menuItems
          .where((item) =>
              item['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
              item['description'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red, // Set background to red
        title: Text(
          '${capitalize(widget.category)} Menu',
          style: TextStyle(color: Colors.white), // Set text to white
        ),
        iconTheme: IconThemeData(color: Colors.white), // Set icon color to white
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
      body: Column(
        children: [
          // Display search bar only for customers
          if (role == 'customer')
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomSearchBar(
                controller: _searchController,
                onChanged: _filterMenuItems,
                hintText: 'Search in ${capitalize(widget.category)}...',
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredMenuItems.isEmpty
                    ? Center(child: Text('No items available'))
                    : ListView.builder(
                        padding: EdgeInsets.all(16.0),
                        itemCount: filteredMenuItems.length,
                        itemBuilder: (context, index) {
                          return MenuItemCard(
                            category: widget.category,
                            item: filteredMenuItems[index],
                            isAdmin: role == 'admin', // Pass user role to the MenuItemCard
                          );
                        },
                      ),
          ),
        ],
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
