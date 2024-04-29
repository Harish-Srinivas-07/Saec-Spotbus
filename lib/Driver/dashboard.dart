import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'amblogin.dart';
import 'ambulancehome.dart';
import 'lateform.dart';
import 'live.dart';

void main() {
  runApp(const MaterialApp(
    home: ambboard(),
  ));

}

class ambboard extends StatefulWidget {
  final String? email;
  final String? hosname;
  final String? ambnumber;
  final String? ukey;
  final String? mobile;
  const ambboard({super.key,this.email,this.hosname,this.ambnumber,this.ukey,this.mobile});

  @override
  State<ambboard> createState() => _DashboardState();
}

class _DashboardState extends State<ambboard> {
  var islogoutloading=false;

  int _currentIndex = 0;
  List<Widget> getPages() {
    return [
      AmbulanceHome(ukey: widget.ukey,dname:widget.hosname,
          did:widget.ambnumber,mobile:widget.mobile
      ),
      const Live(updateValue: false),

    ];
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
                  'Are you sure you want to logout?\n',

                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[500], // Set background color to pale green
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
                          fontWeight: FontWeight.bold,color: Colors.white
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[500], // Set background color to pale red
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
                          fontWeight: FontWeight.bold,color: Colors.white
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
      context,
      MaterialPageRoute(builder: (context) => LoginView()),
    );

    setState(() {
      islogoutloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = getPages();
    return WillPopScope(
        onWillPop: () async {
      // Return false to block the back button
      return false;
    },
    child:Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD7F7DE),
        toolbarHeight: 80.0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Latee()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[800], // Background color
                foregroundColor: Colors.white, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(80.0),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    color: Colors.white, // Set the icon color to white
                  ),
                  SizedBox(width: 8), // Add some space between the icon and text
                  Text(
                    'Late Form',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold, // Make the text bold
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(), // Add a spacer to push the next button to the right
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              onPressed: () {
                logoutConfirmation(); // Show confirmation dialog for logout
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(80.0),
                ),
              ),
              icon: const Icon(Icons.exit_to_app),
              label: islogoutloading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(),
              )
                  : const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.bold, // Make the text bold
                ),
              ),
            ),
          ),
        ],
      ),

      body: _pages[_currentIndex],
        bottomNavigationBar: null,
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: _currentIndex,
      //   onTap: (index) {
      //     setState(() {
      //       _currentIndex = index;
      //     });
      //   },
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.home),
      //       label: 'Home',
      //     ),
      //
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.location_on_rounded),
      //       label: 'Send Location',
      //     ),
      //   ],
      //   selectedItemColor: Colors.green[800], // Customize the selected item color
      //   unselectedItemColor: Colors.black, // Customize the unselected item color
      //   // backgroundColor: Color(0xFFD7F7DE),
      //   backgroundColor: Colors.white,
      //   elevation: 10, // Add elevation to the bar
      //   selectedLabelStyle:
      //   const TextStyle(fontWeight: FontWeight.bold), // Customize the selected label style
      //   unselectedLabelStyle:
      //   const TextStyle(fontWeight: FontWeight.normal), // Customize the unselected label style
      // ),

    )
    );
  }

}