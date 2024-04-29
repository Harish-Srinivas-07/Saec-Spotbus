import 'package:collegebustracking/User/usersignup.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

import '../main.dart';
import '../services/auth_services.dart';
import '../utills/appvalidator.dart';
import '../services/auth_login.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(MaterialApp(
    home: userlogin(),
  ));
}

class userlogin extends StatefulWidget {
  userlogin({super.key});

  @override
  State<userlogin> createState() => _LoginViewState();
}

class _LoginViewState extends State<userlogin> {
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final _emailcontroller = TextEditingController();
  final _passwordcontroller = TextEditingController();
  var isLoader = false;
  var authservice = AuthService();
  var authlogin = AuthLogin();


  Future<void> _submitform() async {
    setState(() {
      isLoader = true;
    });

    var data = {
      "email": _emailcontroller.text,
      "password": _passwordcontroller.text
    };
    await authlogin.userlogin(data, context);

    setState(() {
      isLoader = false;
    });

    // Check if email or password is empty
    if (_emailcontroller.text.isEmpty || _passwordcontroller.text.isEmpty) {
      ScaffoldMessenger.of(_formkey.currentContext!).showSnackBar(
        const SnackBar(content: Text('Please enter valid credentials')),
      );
      return;
    }

    try {
      // Save email using shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', _emailcontroller.text);

      ScaffoldMessenger.of(_formkey.currentContext!).showSnackBar(
        const SnackBar(content: Text('Processing...')),
      );
    } catch (e) {
      print('Error saving email: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Optionally, load saved email on initialization
    _loadsEmail();
  }


  var appvalidator = AppValidator();
  _loadsEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('email');
    print(savedEmail);
    if (savedEmail != null) {
      setState(() {
        _emailcontroller.text = savedEmail;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Pop until reaching the FirstScreen
        return false; // Return false to prevent default behavior
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFE7F2FE),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
          ),
        ),
        backgroundColor: const Color(0xFFE7F2FE),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formkey,
              child: Column(
                children: [
                  const SizedBox(height: 70.0),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/images/SAEC.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  const SizedBox(
                    width: 250,
                    child: Text('SAEC SpotBus',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 25,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 50.0),
                  TextFormField(
                      controller: _emailcontroller,
                      style: const TextStyle(color: Color.fromARGB(255, 46, 48, 146)),
                      cursorColor: Colors.indigo,
                      keyboardType: TextInputType.emailAddress,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: _buildInputdecoration('   Email', Icons.alternate_email_sharp),
                      validator: appvalidator.stuvalidateEmail),
                  const SizedBox(height: 16.0),
                  TextFormField(
                      controller: _passwordcontroller,
                      style: const TextStyle(color: Color.fromARGB(255, 46, 48, 146)),
                      cursorColor: Colors.indigo,
                      keyboardType: TextInputType.visiblePassword,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: _buildInputdecoration('   Password', Icons.password),
                      validator: appvalidator.validatepassword),
                  const SizedBox(height: 40.0),
                  SizedBox(
                    height: 50.0,
                    width: 250,
                    child: ElevatedButton(
                      onPressed: () {
                        isLoader ? print("Loading") : _submitform();
                      },
                      child: isLoader
                          ? const Center(child: CircularProgressIndicator())
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.done_all), // Icon widget
                          SizedBox(width: 15),
                          Text(
                            'Sign in',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          // Add some space between the icon and the text
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 46, 48, 146), // Background color
                        foregroundColor: Colors.white, // Text color
                        elevation: 4, // Elevation (shadow)
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(80.0), // Border radius
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30.0),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => usersignup()));
                    },
                    child: Text(
                      'Doesn\'t have an account?',
                      style: TextStyle(
                        color: Color.fromARGB(255, 46, 48, 146),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      // Send a password reset email
                      if (_emailcontroller.text.isNotEmpty) {
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailcontroller.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password reset email sent. Check your inbox.')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to send password reset email: $e')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter your email to reset your password.')),
                        );
                      }
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color.fromARGB(255, 46, 48, 146),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputdecoration(String label, IconData suffixIcon) {
    return InputDecoration(
        fillColor: Colors.white,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(80.0),
          borderSide: const BorderSide(color: Color.fromARGB(255, 46, 48, 146)),
        ),
        labelStyle: const TextStyle(color: Colors.black),
        labelText: label,
        suffixIcon: Icon(suffixIcon),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(80.0),
          borderSide: const BorderSide(color: Color.fromARGB(255, 46, 48, 146)),
        ));
  }
}
