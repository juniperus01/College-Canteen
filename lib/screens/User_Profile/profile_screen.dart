import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:somato/screens/User_Profile/appearance.dart';
import 'package:somato/screens/User_Profile/edit_profile.dart';
import 'package:somato/screens/User_Profile/expense_tracker.dart';
import 'package:somato/screens/User_Profile/user_orders.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:somato/screens/User_Authentication/login_page.dart';
=======
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/theme_model.dart';
import '/models/language_model.dart';  // Use your existing LanguageModel
import 'appearance.dart';
import 'edit_profile.dart';
import 'expense_tracker.dart';
import 'user_orders.dart';
import '../User_Authentication/login_page.dart';
>>>>>>> 9f8a1ce (Update menu page with localization and category translations)

class UserProfilePage extends StatelessWidget {
  final String fullName;
  final String email;
<<<<<<< HEAD
  final String? imageUrl; // Nullable URL for the user's profile image
  final bool isInside, locationAbleToTrack;
  final String user_role;

  UserProfilePage({
=======
  final String? imageUrl;
  final bool isInside, locationAbleToTrack;
  final String user_role;

  const UserProfilePage({
    Key? key,
>>>>>>> 9f8a1ce (Update menu page with localization and category translations)
    required this.fullName,
    required this.email,
    required this.isInside,
    required this.locationAbleToTrack,
    required this.user_role,
<<<<<<< HEAD
    this.imageUrl, // Optional parameter
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.white), // Correctly placed within the Text widget
        ),
        backgroundColor: Colors.red,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                  ? NetworkImage(imageUrl!) // Load the user's profile image
                  : AssetImage('assets/images/default_user_icon.png') // Default user icon
                      as ImageProvider, // Cast to ImageProvider
            ),
            SizedBox(height: 20),
            Text(
              fullName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              email,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 30),
            ListTile(
              title: Text('Your Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfilePage(fullName: this.fullName, email: this.email)),
                );
              },
            ),
            ListTile(
              title: Text('Appearance'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AppearanceSettings()),
                );
              },
            ),
            // Conditionally render 'Your Orders' and 'Track Expenses'
            if (user_role == 'customer') ...[
              ListTile(
                title: Text('Your Orders'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PastOrdersPage(email: email)),
                  );
                },
              ),
              ListTile(
                title: Text('Track Expenses'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ExpenseTrackerPage(email: email)),
                  );
                },
              ),
            ],
            ListTile(
              title: Text('Log Out'),
              onTap: () async {
                await FirebaseAuth.instance.signOut(); // Log out from Firebase
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage(isInside: isInside, locationAbleToTrack: locationAbleToTrack)), // Navigate to Login Page
                );
              },
            ),
          ],
=======
    this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeModel = Provider.of<ThemeModel>(context);
    final languageModel = Provider.of<LanguageModel>(context);  // Use LanguageModel instead

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.profileTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              children: [
                // Profile Header
                CircleAvatar(
                  radius: 50,
                  backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                      ? NetworkImage(imageUrl!)
                      : const AssetImage('assets/images/default_user_icon.png') as ImageProvider,
                ),
                const SizedBox(height: 16),
                Text(
                  fullName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Settings Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      _buildListTile(
                        context,
                        title: l10n.yourProfile,
                        icon: Icons.person,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfilePage(
                              fullName: fullName,
                              email: email,
                            ),
                          ),
                        ),
                      ),
                      _buildDivider(),
                      _buildListTile(
                        context,
                        title: l10n.appearance,
                        icon: Icons.palette,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppearanceSettings(),
                          ),
                        ),
                      ),
                      _buildDivider(),
                      _buildListTile(
                        context,
                        title: l10n.language,
                        icon: Icons.language,
                        subtitle: languageModel.getCurrentLanguageName(),  // Use your language model's method
                        onTap: () => _showLanguageDialog(context, l10n, languageModel),
                      ),
                    ],
                  ),
                ),

                // Customer-specific Options
                if (user_role == 'customer') ...[
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          context,
                          title: l10n.orderHistory,
                          icon: Icons.receipt_long,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PastOrdersPage(email: email),
                            ),
                          ),
                        ),
                        _buildDivider(),
                        _buildListTile(
                          context,
                          title: l10n.trackExpenses,
                          icon: Icons.account_balance_wallet,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExpenseTrackerPage(email: email),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Logout Card
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: _buildListTile(
                    context,
                    title: l10n.logout,
                    icon: Icons.exit_to_app,
                    onTap: () => _showLogoutDialog(context, l10n),
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
>>>>>>> 9f8a1ce (Update menu page with localization and category translations)
        ),
      ),
    );
  }
<<<<<<< HEAD
}
=======

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? subtitle,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 16, endIndent: 16);
  }

  void _showLanguageDialog(BuildContext context, AppLocalizations l10n, LanguageModel languageModel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                onTap: () {
                  languageModel.setLocale(const Locale('en'));  // Use your language model's method
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('हिंदी'),
                onTap: () {
                  languageModel.setLocale(const Locale('hi'));  // Use your language model's method
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.confirmLogout),
          content: Text(l10n.logoutMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginPage(
                        isInside: isInside,
                        locationAbleToTrack: locationAbleToTrack,
                      ),
                    ),
                    (route) => false,
                  );
                }
              },
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );
  }
}
>>>>>>> 9f8a1ce (Update menu page with localization and category translations)
