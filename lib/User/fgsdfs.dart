import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

// late form da ithu

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const thi());
}

class thi extends StatefulWidget {

  const thi({super.key});
  @override
  State<thi> createState() => _usrequState();
}


class da{
  final String cname;
  final String caddress;
  final String cmobile;
  final String clocation;
  final String ckey;
  final String cnkey;
  final String date;
  final String members;
  final String naddress;
  final String ngoname;
  final String nkey;
  final String nmobile;
  final String nlocation;

  da(this.cname, this.date,this.caddress,this.cmobile,this.clocation,
      this.ngoname, this.cnkey,this.nkey,this.nmobile,this.nlocation,this.members,
      this.ckey,this.naddress

      );
}

class _usrequState extends State<thi> {

  String authh = "";

  final DatabaseReference _databaseReference =

  FirebaseDatabase.instance.reference().child('Lateform');
  List<da> dataList = [];

  @override
  void initState() {
    super.initState();

    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser;
    String? userId = user?.uid;

    if (userId != null) {
      setState(() {
        authh = userId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80.0,
        backgroundColor: Colors.blue[100],
        title: const Text('Late Announcement',style: TextStyle(color: Colors.black,
          fontWeight: FontWeight.bold)
        ),

      ),
      backgroundColor: const Color(0xFFE7F2FE),
      body: _buildListViewWithDivider(),

    );
  }

  Widget _buildListViewWithDivider() {
    return StreamBuilder(
      stream: _databaseReference
          .orderByChild('status1')
          .equalTo('request')
          .onValue,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
          Map<String, dynamic> data =
          Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          List<String> itemIds = data.keys

              .toList();

          // Check if the list is empty
          if (itemIds.isEmpty) {
            return const Center(
              child: Text(
                'No Lates available.',
                style: TextStyle(
                  color: Colors.indigo, // Set text color to indigo
                  fontWeight: FontWeight.bold, // Make text bold
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: itemIds.length * 2 - 1, // Add dividers
            itemBuilder: (context, index) {
              if (index.isOdd) {
                // Divider
                return const Divider();
              } else {
                // Item
                int itemIndex = index ~/ 2;
                String itemId = itemIds[itemIndex];
                String pname = data[itemId]['pname']?.toString() ?? '';
                String category = data[itemId]['category']?.toString() ?? '';
                String date = data[itemId]['date']?.toString() ?? '';
                String location = data[itemId]['location']?.toString() ?? '';
                String address = data[itemId]['address']?.toString() ?? '';
                String des = data[itemId]['des']?.toString() ?? '';
                String mobile = data[itemId]['mobile']?.toString() ?? '';
                String time = data[itemId]['time']?.toString() ?? '';
                return Card(
                  elevation: 5,
               color: const Color(0xFFE7F2FE),
                  margin: const EdgeInsets.all(15),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: ListTile(
                      title: Container(
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue[200],  // Choose your desired background color
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(' Bus Number : $des',
                            style: TextStyle(color: Colors.indigo[800],fontSize: 18 , fontWeight: FontWeight.bold
                            )),
                      ),

                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Text(date,
                              style: const TextStyle(color: Colors.black,fontSize: 15 ,
                                  fontWeight: FontWeight.w700)),
                          Text('Late time  : $mobile',style: const TextStyle(color: Colors.black,fontSize: 15, fontWeight: FontWeight.w600)),

                          Text('Route   : $address',
                              style: const TextStyle(color: Colors.black,fontSize: 15)),

                          Text('Destination : $location',style: const TextStyle(color: Colors.black,fontSize: 15)),
                          Text('Driver name : $pname',
                              style: const TextStyle(color: Colors.black,fontSize: 15)),
                          Text('Way : $category',
                              style: const TextStyle(color: Colors.black,fontSize: 15)),
                          // Text('on    : $date',style:const TextStyle(color: Colors.black,fontSize: 15)),
                          Text('Entry at : $time',style: const TextStyle(color: Colors.black,fontSize: 15)),
                        ],
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/images/bus_stop.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),

                    ),
                  ),
                );
              }
            },
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          // Handle error or no data case
          return const Center(
            child: Text('No Requests Available.'),
          );
        }
      },
    );
  }
}