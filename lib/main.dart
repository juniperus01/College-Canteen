import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/cart_model.dart';
import 'models/theme_model.dart';
import 'screens/User_Authentication/login_page.dart';
import 'package:firebase_core/firebase_core.dart';  // Firebase import
import 'firebase_options.dart';  // Generated file with Firebase options
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import Google Maps Flutter package
import 'dart:math'; // For mathematical calculations
import 'package:geolocator/geolocator.dart'; // Geolocator for cross-platform geolocation

void main() async {
  // Ensure that plugin services are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with default options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the app with providers for state management
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

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GeofenceManager geofenceManager = GeofenceManager();
  bool isInsideGeofence = false; // Store the isInside value
  bool locationAbleToTrack = false; // Track if location was able to be fetched

  @override
  void initState() {
    super.initState();
    // Call getCurrentLocation to retrieve user's location on app startup
    geofenceManager.getCurrentLocation((isInside, isLocationAbleToTrack) {
      setState(() {
        isInsideGeofence = isInside; // Update the value of isInside
        locationAbleToTrack = isLocationAbleToTrack; // Update location tracking status
      });
    });
  }

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
          home: LoginPage(
            isInside: isInsideGeofence,
            locationAbleToTrack: locationAbleToTrack, // Pass location tracking status
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
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      callback(false, false); // Pass false for both if location services are disabled
      return;
    }

    // Request location permissions if not granted
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permission denied.");
        callback(false, false); // Pass false for both if permission is denied
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permissions are permanently denied.");
      callback(false, false); // Pass false for both if permission is denied forever
      return;
    }

    try {
      // Get the current location of the user
      Position position = await Geolocator.getCurrentPosition();
      userLocation = LatLng(position.latitude, position.longitude);
      print("Current Location: ${userLocation!.latitude}, ${userLocation!.longitude}");

      // Check if user is inside the geofence and call the callback
      bool isInside = _isInsideGeofence(userLocation!);
      print("Is inside geofence: $isInside"); // Debug print
      callback(isInside, true); // Pass isInside and true for location tracking
      _notifyUser(isInside);
    } catch (error) {
      print("Error getting location: $error");
      callback(false, false); // Pass false for both on error
    }
  }

  bool _isInsideGeofence(LatLng location) {
    const LatLng societyCoords = LatLng(19.006657, 73.015872);
    const LatLng somaiyaCoords = LatLng(19.0728, 72.8999);

    const LatLng geofenceCenter = societyCoords;
    const double radius = 80000000000; // Geofence radius in meters (reduced from the huge value)

    // Calculate the distance from the geofence center to the user's location
    double distance = _haversineDistance(
      geofenceCenter.latitude,
      geofenceCenter.longitude,
      location.latitude,
      location.longitude,
    );

    return distance <= radius;
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000; // Radius of the Earth in meters
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in meters
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
