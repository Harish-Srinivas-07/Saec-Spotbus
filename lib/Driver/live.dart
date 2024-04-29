import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wakelock/wakelock.dart';
import 'package:background_location/background_location.dart';
import 'package:audiofileplayer/audiofileplayer.dart';
import 'package:shared_preferences/shared_preferences.dart';



void main() {
  runApp(const MaterialApp(
    home: Live(updateValue: false),
  ));
}

class Live extends StatefulWidget {
  final bool updateValue;
  const Live({Key? key, required this.updateValue}) : super(key: key);

  @override
  State<Live> createState() => _LiveState();
}


class _LiveState extends State<Live> {
  String authh = "";
  late Timer timer;
  late Position? currentPosition;
  late GoogleMapController mapController;
  late Marker currentLocationMarker;

  bool sharingLocation = false;
  bool mapLoaded = false;
  bool audioPlayed = false;
  String? rnoname;
  String? ct = '';
  String? selectedVehicle = '';
  String? selectedRoute = '';
  bool update = false;

  @override
  void initState() {
    super.initState();
    BackgroundLocation.startLocationService();

    // Initialize currentPosition and set mapLoaded to true
    // Release the screen wake lock
    Wakelock.enable();
    _determinePosition().then((position) {
      if (position != null) {
        setState(() {
          currentPosition = position;
          mapLoaded = true;
          currentLocationMarker = Marker(
            markerId: const MarkerId('currentLocation'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: 'Bus Location'),
          );
        });
      }
    });
    updateLocation(); // update at initially
    BackgroundLocation.setAndroidNotification(
      title: 'Sharing Bus location',
      message: 'Your bus location is sharing with our students ...',
      icon: '@mipmap/ic_launcher',
    );
    // Start the timer to check if the location sharing button is clicked
    startLocationSharingTimer();
    _loadSelectedValues();
  }

  @override
  void dispose() {
    // Dispose the timer when the widget is disposed
    if (timer.isActive) {
      timer.cancel();
    }
    timer.cancel();
    // Release the screen wake lock
    Wakelock.disable();
    BackgroundLocation.stopLocationService();
    super.dispose();
  }

