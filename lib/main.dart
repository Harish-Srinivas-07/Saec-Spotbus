import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:collegebustracking/Driver/dashboard.dart';
import 'package:collegebustracking/User/dashboard.dart';
import 'package:collegebustracking/utills/auth_gate.dart';
import 'package:collegebustracking/utills/auth_gate2.dart';




Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Fetch user data from Firebase
  DatabaseReference _database = FirebaseDatabase.instance.reference();
  String? userType;

  try {
    DataSnapshot dataSnapshot = (await _database.child('Driver').child(FirebaseAuth.instance.currentUser!.uid).once()).snapshot;

    if (dataSnapshot.value != null) {
      userType = 'Driver';
    }
  } catch (e) {
    print('Error fetching driver data: $e');
  }

  if (userType == null) {
    try {
      DataSnapshot dataSnapshot = (await _database.child('Student').child(FirebaseAuth.instance.currentUser!.uid).once()).snapshot;

      if (dataSnapshot.value != null ) {
        userType = 'Student';
      }
    } catch (e) {
      print('Error fetching student data: $e');
    }
  }

  // Check if email is verified
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null && !user.emailVerified) {
    userType == null;
    // If email is not verified, sign out the user
    await FirebaseAuth.instance.signOut();
    // If email is not verified, show a scaffold with the message
    return;
  }

  // Set the root widget based on user type and email verification
  Widget initialWidget;
  if (userType == 'Driver') {
    initialWidget = ambboard(); // If the user is a driver and email is verified, set AmbulanceDashboard as the initial widget
  } else if (userType == 'Student') {
    initialWidget = userboard(); // If the user is a student and email is verified, set UserDashboard as the initial widget
  } else {
    initialWidget = SplashScreen(); // If user type is unknown, email is not verified, or error occurred, show the SplashScreen
  }

  runApp(MyApp(initialWidget: initialWidget));
}

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          // Return false to block the back button
          return false;
        },
        child: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/schoolbuspng.gif', // Replace with your image path
              width: 200, // Adjust width as needed
              height: 200, // Adjust height as needed
            ),
            SizedBox(height: 20), // Adjust the spacing between image and text
            Text(
              'Loading under progress...', // Your text here
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    )
    );
  }
}


class MyApp extends StatelessWidget {
  final Widget initialWidget;

  MyApp({required this.initialWidget});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Montserrat',
      ),
      home: initialWidget, // Set the initial widget determined during app initialization
    );
  }
}

// SplashScreen, HomeScreen, FadeIn, StaggeredAnimationButtons, StaggeredButton remain the same


class SplashScreen extends StatelessWidget {
  Future<void> simulateAsyncOperation() async {
    await Future.delayed(Duration(seconds: 5));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          // Return false to block the back button
          return false;
        },
        child: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/bushome.png', // Replace with your image path
            fit: BoxFit.cover,
          ),
          // Splash screen overlay
          Container(
            color: Colors.black.withOpacity(0.7), // Adjust opacity as needed
          ),
          Center(
            child: FutureBuilder(
              future: simulateAsyncOperation(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return HomeScreen();
                } else {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 50.0),
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage('assets/images/saec_staff.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 30.0),
                        Text(
                          'Welcome to',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Montserrat', // Add this line
                            fontSize: 25.0,
                            color: Colors.orangeAccent,
                          ),
                        ),
                        Text(
                          'SAEC SpotBus',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat', // Add this line
                            fontSize: 25.0,
                            color: Colors.yellow,
                          ),
                        ),
                        SizedBox(height: 10.0),
                        Center(
                          child: Text(
                            'for the students, by the students',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 10.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 70.0),
                        CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    )
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          // Return false to block the back button
          return false;
        },
        child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/bushome.png',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withOpacity(0.7),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeIn(
                  child: Text(
                    '',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 40.0),
                StaggeredAnimationButtons(),
              ],
            ),
          ),
        ],
      ),
    )
    );
  }
}

class FadeIn extends StatefulWidget {
  final Widget child;

  FadeIn({required this.child});

  @override
  _FadeInState createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class StaggeredAnimationButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
      // Return false to block the back button
      return false;
    },
    child: Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage('assets/images/saec_staff.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 70.0),

        StaggeredButton(
          label: ' Driver',
          iconData: Icons.drive_eta_rounded,
          onPressed: () {
            // Handle button 2 action
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AuthGate2()),
            );
          },
        ),

        SizedBox(height: 20,),

        StaggeredButton(
          label: 'Staff',
          iconData: Icons.badge,
          onPressed: () {
            // Handle button 3 action
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AuthGate()),
            );
          },
        ),
      ],
    )
    );
  }
}

class StaggeredButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData iconData;

  StaggeredButton({
    required this.label,
    required this.onPressed,
    required this.iconData,
  });

  @override
  _StaggeredButtonState createState() => _StaggeredButtonState();
}

class _StaggeredButtonState extends State<StaggeredButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutBack,
      ),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25.0), // Adjust the padding as needed
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            primary: Colors.yellow[800],
            padding: EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(80.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.iconData,
                color: Colors.black,
                size: 30,
              ),
              SizedBox(width: 20), // Adjust the spacing between icon and label
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.black, // Set the text color
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
