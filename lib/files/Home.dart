import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  final UserCredential userCredential;

  HomePage({required this.userCredential});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Marker> _driverMarkers = [];
  GoogleMapController? _mapController;
  String username = '';

  @override
  void initState() {
    super.initState();
    _startFetchingDriverLocations();
  }

  void _startFetchingDriverLocations() {
    Timer.periodic(Duration(seconds: 3), (timer) {
      _fetchDriverLocations();
    });
  }

  Future<void> _fetchDriverLocations() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('DriverLocations').get();

      List<Marker> markers = [];

      snapshot.docs.forEach((doc) async {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          GeoPoint? location = data['location'] as GeoPoint?;
          String busNumber = data['busno'];
          if (location != null) {
            LatLng latLng = LatLng(location.latitude, location.longitude);

            Marker marker = Marker(
              markerId: MarkerId(doc.id),
              position: latLng,
              icon: await BitmapDescriptor.fromAssetImage(
                ImageConfiguration(devicePixelRatio: 1.0),
                'images/111.png',
              ),
              infoWindow: InfoWindow(title: "Bus $busNumber"),
            );

            markers.add(marker);
          }
        }
      });

      setState(() {
        _driverMarkers = markers;
      });
    } catch (e) {
      print('Error fetching driver locations: $e');
    }
  }

  /*void sendPickupRequest(String busDriverId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final studentId = user.email;
        final studentLocation = await getCurrentLocation();

        // Send pick-up request to the bus driver
        await FirebaseFirestore.instance
            .collection('PickupRequests')
            .doc(busDriverId)
            .set({
          'studentmail': studentId,
          'location': GeoPoint(studentLocation.latitude, studentLocation.longitude),
        });

        print('Pick-up request sent to bus driver.');
      }
    } catch (e) {
      print('Error sending pick-up request: $e');
    }
  }


  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied, we cannot request permissions.');
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );

    return position; // Return the position object
  }*/

  void _centerMapToBuses() {
    if (_driverMarkers.isNotEmpty && _mapController != null) {
      LatLngBounds bounds = LatLngBounds(
        southwest: _driverMarkers[0].position,
        northeast: _driverMarkers[_driverMarkers.length - 1].position,
      );
      _mapController!
          .animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayName = widget.userCredential.user?.displayName ?? "Unknown";
    return Scaffold(
      appBar: AppBar(
        title: Text('Bus Tracking - $displayName'),
        backgroundColor: Colors.black87,
      ),
      body: GoogleMap(
        initialCameraPosition:
            CameraPosition(target: LatLng(23.8041, 90.4152), zoom: 14),
        markers: Set<Marker>.of(_driverMarkers),
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _centerMapToBuses,
        child: Icon(Icons.location_searching),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }
}
