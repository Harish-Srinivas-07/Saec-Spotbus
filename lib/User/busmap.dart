import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';

class BusMap extends StatefulWidget {
  const BusMap({Key? key}) : super(key: key);

  @override
  _BusMapState createState() => _BusMapState();
}

class _BusMapState extends State<BusMap> {
  late String _selectedRNO = '';
  late String _selectedRoute = ''; // To store the selected route


  late Uint8List markerIcon;
  late Uint8List userMarkerBytes;
  late Uint8List selMarker;
  var distanceInKilometers;
  late LatLng _currentPosition =
  LatLng(13.065697115739109, 80.11098840063154); // Store current user position
  var _positionObtained = true ;
  StreamController<List<Map<String, dynamic>>> _busDataController =
  StreamController<List<Map<String, dynamic>>>.broadcast();

  // Define custom marker icons
  late BitmapDescriptor selectedMarkerIcon;
  late BitmapDescriptor unselectedMarkerIcon;
  late BitmapDescriptor userMarkerIcon;

  int _selectedIndex = -1; // Maintain the index of the selected item

  Completer<GoogleMapController> _controller = Completer();

// Load custom marker icons in initState()
  @override
  void initState() {
    super.initState();
    loadMarkerIcon();
    loadUserMarkerBytes();
    loadunselect();
    _startFetchingBusData();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _getCurrentLocation(); // Fetch user's current location
    });
  }


  @override
  void dispose() {
    _busDataController.close();
    super.dispose();
  }

  Future<void> loadMarkerIcon() async {
    ByteData data = await rootBundle.load('assets/img/bus_stop_pointer.png');
    markerIcon = data.buffer.asUint8List();
    unselectedMarkerIcon = BitmapDescriptor.fromBytes(markerIcon);
  }

  Future<void> loadunselect() async {
    ByteData data = await rootBundle.load('assets/img/pointer.png');
    selMarker = data.buffer.asUint8List();
    selectedMarkerIcon = BitmapDescriptor.fromBytes(selMarker);
  }


  Future<void> loadUserMarkerBytes() async {
    ByteData data = await rootBundle.load('assets/img/man.png');
    userMarkerBytes = data.buffer.asUint8List();
    userMarkerIcon = BitmapDescriptor.fromBytes(userMarkerBytes);
  }


  Widget _buildGoogleMap(List<Map<String, dynamic>> busData, String selectedRoute) {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: _currentPosition, // Set initial camera position to current user location
        zoom: 10,
      ),
      markers: Set<Marker>.from(_buildMarkers(busData, _selectedRNO, selectedRoute)),
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
    );
  }



  List<Marker> _buildMarkers(List<Map<String, dynamic>> busDataList, String selectedRNO, String selectedRoute) {
    List<Marker> markers = [];
    for (var busData in busDataList) {
      MarkerId markerId = MarkerId('${busData['rno']}${busData['route']}');
      // Check if route is null before concatenating
      String infoWindowText = busData['rno'];
      if (busData['route'] != null) {
        infoWindowText += ' ${busData['route']}';
      }
      markers.add(

        Marker(
          markerId: markerId,
          position: LatLng(
            busData['latitude'] as double,
            busData['longitude'] as double,
          ),
          icon: selectedRNO == busData['rno'] && selectedRoute == busData['route'] ? selectedMarkerIcon : unselectedMarkerIcon,
          infoWindow: InfoWindow(
            title: infoWindowText,
          ),
          onTap: () {
            setState(() {
              _selectedRNO = busData['rno'];
              _selectedRoute = busData['route']; // Update selected RNO and route
            });
            _calculateDistanceAndUpdateUI(busData['latitude'], busData['longitude']);
          },
        ),
      );
    }
    // Add user marker
    markers.add(
      Marker(
        markerId: const MarkerId('user'),
        position: _currentPosition,
        icon: userMarkerIcon,
        infoWindow: const InfoWindow(
          title: 'Your Location',
        ),
      ),
    );
    return markers;
  }




  void _startFetchingBusData() {
    DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('locations');
    dbRef.onValue.listen((event) {
      List<Map<String, dynamic>> busDataList = [];
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> locations = event.snapshot.value as Map<dynamic, dynamic>;
        locations.forEach((key, value) {
          busDataList.add({
            'latitude': value['latitude'],
            'longitude': value['longitude'],
            'rno': value['rno'],
            'timestamp': value['timestamp'],
            'route':value['route'],
          });
        });
      }
      _busDataController.add(busDataList);
    });
  }

