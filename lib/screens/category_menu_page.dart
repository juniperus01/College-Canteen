import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // Import Timer package
import '../widgets/menu_item_card.dart';
import '../widgets/custom_search_bar.dart';
import 'cart_page.dart';

class CategoryMenuPage extends StatefulWidget {
  final String category;
  final String user_email;
  final String user_role;
  final bool isInside, locationAbleToTrack;

  CategoryMenuPage({
    required this.category,
    required this.user_email,
    required this.user_role,
    required this.isInside,
    required this.locationAbleToTrack,
  });

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
  Timer? _timer; // Declare Timer

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
    _startTimer(); // Start the timer to refresh data
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchMenuItems(); // Fetch data every 10 seconds
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> _fetchMenuItems() async {
  try {
    QuerySnapshot snapshot = await _firestore.collection(widget.category).get();
    setState(() {
      menuItems = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Set the document ID as 'id'
        return data;
      }).toList();

      // Sort the menuItems by price in increasing order
      menuItems.sort((a, b) => a['name'].compareTo(b['name']));

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
      filteredMenuItems = menuItems.where((item) =>
          item['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
          item['description'].toString().toLowerCase().contains(query.toLowerCase())).toList();
    });
  }
  
  Future<void> _refreshOrders(BuildContext context) async {
    await Future.delayed(Duration(seconds: 1)); // Simulate a delay for loading
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  backgroundColor: Colors.red,
  title: Text(
    '${capitalize(widget.category)} Menu',
    style: TextStyle(color: Colors.white),
  ),
  iconTheme: IconThemeData(
    color: Colors.white, // Sets back arrow icon color to white
  ),
  actions: [
    // Refresh button
    IconButton(
      icon: Icon(Icons.refresh, color: Colors.white), // Refresh icon color set to white
      onPressed: () => _refreshOrders(context),
    ),
    
    if (role == 'customer') // Show cart icon for customer only
      IconButton(
        icon: Icon(Icons.shopping_cart, color: Colors.white), // Cart icon color set to white
        onPressed: () {
          // Navigate to the CartPage
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
          // Show warning message if the user is outside the campus
          if (widget.locationAbleToTrack && !widget.isInside)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                color: Colors.amberAccent, // Warning background color
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 30), // Warning icon
                    SizedBox(width: 10), // Space between icon and text
                    Expanded(
                      child: Text(
                        "Oops! Please ensure you're inside the campus to place an order.",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!widget.locationAbleToTrack)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                color: Colors.amberAccent, // Warning background color
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 30), // Warning icon
                    SizedBox(width: 10), // Space between icon and text
                    Expanded(
                      child: Text(
                        "Oops! Please ensure you've enabled your location services.",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Search bar and 'Add Item' button for both customer and admin
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search bar with flexible width
                Expanded(
                  child: CustomSearchBar(
                    controller: _searchController,
                    onChanged: _filterMenuItems,
                    hintText: 'Search in ${capitalize(widget.category)}...',
                  ),
                ),
                SizedBox(width: 10),
                // 'Add Item' button visible for admin
                if (role == 'admin')
                  ElevatedButton(
                    onPressed: () {
                      // Show the 'Add New Item' dialog
                      _showAddItemDialog(context, widget.category);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Red background
                      foregroundColor: Colors.white, // White text
                    ),
                    child: Text('Add New Item'),
                  ),
              ],
            ),
          ),
          // Menu items
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
                            isAdmin: role == 'admin',
                            isInside: widget.isInside,
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

  void _showAddItemDialog(BuildContext context, String category) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Item'),
          content: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Add the item to Firestore
                await _addItemToFirestore(context, category, {
                  'name': nameController.text,
                  'price': double.tryParse(priceController.text) ?? 0.0,
                });
                Navigator.of(context).pop(); // Close the dialog
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red, // Red background for the 'Add' button
                foregroundColor: Colors.white, // White text
              ),
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addItemToFirestore(BuildContext context, String category, Map<String, dynamic> newItemData) async {
    try {
      CollectionReference collectionRef = FirebaseFirestore.instance.collection(category);
      await collectionRef.add(newItemData);
      _showSnackBar(context, 'Item added successfully!');

      // Fetch the updated menu items list
      _fetchMenuItems();
    } catch (e) {
      print('Error adding item: $e');
      _showSnackBar(context, 'Error adding item: $e');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red, // Red background
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}