import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BusTrackingScreen(),
    );
  }
}

Future<Marker> createDriverMarker(LatLng driverLocation) async {
  final BitmapDescriptor icon = await BitmapDescriptor.fromAssetImage(
    const ImageConfiguration(devicePixelRatio: 1.0),
    'images/party-bus.png',
  );

  Marker marker = Marker(
    markerId: const MarkerId('Bus'),
    position: driverLocation,
    icon: icon,
  );

  return marker;
}

class BusTrackingScreen extends StatefulWidget {
  @override
  _BusTrackingScreenState createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late GoogleMapController _mapController; // Define the map controller
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  LatLng driverLocation =
      LatLng(23.8041, 90.4152); // Initialize with a default value

  late Timer _locationTimer;
  final Duration _locationUpdateInterval =
      const Duration(seconds: 3); // Update interval

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(_locationUpdateInterval, (timer) {
      _sendDriverLocationToDatabase();
    });
  }

  late double latitude = 23.8041; // Default value
  late double longitude = 90.4152; // Default value

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    latitude = position.latitude;
    longitude = position.longitude;
    setState(() {
      driverLocation = LatLng(latitude, longitude);
    });
  }

  Future<void> _sendDriverLocationToDatabase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        getCurrentLocation();

        DocumentReference locationRef =
            _firestore.collection('DriverLocations').doc(user.uid);

        DocumentSnapshot locationDoc = await locationRef.get();

        if (locationDoc.exists) {
          // Document exists, update its fields
          await locationRef.update({
            'location': GeoPoint(latitude, longitude),
            'email': user
                .email, // Assuming you have busno property in your user object
          });

          print("Collection found, updating data");
        } else {
          // Document doesn't exist, create it
          await locationRef.set({
            'location': GeoPoint(latitude, longitude),
            'email': user.email,
          });
          print("Collection not found, setting new collection");
        }

        print(
            'Driver location sent to Realtime Database: $latitude, $longitude');
      }
    } catch (e) {
      print('Error sending driver location: $e');
    }
  }

  Set<Marker> _markers = {};

  void _moveCameraToDriverLocation() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(driverLocation, 14.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    createDriverMarker(driverLocation).then((marker) {
      setState(() {
        _markers.add(marker);
      });
    });
    return Scaffold(
      appBar: AppBar(
        title: Text("Driver Home Page"),
        backgroundColor: Colors.black87,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: driverLocation,
          zoom: 14,
        ),
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _moveCameraToDriverLocation,
        child: Icon(Icons.location_searching),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }
}
