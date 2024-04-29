import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../Driver/dashboard.dart';
import '../User/dashboard.dart';

class AuthLogin {

  login(data, context) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: data['email']!,
        password: data['password']!,
      );

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Check if the user's email is verified
        if (!user.emailVerified) {
          print("Email id is not verified");
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Email Not Verified"),
                content: Text("Your email is not verified. Please check your email for verification."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                      FirebaseAuth.instance.signOut(); // Sign out the user
                    },
                    child: Text("OK"),
                  ),
                ],
              );
            },
          );
          return;
        }

        // Print user information
        print("login User ID: ${user.uid}");
        print("User Email: ${data['email']}");
        // You can print other properties of the user object as well

        // Proceed with further checks and navigation
        String userId = user.uid;

        // Check if the user exists in the Driver child of the database
        DatabaseReference databaseReference = await FirebaseDatabase.instance
            .reference().child('Driver').child(userId).child('email');

        await Future.delayed(Duration(seconds: 2));

        // Use once().then() to retrieve the DataSnapshot
        DataSnapshot dataSnapshot = await databaseReference.once().then((
            event) {
          print('Check the datasnapshot Driver');
          print(databaseReference);
          return event.snapshot;
        });


        // Check if dataSnapshot exists and if the email matches
        if (dataSnapshot.exists && dataSnapshot.value == data['email']) {
          // Email exists in the database, proceed with login
          print(dataSnapshot.value);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Processing ...')),
          );

          // Redirect to the appropriate dashboard based on user type
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ambboard()),
          );
          return;
        } else {
          // Display error message if user does not exist or email is invalid
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("Login Error"),
                content: Text('Invalid Access, You may be a Student'),
              );
            },
          );
        }
      } else {
        print("User is not logged in.");
      }
    } catch (e) {
      // Handle login errors
      print('Login error: $e');
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Login Error"),
            content: Text(e.toString()),
          );
        },
      );
    }
  }






  userlogin(data, context) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: data['email'],
        password: data['password'],
      );

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        user = FirebaseAuth.instance.currentUser;

        if (user != null && user.emailVerified) {
          // Store the user's ID and email locally
          String userId = user.uid;
          String userEmail = data['email'];

          // Define the studatabaseReference outside the asynchronous block
          DatabaseReference studatabaseReference = FirebaseDatabase.instance
              .reference().child('Student').child(userId).child('email');

          // Retrieve the value from the database and store it locally
          await studatabaseReference.once().then((event) {
            print(studatabaseReference);
            String? studentEmail = event.snapshot.value as String?;

            // Check if the user is verified and has a valid student email
            if (studentEmail != null && studentEmail == userEmail) {
              print("User is verified and is a student. Proceed with login.");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Processing...')),
              );

              // Redirect to the student dashboard
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => userboard()),
              );
            } else {
              // Display error message if user is not verified or not a student
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Login Error"),
                    content: Text("Invalid Access, You may be a Driver"),
                  );
                },
              );
              print("User is not a verified student. Please check your credentials.");
            }
          });
        } else {
          FirebaseAuth.instance.signOut(); // Sign out the user
          // Show an alert if the user's email is not verified
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Email Not Verified"),
                content: Text("Your email is not verified. Please check your email for verification."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                    },
                    child: Text("OK"),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      // Handle login errors
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Login Error"),
            content: Text(e.toString()),
          );
        },
      );
    }
  }




  Future<void> sendVerificationEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();

      print("Verification email sent to ${user.email}");
    }
  }

}