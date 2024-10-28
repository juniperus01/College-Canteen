import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:somato/screens/Counter_Manager/orders.dart';

import '../models/theme_model.dart';
import './User_Profile/profile_screen.dart';
import 'Counter_Manager/orders.dart'; // Import your OrdersOnAdminPage
import 'cart_page.dart';
import 'category_menu_page.dart';
import '../widgets/custom_search_bar.dart';

class MenuPage extends StatefulWidget {
  final String fullName;
  final String email;
  final String role;
  final bool isInside;
  final bool locationAbleToTrack;

  MenuPage({
    required this.fullName,
    required this.email,
    required this.role,
    required this.isInside,
    required this.locationAbleToTrack,
  });

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      MenuPageContent(
        user_email: widget.email,
        user_role: widget.role,
        isInside: widget.isInside,
        locationAbleToTrack: widget.locationAbleToTrack,
      ),
      widget.role == 'admin'
          ? ManageOrdersPage() // Show OrdersOnAdminPage for admin
          : UserProfilePage(
              fullName: widget.fullName,
              email: widget.email,
              isInside: widget.isInside,
              locationAbleToTrack: widget.locationAbleToTrack,
            ),
      CartPage(email: widget.email),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModel>(
      builder: (context, themeModel, child) {
        return Scaffold(
          body: _pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(widget.role == 'admin' ? Icons.list : Icons.person),
                label: widget.role == 'admin' ? 'Orders' : 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).primaryColor,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
                if (index == 1 && widget.role == 'admin') {
                  _pages[1] = ManageOrdersPage(); // Load OrdersOnAdminPage for admin
                } else if (index == 1) {
                  _pages[1] = UserProfilePage(
                    fullName: widget.fullName,
                    email: widget.email,
                    isInside: widget.isInside,
                    locationAbleToTrack: widget.locationAbleToTrack,
                  );
                }
              });
            },
          ),
        );
      },
    );
  }
}

class MenuPageContent extends StatefulWidget {
  final String user_email;
  final String user_role;
  final bool isInside;
  final bool locationAbleToTrack;

  MenuPageContent({
    required this.user_email,
    required this.user_role,
    required this.isInside,
    required this.locationAbleToTrack,
  });

  @override
  _MenuPageContentState createState() => _MenuPageContentState();
}

class _MenuPageContentState extends State<MenuPageContent> {
  // Map to link collection names to menu titles
  final Map<String, String> categoryTitles = {
    'dosa': 'Dosa',
    'chat': 'Chat',
    'snacks': 'Snacks',
    'franky': 'Franky',
    'hot_Items': 'Hot Items',
    'sandwiches': 'Sandwiches',
  };

  final List<Map<String, String>> categories = [
    {'title': 'dosa', 'image': 'assets/images/dosa.jpg', 'description': 'Crispy South Indian crepes'},
    {'title': 'chat', 'image': 'assets/images/chat.jpeg', 'description': 'Savory street food snacks'},
    {'title': 'snacks', 'image': 'assets/images/snacks.png', 'description': 'Quick bites and appetizers'},
    {'title': 'franky', 'image': 'assets/images/franky.jpeg.png', 'description': 'Indian-style wraps'},
    {'title': 'hot_Items', 'image': 'assets/images/chai.jpeg', 'description': 'Tea and Coffee'},
    {'title': 'sandwiches', 'image': 'assets/images/sandwhich.jpeg', 'description': 'Sandwiches'},
  ];

  List<Map<String, String>> filteredCategories = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredCategories = categories;
  }

  void _filterCategories(String query) {
    setState(() {
      filteredCategories = categories
          .where((category) =>
              category['title']!.toLowerCase().contains(query.toLowerCase()) ||
              category['description']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.red, // Set the background color for SliverAppBar
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Somato Menu',
                style: TextStyle(color: Colors.white),
              ),
            ),
            actions: [
              // Show cart icon only if the user role is not Admin
              if (widget.user_role != 'admin')
                IconButton(
                  icon: Icon(Icons.shopping_cart, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CartPage(email: widget.user_email)),
                    );
                  },
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomSearchBar(
                controller: _searchController,
                onChanged: _filterCategories,
                hintText: 'Search categories...',
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryMenuPage(
                            category: filteredCategories[index]['title']!,
                            user_email: widget.user_email,
                            user_role: widget.user_role,
                            isInside: widget.isInside,
                            locationAbleToTrack: widget.locationAbleToTrack,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                              child: Image.asset(
                                filteredCategories[index]['image']!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  capitalize(filteredCategories[index]['title']!),
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  filteredCategories[index]['description']!,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: filteredCategories.length,
              ),
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
