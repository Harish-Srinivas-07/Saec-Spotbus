import 'dart:async';

import 'package:collegebustracking/User/tracklocation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utills/list.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(userapply());
}

class userapply extends StatefulWidget {
  final String? selectedRoute; // Receive the selected route
  final String? selectedRna;
  final String? selectedPath;
  final String? selectedKey;
  final String? selectedMob;

  userapply({Key? key, this.selectedRoute, this.selectedRna, this.selectedPath , this.selectedKey, this.selectedMob}) : super(key: key);

  @override
  State<userapply> createState() => _AmbulanceHomeState(selectedRoute);
}

class _AmbulanceHomeState extends State<userapply> {
  String? ct;

  String? selectedRoute;
  String? selectedRna;
  String? selectedPath;
  String? selectedKey;
  String? selectedMob;

  String? selectedVehicle;
  late Timer timer;
  late Position currentPosition;
  DateTime currentDate = DateTime.now();
  late String formattedDate;
  late String formattedTime;
  late TextEditingController textController1;
  late TextEditingController textController2;
  late TextEditingController textController3;
  bool isTextController1NotEmpty = false;
  bool isVisible = false;
  String akey = '';

  String mob = '';
  String lat = '';
  String lon = '';

  bool track = false;

  _AmbulanceHomeState(this.selectedRoute); // Remove selectedRoute parameter from here

  @override
  void initState() {
    super.initState();
    formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);
    textController1 = TextEditingController();
    textController2 = TextEditingController();
    textController3 = TextEditingController();
    textController1.addListener(updateVisibility);
    print('Formatted Date: $formattedDate');
    formattedTime = DateFormat('HH:mm:ss').format(currentDate);

    // Assign selectedRoute from widget to local variable
    selectedRoute = widget.selectedRoute;
    // Assign selectedRna from widget to local variable
    selectedRna = widget.selectedRna;
    // Assign selectedPath from widget to local variable
    selectedPath = widget.selectedPath;

    selectedKey= widget.selectedKey;
    selectedMob= widget.selectedMob;



