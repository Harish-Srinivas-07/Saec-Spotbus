import 'package:collegebustracking/User/userapply.dart';
import 'package:collegebustracking/User/userlogin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'fgsdfs.dart';
import 'package:firebase_database/firebase_database.dart';
import 'busmap.dart';

void main() {
  runApp(const MaterialApp(
    home: userboard(),
  ));
}

final List<Widget> _pages = [
  userapply(),
];

class userboard extends StatefulWidget {
  const userboard({Key? key}) : super(key: key);

  @override
  State<userboard> createState() => _DashboardState();
}

class _DashboardState extends State<userboard> {
  var islogoutloading = false;
  int _currentIndex = 0;
  String? selectedRoute; // Store the selected route globally
  String? selectedPath;
  String? selectedRna;
  String? selectedKey;
  String? selectedMob;

  // Function to fetch bus numbers with their corresponding rna and path from Firebase Realtime Database
  Future<List<Map<String, String>>> getBusInfo() async {
    List<Map<String, String>> busInfoList = [];
    try {
      DatabaseReference dbRef = FirebaseDatabase.instance.ref().child("Tracking");
      DataSnapshot dataSnapshot = await dbRef.once().then((event) => event.snapshot);
      Map<dynamic, dynamic>? buses = dataSnapshot.value as Map<dynamic, dynamic>?;
      if (buses != null) {
        buses.forEach((key, value) {
          String rno = value['rno'];
          String rna = value['rna'];
          String path = value['path'];
          String dkey = value['dkey'];
          String mob = value['mobile'];
          busInfoList.add({"rno": rno, "rna": rna, "path": path, "dkey": dkey, "mob":mob});
        });
      }
    } catch (e) {
      print("Error fetching bus information: $e");
    }
    return busInfoList;
  }



  logoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Logout Confirmation',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Are you sure you want to logout?',
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[500], // Set background color to pale green
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the alert box
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo, // Set background color to pale red
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        logout(); // Call logout function if user confirms
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  logout() async {
    setState(() {
      islogoutloading = true;
    });

    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => userlogin()));

    setState(() {
      islogoutloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          // Return false to block the back button
          return false;
        },
        child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[100],
        toolbarHeight: 70.0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 10.0), // Adjust the padding as needed
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const thi()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(80.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20.0), // Add padding to both sides
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.free_cancellation,
                    color: Colors.white,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Bus Late ?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(), // Add Spacer between the buttons
          Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 20.0), // Adjust the padding as needed
            child: ElevatedButton.icon(
              onPressed: () {
                logoutConfirmation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[900],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(80.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20.0), // Add padding to both sides
              ),
              icon: islogoutloading ? const CircularProgressIndicator() : const Icon(Icons.exit_to_app),
              label: const Padding(
                padding: EdgeInsets.all(5.0), // Adjust the padding around the label
                child: Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),

      body: userapply(selectedRoute: selectedRoute ,selectedPath:selectedPath ,selectedRna:selectedRna ,
          selectedKey:selectedKey , selectedMob: selectedMob),
      bottomNavigationBar: Container(
        height: 70, // Adjust the height according to your preference
        color: Colors.blue[100],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () {
                // Fetch and display available bus numbers along with rna and path when bus icon is clicked
                getBusInfo().then((busInfoList) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text(
                          'Available Routes',
                          style: TextStyle(
                            color: Color.fromARGB(255, 1, 121, 6),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: busInfoList.map((busInfo) {
                              String busNumber = busInfo['rno']!;
                              String busRna = busInfo['rna']!;
                              String busPath = busInfo['path']!;
                              String busKey = busInfo['dkey']!;
                              String busMob = busInfo['mob']!;
                              return ListTile(
                                title: Text('$busNumber - $busRna'),
                                onTap: () {
                                  // print('Selected Route from Dashboard: $busNumber');
                                  // print('Selected Route from Dashboard: $busRna');
                                  // print('Selected Route from Dashboard: $busPath');
                                  // print('Selected Route from Dashboard: $busKey');
                                  // print('Selected Route from Dashboard: $busMob');
                                  setState(() {
                                    selectedRoute = busNumber;
                                    selectedRna = busRna;
                                    selectedPath = busPath;
                                    selectedKey = busKey;
                                    selectedMob = busMob;
                                  });
                                  Navigator.of(context).pop();
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
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
                }).catchError((error) {
                  print("Error fetching bus information: $error");
                });
              },
              icon: Image.asset(
                'assets/images/schoolbuspng.gif',
                height: 70,
                width: 95,
              ),
            ),




            Padding(
              padding: const EdgeInsets.only(right: 0.0), // Adjust the right spacing as needed
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BusMap()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(80.0),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.map,
                      color: Colors.black,
                    ),
                    SizedBox(width: 10), // Add some space between icon and text
                    Text(
                      'Nearby buses',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),


          ],
        ),
      ),
    )
    );
  }
}

