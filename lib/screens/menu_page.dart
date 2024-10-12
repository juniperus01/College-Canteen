import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/theme_model.dart';
import './User_Profile/profile_screen.dart';
import 'cart_page.dart';
import 'category_menu_page.dart';

class MenuPage extends StatefulWidget {
  final String fullName;
  final String email;

  MenuPage({required this.fullName, required this.email}); // Accept parameters

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.add(MenuPageContent());
    _pages.add(UserProfilePage(fullName: widget.fullName, email: widget.email)); // Pass user data to UserProfilePage
  }

  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModel>(
      builder: (context, themeModel, child) {
        return Scaffold(
          body: _pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).primaryColor,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
                // Update UserProfilePage with the user data when switching tabs
                if (index == 1) {
                  _pages[1] = UserProfilePage(fullName: widget.fullName, email: widget.email);
                }
              });
            },
          ),
        );
      },
    );
  }
}

class MenuPageContent extends StatelessWidget {
  final List<Map<String, String>> categories = [
    {'title': 'dosa', 'image': 'assets/images/dosa.webp', 'description': 'Crispy South Indian crepes'},
    {'title': 'chat', 'image': 'assets/images/chaats.webp', 'description': 'Savory street food snacks'},
    {'title': 'snacks', 'image': 'assets/images/snacks.webp', 'description': 'Quick bites and appetizers'},
    // {'title': 'Beverages', 'image': 'assets/images/beverages.webp', 'description': 'Refreshing drinks'},
    // {'title': 'Frankies', 'image': 'assets/images/franky.webp', 'description': 'Indian-style wraps'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.red,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Somato Menu',
                style: TextStyle(color: Colors.white),
              ),
              background: Image.asset(
                'assets/images/food_background.webp',
                fit: BoxFit.cover,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartPage()),
                  );
                },
              ),
            ],
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
                            category: categories[index]['title']!,
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
                                categories[index]['image']!,
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
                                  capitalize(categories[index]['title']!),
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  categories[index]['description']!,
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
                childCount: categories.length,
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
