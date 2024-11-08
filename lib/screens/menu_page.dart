import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/theme_model.dart';
import './User_Profile/profile_screen.dart';
import 'Admin/manage_admins.dart';
import 'Counter_Manager/orders.dart';
import 'User_Profile/track_orders.dart';
import 'cart_page.dart';
import 'category_menu_page.dart';
import '../widgets/custom_search_bar.dart';
import '../utils/category_utils.dart';

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
      if (widget.email == "master.admin@somaiya.edu")
        ManageStaffPage(),
      if (widget.role == "customer")
        TrackOrdersPage(email: widget.email),
      UserProfilePage(
        fullName: widget.fullName,
        email: widget.email,
        isInside: widget.isInside,
        locationAbleToTrack: widget.locationAbleToTrack,
        user_role: widget.role,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<ThemeModel>(
      builder: (context, themeModel, child) {
        return Scaffold(
          body: _pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: l10n.menuTitle,
              ),
              if (widget.email == "master.admin@somaiya.edu")
                BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings),
                  label: l10n.staffLabel,
                ),
              if (widget.role == "customer")
                BottomNavigationBarItem(
                  icon: Icon(Icons.fastfood),
                  label: l10n.trackOrdersLabel,
                ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: l10n.profileTitle,
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).primaryColor,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
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
  List<Map<String, String>> filteredCategories = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        filteredCategories = _getCategories();
      });
    });
  }

  List<Map<String, String>> _getCategories() {
    final l10n = AppLocalizations.of(context)!;
    return [
      {
        'title': l10n.dosaCategory,
        'image': 'assets/images/dosa.jpg',
        'description': l10n.dosaDescription,
        'collection': 'dosa'
      },
      {
        'title': l10n.chatCategory,
        'image': 'assets/images/chat.jpeg',
        'description': l10n.chatDescription,
        'collection': 'chat'
      },
      {
        'title': l10n.snacksCategory,
        'image': 'assets/images/snacks.png',
        'description': l10n.snacksDescription,
        'collection': 'snacks'
      },
      {
        'title': l10n.frankyCategory,
        'image': 'assets/images/franky.jpeg.png',
        'description': l10n.frankyDescription,
        'collection': 'franky'
      },
      {
        'title': l10n.hotItemsCategory,
        'image': 'assets/images/chai.jpeg',
        'description': l10n.hotItemsDescription,
        'collection': 'hot_Items'
      },
      {
        'title': l10n.sandwichesCategory,
        'image': 'assets/images/sandwhich.jpeg',
        'description': l10n.sandwichesDescription,
        'collection': 'sandwiches'
      },
    ];
  }

  void _filterCategories(String query) {
    final categories = _getCategories();
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.red,
            iconTheme: IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                l10n.somatoMenu,
                style: TextStyle(color: Colors.white),
              ),
            ),
            actions: [
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
                hintText: l10n.searchHint,
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
                  final category = filteredCategories[index];
                  
                  return GestureDetector(
                    onTap: () {
                      // Use the collection name for Firebase operations
                      String collectionName = category['collection'] ?? 'unknown';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryMenuPage(
                            category: collectionName, // Pass the Firebase collection name
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
                                category['image']!,
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
                                  category['title']!,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  category['description']!,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}