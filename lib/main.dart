import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/cart_model.dart';
import 'models/theme_model.dart';
import 'screens/login_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartModel()),
        ChangeNotifierProvider(create: (context) => ThemeModel()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModel>(
      builder: (context, themeModel, child) {
        return MaterialApp(
          title: 'Somato',
          theme: themeModel.isDark
              ? ThemeData.dark().copyWith(
                  primaryColor: Colors.red,
                  colorScheme: ColorScheme.dark().copyWith(
                    primary: Colors.red,
                    secondary: Colors.redAccent,
                  ),
                )
              : ThemeData.light().copyWith(
                  primaryColor: Colors.red,
                  colorScheme: ColorScheme.light().copyWith(
                    primary: Colors.red,
                    secondary: Colors.redAccent,
                  ),
                ),
          home: LoginPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