// Function to fetch user's current location
  Future<void> _getCurrentLocation() async {

    bool serviceEnabled;
    LocationPermission permission;

    // Show loader while fetching location
    setState(() {
      _positionObtained = false; // Set flag to false while fetching
    });

    // Show loader
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dialog from being dismissed by tapping outside
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, prompt the user to enable them
      serviceEnabled = await Geolocator.openLocationSettings();
      if (!serviceEnabled) {
        // User declined to enable location services, handle accordingly
        print('Location services are disabled.');
        Navigator.pop(context); // Dismiss loader
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
        print(
            'Location permissions are permanently denied, we cannot request permissions.');
        Navigator.pop(context); // Dismiss loader
        return;
      }

      if (permission == LocationPermission.denied) {
        // Permissions are denied, handle accordingly
        print('Location permissions are denied.');
        Navigator.pop(context); // Dismiss loader
        return;
      }
    }

    // Fetch current position if everything is fine
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _positionObtained = true; // Set flag to true to indicate position is obtained
    });

    // Dismiss loader
    Navigator.pop(context);
  }

  void _calculateDistanceAndUpdateUI(double busLatitude, double busLongitude) async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      busLatitude,
      busLongitude,
    );
    setState(() {
      distanceInKilometers = distanceInMeters / 1000;
    });
    print('Ans from func call $distanceInKilometers');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60.0,
        backgroundColor: const Color(0xFFE7F2FE),
        title: const Text(
          'Nearby buses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Add the new container to display the distance
          if (_selectedRNO.isNotEmpty && distanceInKilometers != null)
            Container(
              width: double.infinity,
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(0),
                color: Colors.indigo[800],
              ),
              child: Center(
                child: Text(
                  '${distanceInKilometers.toStringAsFixed(2)} km away from you',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),



          // Expanded widget containing the GoogleMap
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _busDataController.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final busData = snapshot.data;
                  if (busData != null && busData.isNotEmpty) {
                    return _buildGoogleMap(busData, _selectedRoute);
                  } else {
                    return const Center(
                      child: Text(
                        'No bus data available',
                        style: TextStyle(
                          color: Colors.red, // Set text color to red
                          fontWeight: FontWeight.bold, // Make text bold
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ),

          // // SizedBox for spacing
          // const SizedBox(height: 10),

          // Container with ListView.builder for displaying bus routes
// Container with ListView.builder for displaying bus routes
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _busDataController.stream,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final busDataList = snapshot.data!;
                return Container(
                  color: const Color(0xFFE7F2FE),
                  height: 60.0,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 10.0, top: 10.0),
                    scrollDirection: Axis.horizontal,
                    itemCount: busDataList.length,
                    itemBuilder: (context, index) {
                      final busData = busDataList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedIndex == index ? Colors.indigo[800] : Colors.blue[500],
                            borderRadius: BorderRadius.circular(18.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                // Update the selected index
                                _selectedIndex = index;
                                _selectedRNO = busData['rno']; // Update selected RNO
                                _selectedRoute = busData['route']; // Update selected route
                              });
                              _calculateDistanceAndUpdateUI(busData['latitude'], busData['longitude']);
                              print('Selected Route for calc: ${busData['rno']}${busData['route']}');
                            },
                            child: Center(
                              child: Text(
                                ' ${busData['route']} : ${busData['rno']}',
                                style: TextStyle(
                                  color: _selectedIndex == index ? Colors.white : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              } else {
                return SizedBox.shrink(); // Return an empty SizedBox if no data
              }
            },
          ),
        ],
      ),
    );
  }


}