  Future<void> _loadSelectedValues() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        selectedRoute = prefs.getString('selectedRoute') ?? null;
        selectedVehicle = prefs.getString('selectedVehicle') ?? null;
        ct = prefs.getString('ct') ?? null;
        update = prefs.getBool('update') ?? false;
      });
      print('$update from live');

    } catch (e) {
      print('Error loading selected values: $e');
    }
  }

  // Start timer to check if location sharing button is clicked
  void startLocationSharingTimer() {
    timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!sharingLocation && !audioPlayed) {
        // If sharingLocation is false and audio is not played, play the audio
        Audio.load('assets/audio/alert.mp3')..play()..dispose();
        audioPlayed = true;
      }
    });
  }

  // Stop the timer when the location sharing button is clicked
  void stopLocationSharingTimer() {
    if (timer.isActive) {
      timer.cancel();
    };
    timer.cancel();
  }

  // Restarts the timer when the location sharing button is clicked
  void restartLocationSharingTimer() {
    if (!timer.isActive) {
      startLocationSharingTimer();
      audioPlayed = false; // Reset audioPlayed to false when the button is clicked
    }
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isDenied) {
    }
  }

  Future<Position?> _determinePosition() async {
    try {
      // Check if location services are enabled
      if (!(await Geolocator.isLocationServiceEnabled())) {
        // Location services are disabled, prompt user to enable them
        bool serviceEnabled = await Geolocator.openLocationSettings();
        if (!serviceEnabled) {
          // User didn't enable location services, return null
          return null;
        }
      }

      // Check if location permissions are granted
      var status = await Permission.location.status;
      if (status.isDenied) {
        // Location permissions are denied, request them
        await requestLocationPermission();
      }

      // Get the current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    } catch (e) {
      print("Error determining position: $e");
      return null;
    }
  }


  void toggleSharingLocation() {
    // Check if selectedRoute, selectedVehicle, and ct are not null
    print('the value $ct$selectedRoute$selectedVehicle$update');
    if (selectedRoute != '' && selectedVehicle != '' && ct != '' && widget.updateValue) {
      if (!sharingLocation) {
        // Start sharing location
        _startSharingLocation();
        BackgroundLocation.startLocationService(distanceFilter: 20);
        restartLocationSharingTimer(); // Restart the timer when sharing location is started
      } else {
        // Show confirmation dialog when stopping sharing location
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Stop Sharing Confirmation', style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text('Are you sure you want to stop sharing your location?'),
              actions: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[500],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                   // Close the dialog
                  },
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[500],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () { // Close the dialog
                    _stopSharingLocation();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();// Stop sharing location if confirmed
                  },
                  child: const Text('Stop Sharing', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            );
          },
        );
      }
    } else {
      // Display alert box if any of the values are null
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Alert', style: TextStyle(fontWeight: FontWeight.bold,color: Colors.red)),
            content: Text(
              'Please select a route in home page',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[500],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
  }


  void _startSharingLocation() {
    setState(() {
      sharingLocation = true;
      mapLoaded = true;
      // Set Android notification before starting location service
      BackgroundLocation.setAndroidNotification(
        title: 'Sharing Bus location',
        message: 'Your bus location is sharing with our students ...',
        icon: '@mipmap/ic_launcher',
      );
      BackgroundLocation.startLocationService();
      timer = Timer.periodic(const Duration(seconds: 10), (Timer t) => updateLocation());
    });
  }


  void _stopSharingLocation() {
    setState(() {
      sharingLocation = false;
      timer.cancel();
      BackgroundLocation.stopLocationService();
      stopLocationSharingTimer(); // Stop the timer when sharing location is stopped
    });

    // Remove the "Tracking" and "locations" nodes from the database
    DatabaseReference _database = FirebaseDatabase.instance.ref();
    FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser;
    String? userId = user?.uid;
    if (userId != null) {
      _database.child('Tracking').child(userId).remove();
      _database.child('locations').child(userId).remove();
    }
  }



  Future<void> updateLocation() async {
    try {
      if (!sharingLocation) {
        return; // Don't update location if sharingLocation is false
      }

      FirebaseAuth _auth = FirebaseAuth.instance;
      User? user = _auth.currentUser;
      String? userId = user?.uid;
      userId ??= "";

      // Fetch the 'rno' from the database
      DatabaseReference _database = FirebaseDatabase.instance.ref();
      DatabaseEvent? event = await _database.child('Tracking').child(userId).once();

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          String? rno = data['rno'] as String?;
          String? route = data['rna'] as String?;
          rnoname = route;

          // Get the current position
          final position = await _determinePosition();
          if (position == null) {
            return;
          }

          // Update the database with the new location data under the "locations" node with the user ID
          await FirebaseDatabase.instance
              .ref()
              .child('locations')
              .child(userId)
              .set({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': ServerValue.timestamp,
            'rno': rno, // Add 'rno' to the location data
            'route': route,
          });

          // Update marker position
          setState(() {
            currentPosition = position;
            currentLocationMarker = Marker(
              markerId: const MarkerId('currentLocation'),
              position: LatLng(position.latitude, position.longitude),
              infoWindow: const InfoWindow(title: 'Bus Location'),
            );
          });

          // Move camera to updated position
          mapController.animateCamera(
            CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
          );
        }
      }
    } catch (e) {
      print("Error updating location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: mapLoaded ? Colors.white : const Color(0xFFD7F7DE),
        child: Stack(
          children: [
            if (mapLoaded)
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(currentPosition?.latitude ?? 0, currentPosition?.longitude ?? 0),
                  zoom: 14.0,
                ),
                markers: sharingLocation ? {currentLocationMarker} : {},
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                },
                trafficEnabled: true,
              )
            else
              const Center(
                child: CircularProgressIndicator(),
              ),
            if (mapLoaded==true && currentPosition != null)
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.green,
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Distance from College : ${_calculateDistance(currentPosition!.latitude, currentPosition!.longitude, 13.065995353264174, 80.11124646902768).toStringAsFixed(2)} km",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,

                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: !mapLoaded ? null : FloatingActionButton.extended(
        onPressed: () {
          toggleSharingLocation();
          restartLocationSharingTimer(); // Restart the timer when the button is clicked
        },
        backgroundColor: sharingLocation ? Colors.red : Colors.green,
        icon: Icon(
          sharingLocation ? Icons.pause : Icons.play_arrow,
          color: Colors.white, // Set icon color to white
        ),
        label: Text(
          sharingLocation ? "Pause Sharing" : "Share Location",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  double _calculateDistance(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude) / 1000;
  }

}

