import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart' as launcher ;
import 'package:geolocator/geolocator.dart';

import 'dart:ui';
import 'package:audiofileplayer/audiofileplayer.dart';
import 'package:collegebustracking/utills/list.dart';

Timer? _timer;
bool isBellButtonClicked = false;

class trackl extends StatefulWidget {
  final String akey;

  trackl({
    required this.akey,
  });

  @override
  _FullListPageState createState() => _FullListPageState();
}

class _FullListPageState extends State<trackl> {

  String selectedRadio = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late GoogleMapController mapController;

  DatabaseReference reference = FirebaseDatabase.instance.ref();
  StreamController<Map<String, dynamic>> _locationStreamController = StreamController<Map<String, dynamic>>();
  Uint8List? compressedBytes; // Declare compressedBytes here
  Uint8List? userMarkerBytes; // Declare userMarkerBytes here


  final double destinationLatitude = 13.064811508580839;
  final double destinationLongitude = 80.1111505544997;
  late Position _currentPosition;

  double usertime =0;
  double clgtime =0;
  int gotime=0;
  int minutestime=0;
  int totallength=0;
  double? percentage = 0.0;

  bool _busHalted = false;
  String route = '';


  @override
  void initState() {
    super.initState();
    print('akey value: ${widget.akey}');

    _getCurrentLocation().then((_) {
      startLocationUpdates();
      loadCompressedBytes();
      loadUserMarkerBytes();
      if (widget.akey.isEmpty) {

        WidgetsBinding.instance!.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Alert'),
              content: Text('Please select a route.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        });
      }
    });
  }


  @override
  void dispose() {
    _locationStreamController.close();
    super.dispose();
  }



  Future<void> loadCompressedBytes() async {
    // Load the image byte data
    ByteData data = await rootBundle.load('assets/img/bus_stop_pointer.png');

    // Convert List<int> to Uint8List
    compressedBytes = Uint8List.fromList(data.buffer.asUint8List());
  }

  // Load user marker bytes from assets
  Future<void> loadUserMarkerBytes() async {
    ByteData data =
    await rootBundle.load('assets/img/man.png');
    userMarkerBytes = Uint8List.fromList(data.buffer.asUint8List());
  }


  bool busUpdatesReceived = false;

  void startLocationUpdates() {
    DatabaseReference reference = FirebaseDatabase.instance
        .ref()
        .child('locations')
        .child(widget.akey);

    reference.onValue.listen((event) {
      if (event.snapshot.value != null) {

        var userData = event.snapshot.value;
        if (userData is Map<Object?, Object?>) {

          Map<String, dynamic> userDataMap =
          userData.cast<String, dynamic>();

          // Check and extract rno value
          route = userDataMap.containsKey('rno') ? userDataMap['rno'] : '';
          // Calculate total length based on route value
          String? length = dist_list[route];
          if (length != null) {
            totallength = int.parse(length);
          } else {
            print("Length not found for route: $route");
          }


          busUpdatesReceived = true;
          setState(() {
            _busHalted = false;
          });

          _locationStreamController.add(userDataMap);

          showLocationOnMap(
              userDataMap['latitude'], userDataMap['longitude']);
        } else {
          print("Invalid data structure in the database");
        }
      } else {
        print("No location data found in the database");
        // Show an alert dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("No Location Data"),
              content: Text("Driver may not be sharing location."),
              actions: [
                TextButton(
                  onPressed: () {
                    // Navigate back to previous window
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      }
    }, onError: (Object error) {
      print("Error fetching location data: $error");
    });

    // Timer to check for updates every 10 seconds
    Timer.periodic(Duration(minutes: 1), (timer) {

      if (!busUpdatesReceived) {
        setState(() {
          _busHalted = true;
        });
      }
      if (busUpdatesReceived == true){
        setState(() {
          _busHalted = false;
        });
      }
      // Reset the flag for the next cycle
      busUpdatesReceived = false;
    });
  }



  void showLocationOnMap(double? latitude, double? longitude) {
    // Check if mapController is initialized
    if (mapController != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(latitude!, longitude!),
          14.0,
        ),
      );
    }
  }


  // Function to launch Google Maps navigation
  Future<void> launchGoogleMapsNavigation(double startLatitude,
      double startLongitude, double endLatitude, double endLongitude) async {
    String googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&origin=$startLatitude,$startLongitude&destination=$endLatitude,$endLongitude&travelmode=driving';
    if (await launcher.canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launcher.launchUrl(Uri.parse(googleMapsUrl));
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }

  // Function to fetch user's current location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, prompt the user to enable them
      serviceEnabled = await Geolocator.openLocationSettings();
      if (!serviceEnabled) {
        // User declined to enable location services, handle accordingly
        // You can show a dialog or a snackbar to inform the user
        print('Location services are disabled.');
        return;
      }
    }

    // Check location permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Location permissions are not granted, request permission from the user
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle accordingly
        // You can show a dialog explaining why the permission is necessary
        // and direct the user to the app settings to enable it manually
        print(
            'Location permissions are permanently denied, we cannot request permissions.');
        return;
      }

      if (permission == LocationPermission.denied) {
        // Permissions are denied, handle accordingly
        // You can show a dialog explaining why the permission is necessary
        // and direct the user to the app settings to enable it
        print('Location permissions are denied.');
        return;
      }
    }

