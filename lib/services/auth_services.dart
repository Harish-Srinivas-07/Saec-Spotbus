
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../Driver/dashboard.dart';
import '../User/dashboard.dart';


class AuthService{

////////////////////////////////////////////////////////////////////


  createuser(data, context) async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: data['email'],
          password: data['password']
      );

      DatabaseReference _database = FirebaseDatabase.instance.reference();
      FirebaseAuth _auth = FirebaseAuth.instance;
      User? user = _auth.currentUser;
      String? userId = user?.uid;

      if (userId != null) {
        await _database.child('Driver').child(userId!).set({
          'email': data['email'],
          'address': data['address'],
          'ambnumber': data['did'],
          'mobile': data['mobile'],
          'hosname': data['dname'],
          'ukey': userId,
          'user': "Driver",
          'status': 'request',
        });

        sendVerificationEmail();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registered Successfully')),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email has been sent')),

        );

      } else {
        throw Exception("User ID is null");
      }
    } catch (e) {
      print("Error creating user: $e");
      showDialog(context: context, builder: (context) {
        return AlertDialog(
          title: Text("Sign Up Failed"),
          content: Text(e.toString()),
        );
      });
    }
  }



  createuseruser(data, context) async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: data['email'],
          password:data['password']
      );

      DatabaseReference _database = FirebaseDatabase.instance.reference();
      FirebaseAuth _auth = FirebaseAuth.instance;
      User? user = _auth.currentUser;
      String? userId = user?.uid;

      DatabaseEvent databaseEvent = await _database.child('Student').once();
      DataSnapshot dataSnapshot = databaseEvent.snapshot;

      await _database.child('Student').child(userId!).set({
        'email': data['email'],
        'name' : data['name'],
        'location':data['location'],
        'user':"Student",
      });


      sendVerificationEmail();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registered Successfully')),

      );

    } catch (e) {
      showDialog(context: context, builder: (context) {
        return AlertDialog(
          title: Text("Sign Up Failed"),
          content: Text(e.toString()),

        );
      });
    }

  }


///////////////////////////////////////////////////////////////////////////////////


  Future<void> sendVerificationEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();

      print("Verification email sent to ${user.email}");
    }
  }

}