    // Start the timer to check for changes in lat
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Check if $lat has changed
      if (lat.isNotEmpty && lat != 'calculating') {
        // If $lat has changed, make the container visible
        setState(() {
          isVisible = true;
        });
        // After 10 seconds, hide the container again
        Future.delayed(const Duration(seconds: 5), () {
          setState(() {
            isVisible = false;
          });
        });
      }
    });
  }



  @override
  void didUpdateWidget(userapply oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update text fields if selectedRna or selectedPath changes
    if (widget.selectedRna != selectedRna || widget.selectedPath != selectedPath) {
      setState(() {
        selectedRoute = widget.selectedRoute;
        selectedRna = widget.selectedRna;
        selectedPath = widget.selectedPath;
        akey = widget.selectedKey!;
        mob = widget.selectedMob!;
        textController1.text = selectedRna ?? '';
        textController2.text = selectedPath ?? '';
        fetchUserLocation();
      });
    }
    if (widget.selectedRoute != selectedRoute ) {
      setState(() {
        selectedRoute = widget.selectedRoute;
        isVisible = true; // Set isVisible to true when selectedRoute changes
      });
      fetchdata(); // Update data when selectedRoute changes
    }
  }



  @override
  void dispose() {
    textController1.dispose();
    textController2.dispose();
    textController3.dispose();
    timer.cancel();
    super.dispose();
  }

  void updateVisibility() {
    setState(() {
      isTextController1NotEmpty = textController1.text.isNotEmpty;
    });
  }

  Future<void> click() async {}

  void _launchPhoneCall(BuildContext context, String phoneNumber) async {
    // Ensure that mob is assigned the value of selectedMob
    String mob = phoneNumber;

    // Copy the phone number to the clipboard
    await Clipboard.setData(ClipboardData(text: phoneNumber));

    // Show a snackbar to indicate that the phone number is copied
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phone number copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );

    // Launch the phone call
    if (await launcher.canLaunchUrl(Uri.parse('tel:$phoneNumber'))) {
      await launcher.launchUrl(Uri.parse('tel:$phoneNumber'));
    } else {
      print('Could not launch phone call');
    }
  }

  Future<void> fetchUserLocation() async {
    try {

      DatabaseReference locationreference =
      FirebaseDatabase.instance.ref().child('locations');

      Query locquery = locationreference.orderByChild('rno').equalTo(selectedRoute);

      // Fetch current user location
      Position userPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      locquery.onValue.listen((event) {
        if (event.snapshot.value != null) {
          print('Locations Data: ${event.snapshot.value}');

          var outerMap = event.snapshot.value as Map<Object?, Object?>?;

          if (outerMap != null && outerMap.isNotEmpty) {
            var firstKey = outerMap.keys.first;
            var innerMap = outerMap[firstKey] as Map<Object?, Object?>?;

            if (innerMap != null) {
              String latitude = innerMap['latitude']?.toString() ?? '13.065697115739109';
              String longitude = innerMap['longitude']?.toString() ?? '80.11098840063154';

              print('Tracking lat long:$latitude $longitude');
              lat = innerMap['latitude']?.toString() ?? 'calculating';
              lon = innerMap['longitude']?.toString() ?? 'calculating';

              // Calculate distance between user and bus location
              double distanceInMeters = Geolocator.distanceBetween(
                  userPosition.latitude, userPosition.longitude,
                  double.parse(innerMap['latitude']?.toString() ?? '0'),
                  double.parse(innerMap['longitude']?.toString() ?? '0'));

              setState(() {
                // Update lat and lon with distance in kilometers
                lat = '${(distanceInMeters / 1000).toStringAsFixed(2)} kms';
                lon = ''; // You can set this as needed
                isVisible = true;
                track = true;// Update isVisible when $lat changes
              });

            } else {
              print('Inner map is null');
            }
          } else {
            print('Outer map is null or empty');
          }
        } else {
          print('No track location data found in the database');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No live buses found'),
              duration: Duration(seconds: 3),
            ),
          );
          // Clear the form and reset relevant variables
          setState(() {
            textController1.clear();
            textController2.clear();
            textController3.clear();
            isVisible = false;
          });
        }
      }, onError: (Object error) {
        print('Error fetching location data: $error');
      });
    } catch (e) {
      print('Error fetching user location: $e');
    }
  }




  Future<void> fetchdata() async {
    try {

      DatabaseReference reference =
      FirebaseDatabase.instance.ref().child('Tracking');


      setState(() {
        isTextController1NotEmpty = textController1.text.isNotEmpty;
      });

      Query query = reference.orderByChild('rno').equalTo(selectedRoute);


      query.onValue.listen((event) {
        if (event.snapshot.value != null) {
          print('Retrieved Data: ${event.snapshot.value}');

          var outerMap = event.snapshot.value as Map<Object?, Object?>?;

          if (outerMap != null && outerMap.isNotEmpty) {
            var firstKey = outerMap.keys.first;
            var innerMap = outerMap[firstKey] as Map<Object?, Object?>?;

            if (innerMap != null) {
              String rna = innerMap['rna']?.toString() ?? 'Route';
              String rno = innerMap['path']?.toString() ?? '1A';
              akey = innerMap['dkey']?.toString() ?? 'abcdefghijklmnop';
              mob = innerMap['mobile']?.toString() ?? '044 2680 1999';

              print('Tracking :$akey');

              textController1.text = rna;
              textController2.text = rno;
              textController3.text = rno;

            } else {
              print('Inner map is null');
            }
          } else {
            print('Outer map is null or empty');
          }
        } else {
          print('No location data found in the database');
          // Clear the form and reset relevant variables
          setState(() {
            textController1.clear();
            textController2.clear();
            textController3.clear();
            isVisible = false;
            track = true;
          });
        }
      }, onError: (Object error) {
        print('Error fetching location data: $error');
      });

      fetchUserLocation();

    } catch (e) {
      print('Error fetching data: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    bool isTextController1NotEmpty = textController1.text.isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFFE7F2FE),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              AnimatedOpacity(
                opacity: isVisible ? 1.0 : 0,
                duration: const Duration(seconds: 1),
                child: Container(
                  width: double.infinity,
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(0),
                    color: Colors.yellow[800],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$lat away from you',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text(
                          'App Info',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to our first College Bus Tracking app 🚌!\n\nDeveloped '
                                    'by students \nfrom the CSE A 2020 Batch 😎,\nthis app '
                                    'simplifies our campus commute.\n\n📣 Notice to All '
                                    'Users:\nWe believe in collective innovation to enhance '
                                    'campus life. Share your ideas to shape our college.'
                                    '\n\nYour contributions make a difference! If you encounter '
                                    'any bugs or have suggestions for improvement, please let us know. '
                                    'Together, we can make this app even better.'
                                    '\n\nMeet the minds behind it: '
                                    '\n🛡️ Dinesh Kumar R,\n🕶️ Ganpathi V, and\n 🛠️ Harish Srinivas SR.'
                                    '\n\nWe are under the guidance of Dr. D. Hemanand, Professor.',
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 10),
                              GestureDetector(
                                onTap: () {
                                  // Open the feedback form URL in the browser
                                  launch('https://forms.gle/xvMAzNSLac6nHwwa7');
                                },
                                child: Text(
                                  'Feedback form ',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child:Text(
                              'Close',
                              style: TextStyle(
                                color: Colors.red, // Red color for the close button
                                fontWeight: FontWeight.bold, // Bold text for the close button
                              ),
                            ),
                          ),
                        ],
                      );

                    },
                  );

                },
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE7F2FE),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/SAEC.png',
                      width: 130, // Adjust the width of the image as needed
                      height: 130, // Adjust the height of the image as needed
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Track College Bus',
                style: TextStyle(
                  color: Colors.indigo,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 200, // Adjust the width as needed
                height: 50, // Adjust the height as needed
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80), // Adjust the border radius as needed
                  border: Border.all(
                    color: Colors.transparent, // Adjust the border color as needed
                    width: 1, // Adjust the border width as needed
                  ),
                ),
                child: DropdownButton<String>(
                  value: selectedRoute,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRoute = newValue;
                    });
                    fetchdata();
                  },
                  items: DestinationsList.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10), // Adjust the padding as needed
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  hint: const Padding(
                    padding:  EdgeInsets.symmetric(horizontal: 10), // Adjust the padding as needed
                    child: Text(
                      'Select Route',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  isExpanded: true, // Allow the dropdown button to expand horizontally to fit the container width
                ),
              ),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: textController1,
                  decoration: InputDecoration(
                    labelText: '   Bus Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(80.0),
                      borderSide: const BorderSide(
                          color: Color.fromARGB(255, 46, 48, 146)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: textController2,
                  decoration: InputDecoration(
                    labelText: '   Route Destination',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(80.0),
                      borderSide: const BorderSide(
                          color:  Color.fromARGB(255, 46, 48, 146)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Inside the Column widget children list
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // Previous widgets...
                  const SizedBox(height: 0),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 0),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Visibility(
                                visible: isTextController1NotEmpty,
                                child: IconButton(
                                  onPressed: () {
                                    print('Calling Driver');
                                    _launchPhoneCall(context, mob);
                                  },
                                  icon: Image.asset(
                                    'assets/images/dialer.png',
                                    width: 55,
                                    height: 55,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Visibility(
                                visible: isTextController1NotEmpty,
                                child: SizedBox(
                                width: 200, // Adjust the width as needed
                                child:ElevatedButton(
                                  onPressed: () {
                                    // Check if selectedPath, selectedRna, and selectedRoute are not null
                                    // if (track && isVisible) {
                                      // Proceed with navigation
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (context) => trackl(akey: akey),
                                      ));
                                    // } else {
                                    //   // Display an alert box if any of the fields are null
                                    //   showDialog(
                                    //     context: context,
                                    //     builder: (BuildContext context) {
                                    //       return AlertDialog(
                                    //         title: Text('Alert',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.indigo)),
                                    //         content: Text(
                                    //           'Please select any available \nRoute to track buses',
                                    //           style: TextStyle(fontWeight: FontWeight.bold),
                                    //         ),
                                    //         actions: <Widget>[
                                    //           TextButton(
                                    //             onPressed: () {
                                    //               Navigator.of(context).pop();
                                    //             },
                                    //             child: Text(
                                    //               'OK',
                                    //               style: TextStyle(
                                    //                 fontWeight: FontWeight.bold,
                                    //                 color: Colors.red,
                                    //               ),
                                    //             ),
                                    //           ),
                                    //         ],
                                    //       );
                                    //
                                    //     },
                                    //   );
                                    // }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 46, 48, 146),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(15),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.near_me,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        SizedBox(width: 15),
                                        Text(
                                          'Track',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              ),
                              ),

                            ],
                          ),
                          // Add the Text widget to display bus location
                          // icon code is here


                        ],
                      ),
                    ],
                  ),

                ],
              ),

              // Add the Text widget to display bus location
            ],
          ),
        ),
      ),
    );
  }

}
