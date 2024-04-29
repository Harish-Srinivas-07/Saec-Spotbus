import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utills/list.dart';
import 'live.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AmbulanceHome());
}

class AmbulanceHome extends StatefulWidget {
  final String? ukey;
  final String? dname;
  final String? did;
  final String? mobile;

  const AmbulanceHome({
    Key? key,
    this.ukey,
    this.dname,
    this.did,
    this.mobile,
  });

  @override
  State<AmbulanceHome> createState() => _AmbulanceHomeState();
}

class _AmbulanceHomeState extends State<AmbulanceHome> {
  String? ct;

  String? selectedRoute;
  String? selectedVehicle;
  DateTime currentDate = DateTime.now();
  late String formattedDate;
  late String formattedTime;
  int _currentIndex = 0;
  bool isEnglishSelected = true;
  bool update = false;


  @override
  void initState() {
    super.initState();
    formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);
    formattedTime = DateFormat('HH:mm:ss').format(currentDate);
    _loadSelectedValues();
    update = false;// Load saved values when the widget initializes
  }

  // save the value locally
  Future<void> _saveSelectedValues() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('selectedRoute', selectedRoute ?? '');
      prefs.setString('selectedVehicle', selectedVehicle ?? '');
      prefs.setString('ct', ct ?? '');
      prefs.setBool('update', update ?? false);
    } catch (e) {
      print('Error saving selected values: $e');
    }
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
      print(update);
    } catch (e) {
      print('Error loading selected values: $e');
    }
  }


  Future<List<String>> getBusNumbers() async {
    List<String> busNumbers = [];
    try {
      DatabaseReference dbRef =
      FirebaseDatabase.instance.ref().child("Tracking");
      DataSnapshot dataSnapshot =
      await dbRef.once().then((event) => event.snapshot);
      Map<dynamic, dynamic>? buses =
      dataSnapshot.value as Map<dynamic, dynamic>?;
      if (buses != null) {
        buses.forEach((key, value) {
          busNumbers.add(value['rno']);
        });
      }
    } catch (e) {
      print("Error fetching bus numbers: $e");
    }
    return busNumbers;
  }

  Future<void> _saveProduct() async {
    try {

      // Check if any of the required values are null
      if (selectedRoute == null || selectedVehicle == null || ct == null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                isEnglishSelected ? 'Alert' : 'எச்சரிக்கை',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                isEnglishSelected
                    ? 'Please select all required values.'
                    : 'அவசியமான அமைப்புகளையும் தேர்வு செய்யவும்.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(isEnglishSelected ? 'OK' : 'சரி'),
                ),
              ],
            );
          },
        );
        return; // Return early if any required value is null
      }
      update = true;
      await _saveSelectedValues(); // Save selected values before updating Firebase
      FirebaseAuth _auth = FirebaseAuth.instance;
      User? user = _auth.currentUser;
      String? userId = user?.uid;


      DatabaseReference _database = FirebaseDatabase.instance.ref();

      _database.child('Driver').child(userId!).once().then((event) async {
        if (event.snapshot.value != null) {
          DataSnapshot snapshot = event.snapshot;
          Map<dynamic, dynamic> driverData =
          snapshot.value as Map<dynamic, dynamic>;
          String? dname = driverData['hosname'];
          String? mobile = driverData['mobile'];

          await _database.child('Tracking').child(userId).set({
            "dname": dname,
            "mobile": mobile,
            "did": widget.did,
            "rno": selectedRoute,
            "rna": selectedVehicle,
            "path": ct,
            "status1": 'request',
            "status2": 'request',
            "time": formattedTime,
            "date": formattedDate,
            "dkey": userId,
          });

          // Update the database with the new location data under the "locations" node with the user ID
          await FirebaseDatabase.instance
              .ref()
              .child('locations')
              .child(userId)
              .set({
            'latitude': 13.064720319462916,
            'longitude': 80.11108553648604,
            'timestamp': ServerValue.timestamp,
            'rno': selectedRoute, // Add 'rno' to the location data
            'route': selectedVehicle,
          });


          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              width: 350,
              content: Center(
                child: Text(
                  isEnglishSelected ? 'Updated Successfully ✓' : 'புதுப்பிக்கப்பட்டது ✓',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
              elevation: 4.0,
            ),
          );
          print('$update check from submit');
        } else {
          print('Driver data not found.');
        }
      });
    } catch (e) {
      print('Error saving product: $e');
    }
    // Pass the boolean value when navigating to live.dart
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Live(updateValue: true), // Pass the boolean value
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7F7DE),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[

              const SizedBox(height: 0),
              Container( // Adjust width as needed
                height: 35,
                padding: const EdgeInsets.symmetric(horizontal: 20), // Adjust padding as needed
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(0), // Adjust border radius as needed
                  color: Colors.green[700], // Set background color to green
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Align text to the left and switch to the right
                  children: [
                    Text(
                      isEnglishSelected ? 'தமிழுக்கு மாற்றவும்' : 'Change to English' ,
                      style: const TextStyle(
                        color: Colors.white, // Set text color to white
                        fontSize: 15, // Set font size to 15
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: isEnglishSelected,
                        onChanged: (value) {
                          setState(() {
                            isEnglishSelected = value;
                          });
                        },
                        activeColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),


              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          isEnglishSelected ? 'Running Buses': 'பேருந்து பட்டியல்',
                          style: const TextStyle(
                            color:  Color.fromARGB(255, 1, 121, 6),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        content: FutureBuilder<List<String>>(
                          future: getBusNumbers(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child:  CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else if (snapshot.hasData &&
                                snapshot.data!.isEmpty) {
                              return Text(isEnglishSelected ? 'No routes available.' : 'வழிகள் இல்லை.');
                            } else {
                              List<String> busNumbers = snapshot.data ?? [];
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: busNumbers
                                    .map((busNumber) => ListTile(
                                  title: Text(busNumber),
                                  onTap: () {
                                    setState(() {
                                      selectedRoute = busNumber;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ))
                                    .toList(),
                              );
                            }
                          },
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(isEnglishSelected ? 'Close' : 'மூடு'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Image.asset(
                  'assets/images/schoolbuspng.gif',
                  width: 200,
                  height: 100,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isEnglishSelected ? 'Select Today Route': 'இன்றைய பயணம்',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 55.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60.0),
                    color: Colors.white,
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedRoute,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedRoute = newValue;
                      });
                    },
                    items: isEnglishSelected
                        ? englishRouteNames
                        .map<DropdownMenuItem<String>>(
                            (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value , style: const TextStyle(fontWeight: FontWeight.bold)),
                        ))
                        .toList()
                        : tamilRouteNames
                        .map<DropdownMenuItem<String>>(
                            (String value) => DropdownMenuItem<String>(
                          value: routeNameMapping[value]!,
                          child: Text(value),
                        ))
                        .toList(),
                    decoration: InputDecoration(
                      hintText: isEnglishSelected ?  ' Select Route' : ' பாதை தேர்வு' ,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 16.0,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 55.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60.0),
                    color: Colors.white,
                  ),
                  child: DropdownButtonFormField<String>(
                    value: ct,
                    onChanged: (String? newValue) {
                      setState(() {
                        ct = newValue;
                      });
                    },
                    items: [
                      'College to Route',
                      'Route to College',
                    ]
                        .map<DropdownMenuItem<String>>(
                            (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value , style: const TextStyle(fontWeight: FontWeight.bold)),
                        ))
                        .toList(),
                    decoration: InputDecoration(
                      hintText: isEnglishSelected ? ' From where ?' : ' எங்கிருந்து ?',
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 16.0,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 100.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60.0),
                    color: Colors.white,
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedVehicle,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedVehicle = newValue;
                      });
                    },
                    items: [
                      '2', '3', '4', '18A',
                      '21', '22', '22', '23',
                      '24', '25', '27A', '28',
                      '29', '30', '33', '34',
                    ]
                        .map<DropdownMenuItem<String>>(
                            (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value , style: const TextStyle(fontWeight: FontWeight.bold)),
                        ))
                        .toList(),
                    decoration: InputDecoration(
                      hintText: isEnglishSelected ? ' Vehicle No' : ' வண்டி எண்',
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 10.0,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  width: 260, // Set the desired width of the button
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(80.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.checklist,
                          color: Colors.white, // Set the icon color to white
                        ),
                        const SizedBox(width: 25), // Reduce the space between the icon and the text
                        Text(
                          isEnglishSelected ? 'Start Trip' : 'தொடங்கு',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
