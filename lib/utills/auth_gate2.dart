import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../Driver/amblogin.dart';
import '../Driver/dashboard.dart';

void main() {
  runApp(new MaterialApp(
    home: new AuthGate2(),

  ));

}

class AuthGate2 extends StatelessWidget {
  const AuthGate2({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context,snapshot) {
          if (!snapshot.hasData) {
            return LoginView();
        }
        //   else{
        // User? user = snapshot.data;
        // String uid = user?.uid ?? ''; // You can use the UID as ne
        //
        // DatabaseReference databaseReference = FirebaseDatabase.instance.ref().child('Driver').child(uid);
        //
        // // Use the onValue stream to listen for changes
        // databaseReference.onValue.listen((event) {
        //   print('Database event received: $event');
        //
        //   // Check if the event contains the data you need
        //   if (event.snapshot != null && event.snapshot.value != null) {
        //     var userData = event.snapshot.value;
        //     print('User data from database: $userData');
        //
        //     // Check if userData is a Map
        //     if (userData is Map<Object?, Object?>) {
        //       // Cast the map to Map<String, dynamic>
        //       Map<String, dynamic> userDataMap = userData.cast<String, dynamic>();
        //
        //       // Access email directly and handle null case
        //       String? emailFromDatabase = userDataMap['address'];
        //       String? ambnumber = userDataMap['ambnumber'];
        //       String? hosname = userDataMap['hosname'];
        //       String? mobile = userDataMap['mobile'];
        //       String? ukey = userDataMap['ukey'];
        //
        //       if (emailFromDatabase != null) {
        //         print('Email from database: $emailFromDatabase');
        //
        //         ScaffoldMessenger.of(context).showSnackBar(
        //           const SnackBar(content: Text('Processing Driver ...')),
        //         );
        //
        //         Navigator.pushReplacement(
        //             context,
        //             MaterialPageRoute(builder: (context) => ambboard(email: emailFromDatabase,  hosname: hosname, ambnumber:ambnumber,
        //                 mobile:mobile,ukey:ukey))
        //         );
        //       } else {
        //         print('Email key is null or not found in userData.');
        //       }
        //     } else {
        //       print('Invalid data structure in the database.');
        //       print('Type of userData: ${userData.runtimeType}');
        //       print('Content of userData: $userData');
        //     }
        //   }
        // });
        // }
          return ambboard();
        }
    );

  }
}