    // Fetch current position if everything is fine
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
    });
  }

  // Function to calculate distance between two points
  double calculateDistance(
      double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(
        startLatitude, startLongitude, endLatitude, endLongitude);
  }
  // Function to calculate distance between college and bus location
  double calculateCollegeDistance(
      double busLatitude,
      double busLongitude,
      double collegeLatitude,
      double collegeLongitude,
      ) {
    return Geolocator.distanceBetween(
      busLatitude, busLongitude, collegeLatitude, collegeLongitude,
    );
  }

  String estimateTime(double distance) {
    // Assuming an average speed of 10 km/h for the bus
    double averageSpeedKmPerHour = 10000.0;
    double timeInHours = distance / averageSpeedKmPerHour;
    usertime = timeInHours;

    int hours = timeInHours.floor();
    int minutes = ((timeInHours - hours) * 60).round();
    int minutestime = ((timeInHours - hours) * 60).round();


    // Convert hours to minutes and add to total minutes
    minutestime += hours * 60;
    gotime = minutestime;

    if (hours > 0) {
      // If time exceeds one hour, format as "in 1 hr 5 min"
      return '$hours hr $minutes min';
    } else {
      // Otherwise, only show minutes
      return '$minutes min';
    }
  }


  String clgestimateTime(double clgdistance) {

    // Assuming an average speed of 10 km/h for the bus
    double averageSpeedKmPerHour = 10000.0;
    double timeInHours = clgdistance / averageSpeedKmPerHour;

    clgtime = timeInHours;

    // Subtract 5 minutes from the estimated arrival time
    double fiveMinutesInHours = 5 / 60;
    timeInHours -= fiveMinutesInHours;

    // Calculate arrival time based on current time
    DateTime currentTime = DateTime.now();
    int hours = currentTime.hour;
    int minutes = currentTime.minute+7;

    // Calculate arrival time
    int arrivalHours = hours + (timeInHours.floor());
    int arrivalMinutes = minutes + (((timeInHours - timeInHours.floor()) * 60).round());

    // Handle overflow
    if (arrivalMinutes >= 60) {
      arrivalHours += 1;
      arrivalMinutes -= 60;
    }

    // Format arrival time
    String amOrPm = arrivalHours >= 12 ? 'pm' : 'am';
    arrivalHours = arrivalHours % 12;
    if (arrivalHours == 0) {
      arrivalHours = 12;
    }
    String formattedArrivalTime = '$arrivalHours:${arrivalMinutes.toString().padLeft(2, '0')} $amOrPm';

    return formattedArrivalTime;
  }

  void startTimer(double distance) {
    // Ensure gotime is at least 5, as we are subtracting 5 minutes
    int minutes = gotime >= 5 ? gotime - 5 : 0;

    // Start the timer
    print('the time is : $minutes');
    _timer = Timer(Duration(minutes: minutes), () {

      showDialog(
        context: context,
        builder: (BuildContext context) {

          Audio.load('assets/audio/alert.mp3')..play()..dispose();
          isBellButtonClicked = false;
          return AlertDialog(
            title: const Text('Be ready ...',
              style: TextStyle(
              fontWeight: FontWeight.bold,
            ),),
            content: const Text('Your Bus Arriving within 5 min'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
      // Update the bell icon after the timer ends
      setState(() {
        isBellButtonClicked = false;
      });
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 60.0,
          title: const Text('Bus Live Tracking',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFE7F2FE)),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _locationStreamController.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            double? latitude = snapshot.data!['latitude'];
            double? longitude = snapshot.data!['longitude'];
            double? distance;
            double? clgdistance;
            String? timeEstimation;
            String? clgtimeEstimation;

            if (_currentPosition != null) {
              distance = calculateDistance(
                _currentPosition.latitude,
                _currentPosition.longitude,
                latitude!,
                longitude!,
              );
              clgdistance = calculateDistance(
                destinationLatitude,
                destinationLongitude,
                latitude,
                longitude,
              );
              timeEstimation = estimateTime(distance);
              clgtimeEstimation = clgestimateTime(clgdistance);
              percentage = ((totallength-(distance/1000)) / totallength) * 100;
            } else {
              // Handle the case where the route hasn't been selected yet
              return Center(
                child: Text(
                  'No route selected.',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              );
            }

            // Check if the bus has crossed the college
            bool busCrossed = usertime > clgtime;


            return Container(
              height: double.infinity,
              width: double.infinity,
              child: Stack(
                children: [

                  GoogleMap(

                    initialCameraPosition: CameraPosition(
                      target: LatLng(latitude!, longitude!),
                      zoom: 14.0,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('locationMarker'),
                        position: LatLng(latitude, longitude),
                        icon: BitmapDescriptor.fromBytes(compressedBytes!),
                        infoWindow: const InfoWindow(title: 'Bus Location'),
                      ),
                      Marker(
                        markerId: const MarkerId('destinationMarker'),
                        position: LatLng(destinationLatitude, destinationLongitude),
                        icon: BitmapDescriptor.defaultMarker,
                        infoWindow: const InfoWindow(title: 'Our College'),
                      ),
                      if (_currentPosition != null && userMarkerBytes != null)
                        Marker(
                          markerId: const MarkerId('userLocation'),
                          position: LatLng(_currentPosition.latitude,
                              _currentPosition.longitude),
                          icon: BitmapDescriptor.fromBytes(userMarkerBytes!),
                          infoWindow: const InfoWindow(title: 'Your Location'),
                        ),
                    },

                  ),

                  Positioned(
                    top: 85,
                    right: 20,
                    left: 20,// Adjusted to position at the right corner
                    child: Container(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end, // Align children to the end (right)
                        children: [
                          Visibility(
                            visible: isBellButtonClicked,
                            child: Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                isBellButtonClicked = !isBellButtonClicked; // Toggle the bell button state
                                // Start the timer 5 minutes before the estimated arrival time
                                if (isBellButtonClicked && distance != null) {
                                  startTimer(distance);
                                } else {
                                  // If bell button is turned off, cancel the timer if it's running
                                  _timer?.cancel();
                                }
                              });
                              print("Timer clicked");
                            },
                            icon: Icon(
                              isBellButtonClicked ? Icons.notifications_active : Icons.notification_add,
                              color: isBellButtonClicked ? Colors.indigo : Colors.black, // Change icon color
                              size: 30, // Adjust icon size as needed
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),


                  Positioned(
                    bottom: 10,
                    left: 30,
                    right: 30,
                    child: ElevatedButton(
                      onPressed: () {
                        launchGoogleMapsNavigation(
                          latitude!,
                          longitude!,
                          destinationLatitude,
                          destinationLongitude,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(80.0),
                        ),
                      ),
                      child: const Text(
                        'Navigate to College',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(80),
                        ),
                        child: Text(
                          'Arriving within : $timeEstimation',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    left: 10,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(80),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(80),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              color: Colors.white.withOpacity(0.4),
                              child: Text(
                                'You will reach college at : $clgtimeEstimation',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (busCrossed) // Display "Bus Crossed !" text if bus has crossed the college
                    Positioned(
                      bottom: 65,
                      left: 25,
                      right: 25,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(80),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            color: Colors.transparent, // Set background color to transparent
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent, // Set background color to transparent
                                borderRadius: BorderRadius.circular(80),
                              ),
                              child: Center(
                                child: Text(
                                  'Bus approaching college !',
                                  textAlign: TextAlign.center, // Center the text
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red, // Change text color to red
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Add the progress bar here
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Visibility(
                      visible: !busCrossed,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.red,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        value: percentage != null ? percentage! / 100 : 0.0,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 100, // Adjust the position as needed
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Visibility(
                        visible: _busHalted, // Show the text when bus is halted
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.red, // Set background color to red
                            borderRadius: BorderRadius.circular(80),
                          ),
                          child: Text(
                            'Bus is halted !',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Set text color to white
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            );
          } else {
            // Show loading or default map
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }


}