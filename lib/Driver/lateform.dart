import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MaterialApp(
    home: Latee(),
  ));
}

class Latee extends StatefulWidget {
  const Latee({Key? key}) : super(key: key);

  @override
  _LateFormState createState() => _LateFormState();
}

class _LateFormState extends State<Latee> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController addressc = TextEditingController();
  final TextEditingController locationc = TextEditingController();
  final TextEditingController mobilec = TextEditingController();
  final TextEditingController timecontroller = TextEditingController();
  final TextEditingController datecontroller = TextEditingController();

  final List<String> _categories = ['College to Route', 'Route to College',];
  late String _selectedCategory = 'Route to College';

  DateTime currentDate = DateTime.now();
  late String formattedDate;
  late String formattedTime;

  @override
  void initState() {
    super.initState();
    formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);
    datecontroller.text = formattedDate;

    formattedTime = DateFormat('hh:mm a').format(currentDate);
    timecontroller.text = formattedTime;

    // Fetch data from Firebase and autofill the form
    fetchDriverData();
  }

  Future<void> fetchDriverData() async {
    try {
      FirebaseAuth _auth = FirebaseAuth.instance;
      User? user = _auth.currentUser;
      String? userId = user?.uid;

      DatabaseReference _database = FirebaseDatabase.instance.ref();
      DatabaseEvent event = await _database.child('Driver').child(userId!).once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        Map<dynamic, dynamic> driverData = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _productNameController.text = driverData['hosname'] ?? 'Driver';
          _descriptionController.text = driverData['ambnumber'] ?? '99';
          addressc.text = driverData['address'] ?? 'College';
          locationc.text = 'SA College';
          mobilec.text = '10 min';
        });
      }
      // Extract the time entered by the user
      String lateTime = timecontroller.text.replaceAll(RegExp(r'[^\d]'), ''); // Extract only digits
      String hour = lateTime.substring(0, 2); // Extract the first two characters as hour
      String minute = lateTime.substring(2, 4); // Extract the next two characters as minutes
      lateTime = hour + minute; // Combine hour and minute
      int timestamp = int.tryParse(lateTime) ?? 0; // Use int.tryParse to handle invalid input gracefully

      if (timestamp >= 830 && timestamp <= 1000) {
        int difference = timestamp - 830; // Ensure the difference is positive
        if (difference >= 60) {
          lateTime = '${(difference ~/ 60)} hr ${(difference % 60)} min'; // Calculate hours and minutes
        } else {
          lateTime = '${difference % 60} min'; // Only display minutes if less than 1 hour
        }
        mobilec.text = lateTime;
      } else {
        lateTime = '10 min';
      }

    } catch (e) {
      print('Error fetching driver data: $e');
    }
  }

  Future<void> _saveProduct() async {
    var data = {
      "pname": _productNameController.text,
      "des": _descriptionController.text,
      "address": addressc.text,
      "location": locationc.text,
      "mobile": mobilec.text,
      "time": timecontroller.text,
      "date": datecontroller.text,
      "status1": 'request',
      "status2": 'request',
      "category": _selectedCategory,
    };

    try {
      FirebaseAuth _auth = FirebaseAuth.instance;
      User? user = _auth.currentUser;
      String? userId = user?.uid;

      DatabaseReference _database = FirebaseDatabase.instance.ref();
      String? dataKey = _database.child('Lateform').push().key;

      // Extract the time entered by the user
      String lateTime = timecontroller.text.replaceAll(RegExp(r'[^\d]'), ''); // Extract only digits
      String hour = lateTime.substring(0, 2); // Extract the first two characters as hour
      String minute = lateTime.substring(2, 4); // Extract the next two characters as minutes
      lateTime = hour + minute; // Combine hour and minute
      int timestamp = int.tryParse(lateTime) ?? 0; // Use int.tryParse to handle invalid input gracefully

      if (timestamp >= 830 && timestamp <= 1000) {
        int difference = timestamp - 830; // Ensure the difference is positive
        if (difference >= 60) {
          lateTime = '${(difference ~/ 60)} hr ${(difference % 60)} min'; // Calculate hours and minutes
        } else {
          lateTime = '${difference % 60} min'; // Only display minutes if less than 1 hour
        }
        mobilec.text = lateTime;
      } else {
        lateTime = '10 min';
      }


      mobilec.text = lateTime;


      await _database.child('Lateform').child(userId!).set({
        "pname": _productNameController.text,
        "des": _descriptionController.text,
        "address": addressc.text,
        "mobile": lateTime,
        "location": locationc.text,
        "status1": 'request',
        "status2": 'request',
        "time": formattedTime,
        "date": datecontroller.text,
        "udkey": userId! + dataKey!,
        "pkey": userId,
        "category": _selectedCategory,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Center(
            child: Text(
              'Submit Successfully',
              style:  TextStyle(
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

      _productNameController.clear();
      _descriptionController.clear();
      addressc.clear();
      mobilec.clear();
      locationc.clear();

    } catch (e) {
      print('Error saving product: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7F7DE), // green light
      appBar: AppBar(
        toolbarHeight: 60.0,
        backgroundColor: const Color(0xFFD7F7DE), // green light
        title: const Padding(
          padding:  EdgeInsets.all(20.0), // Adjust the padding as needed
          child:  Text('Late Entry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 40.0), // Add padding to the left of the icon
          child: IconButton(
            onPressed: () {
              print('Unknown Person Button Pressed');
            },
            icon: const CircleAvatar(
              child:  Icon(Icons.personal_injury_sharp),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 50.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(80.0),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              margin: const EdgeInsets.symmetric(vertical: 5.0),
              child: TextFormField(
                controller: _productNameController,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Driver Name',
                  border: InputBorder.none,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(80.0),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              margin: const EdgeInsets.symmetric(vertical: 5.0),
              child: TextFormField(
                controller: _descriptionController,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Bus number',
                  border: InputBorder.none,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(80.0),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              margin: const EdgeInsets.symmetric(vertical: 5.0),
              child: TextFormField(
                controller: addressc,
                decoration: const InputDecoration(
                  labelText: 'Route name',
                  border: InputBorder.none,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(80.0),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              margin: const EdgeInsets.symmetric(vertical: 5.0),
              child: TextFormField(
                controller: locationc,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: InputBorder.none,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(80.0),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              margin: const EdgeInsets.symmetric(vertical: 5.0),
              child: TextFormField(
                controller: mobilec,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                decoration: const InputDecoration(
                  labelText: 'Late time',
                  border: InputBorder.none,

                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(80.0),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              margin: const EdgeInsets.symmetric(vertical: 5.0),
              child: TextFormField(
                controller: datecontroller,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: InputBorder.none,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(80.0),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              margin: const EdgeInsets.symmetric(vertical: 5.0),
              child: TextFormField(
                controller: timecontroller,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  border: InputBorder.none,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(80.0),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              margin: const EdgeInsets.symmetric(vertical: 5.0),
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Choose Path',
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20.0), // Add space between the form and the button
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0), // Add padding to the bottom
              child: Column(
                children: [
                  SizedBox(
                    height: 50, // Set the desired height here
                    child: ElevatedButton(
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 1, 121, 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(60.0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.more_time,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 15), // Add some spacing between icon and text
                          Text(
                            'Late Register',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),


          ],
        ),

      ),
    );
  }
}
