import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_services.dart';
import '../services/auth_login.dart';
import '../utills/appvalidator.dart';
import 'ambsignup.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MaterialApp(
    home: LoginView(),
  ));
}

class LoginView extends StatefulWidget {
  LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passcodeController = TextEditingController();
  var isLoader = false;
  var authService = AuthService();
  var authlogin = AuthLogin();
  var appValidator = AppValidator();
  int wrongAttempts = 0; // Track the number of wrong attempts
  bool showPopup = false; // Control whether to show the popup
  late Timer _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadEmail();

  }


  Future<void> _submitForm() async {
    setState(() {
      isLoader = true;
    });

    // Initialize Remote Config with a default value
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(minutes: 1),
    ));
    await remoteConfig.fetchAndActivate();

    var passcode = _passcodeController.text;

    // Retrieve the passcode value from Remote Config
    final FirebaseRemoteConfig iremoteConfig = FirebaseRemoteConfig.instance;
    final defaultPasscode = iremoteConfig.getString('firepasscode');
    remoteConfig.getString('firepasscode');

    // Check if the passcode is correct
    if (passcode != defaultPasscode) {
      setState(() {
        isLoader = false;
        wrongAttempts++;
      });

      if (wrongAttempts == 3) {
        showPopup = true;
        _startCountdownTimer();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect passcode. Please try again.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // If passcode is correct, proceed with login
    var data = {
      "email": _emailController.text,
      "password": _passwordController.text,
    };

    // Add error handling in case of any exceptions during shared preferences operations
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('demail', _emailController.text);
      await prefs.setString('password', _passwordController.text);
    } catch (e) {
      print('Error saving data to SharedPreferences: $e');
    }

    await authlogin.login(data, context);

    setState(() {
      isLoader = false;
    });


  }
  _loadEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Ensure that you're correctly handling the case when the saved email is null
    String? savedEmail = prefs.getString('demail');
    String? savedPass = prefs.getString('password');
    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPass ?? ''; // Handle the case when savedPass is null
      });
    }
  }


  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    const oneSec = Duration(seconds: 1);
    _countdownTimer = Timer.periodic(
      oneSec,
          (Timer timer) {
        if (showPopup) {
          setState(() {
            if (wrongAttempts < 3 && showPopup) {
              showPopup = false;
              timer.cancel();
            }
          });
        }
      },
    );
  }

  void _handleCountdownFinished() {
    setState(() {
      showPopup = false;
      wrongAttempts = 0; // Reset attempts counter
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFD7F7DE),
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
        backgroundColor: const Color(0xFFD7F7DE),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10.0),
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
                      const Text(
                        'Driver Login',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: Colors.black,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Color.fromARGB(255, 1, 121, 6)),
                        cursorColor: Colors.green,
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: _buildInputDecoration('   Email', Icons.alternate_email_rounded),
                        validator: appValidator.validateEmail,
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(color: Color.fromARGB(255, 1, 121, 6)),
                        cursorColor: Colors.green,
                        keyboardType: TextInputType.visiblePassword,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: _buildInputDecoration('   Password', Icons.password),
                        validator: appValidator.validatepassword,
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _passcodeController,
                        style: const TextStyle(color: Color.fromARGB(255, 1, 121, 6)),
                        cursorColor: Colors.green,
                        keyboardType: TextInputType.visiblePassword,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: _buildInputDecoration('   Passcode', Icons.sync_lock),
                        validator: appValidator.validatepassword,
                      ),
                      const SizedBox(height: 25.0),
                      SizedBox(
                        height: 50.0,
                        width: 250,
                        child: ElevatedButton(
                          onPressed: () {
                            isLoader ? print("Loading") : _submitForm();
                          },
                          child: isLoader
                              ? const Center(child: CircularProgressIndicator())
                              : const Row(
                            mainAxisSize: MainAxisSize.min, // Ensure the Row takes minimum space
                            children: [
                              Icon(Icons.key), // Add the icon
                              SizedBox(width: 15), // Add some space between the icon and the text
                              Text(
                                'Sign in',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 1, 121, 6),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(80.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30.0),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignUpView(),
                            ),
                          );
                        },
                        child: const Text(
                          'Doesn\'t have an account ?',
                          style: TextStyle(
                            color: Color.fromARGB(255, 1, 121, 6),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () async {
                          // Send a password reset email
                          if (_emailController.text.isNotEmpty) {
                            try {
                              await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text);
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
                            color: Color.fromARGB(255, 1, 121, 6),
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
            if (showPopup) // Show popup if showPopup is true
              Center(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.8), // Adjust opacity here
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Too many wrong attempts. Please wait ...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25.0,
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        CountdownWidget(
                          onCountdownFinish: _handleCountdownFinished,
                        ), // Display countdown widget
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData suffixIcon) {
    return InputDecoration(
      fillColor: Colors.white,
      filled: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(80.0),
        borderSide: const BorderSide(color: Color(0xFF40E80F)),
      ),
      labelStyle: const TextStyle(color: Colors.black),
      labelText: label,
      suffixIcon: Icon(suffixIcon),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(80.0),
        borderSide: const BorderSide(color: Colors.green),
      ),
    );
  }
}
// Countdown widget for displaying the countdown
class CountdownWidget extends StatefulWidget {
  final VoidCallback onCountdownFinish;

  const CountdownWidget({required this.onCountdownFinish});

  @override
  _CountdownWidgetState createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  int countdown = 30;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        countdown--;
      });
      if (countdown == 0) {
        timer.cancel();
        widget.onCountdownFinish(); // Call the callback function
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '$countdown',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 70.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
