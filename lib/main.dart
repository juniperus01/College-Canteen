import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'models/cart_model.dart';
import 'models/theme_model.dart';
import 'models/language_model.dart';
import 'l10n/l10n.dart';
import 'screens/User_Authentication/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartModel()),
        ChangeNotifierProvider(create: (context) => ThemeModel()),
        ChangeNotifierProvider(create: (context) => LanguageModel()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GeofenceManager geofenceManager = GeofenceManager();
  bool isInsideGeofence = false;
  bool locationAbleToTrack = false;

  @override
  void initState() {
    super.initState();
    geofenceManager.getCurrentLocation((isInside, isLocationAbleToTrack) {
      setState(() {
        isInsideGeofence = isInside;
        locationAbleToTrack = isLocationAbleToTrack;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeModel, LanguageModel>(
      builder: (context, themeModel, languageModel, child) {
        return MaterialApp(
          title: 'Somato',
          locale: languageModel.locale,
          supportedLocales: L10n.all,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
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
          home: LoginPage(
            isInside: isInsideGeofence,
            locationAbleToTrack: locationAbleToTrack,
          ),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class GeofenceManager {
  LatLng? userLocation;

  void getCurrentLocation(Function(bool, bool) callback) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      callback(false, false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permission denied.");
        callback(false, false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permissions are permanently denied.");
      callback(false, false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      userLocation = LatLng(position.latitude, position.longitude);
      print("Current Location: ${userLocation!.latitude}, ${userLocation!.longitude}");

      bool isInside = _isInsideGeofence(userLocation!);
      print("Is inside geofence: $isInside");
      callback(isInside, true);
      _notifyUser(isInside);
    } catch (error) {
      print("Error getting location: $error");
      callback(false, false);
    }
  }

  bool _isInsideGeofence(LatLng location) {
    const LatLng geofenceCenter = LatLng(19.006657, 73.015872);
    const double radius = 80000000000;

    double distance = _haversineDistance(
      geofenceCenter.latitude,
      geofenceCenter.longitude,
      location.latitude,
      location.longitude,
    );

    return distance <= radius;
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  void _notifyUser(bool isInside) {
    if (isInside) {
      print('You are inside the geofenced area!');
    } else {
      print('You are outside the geofenced area!');
    }
  }
}
