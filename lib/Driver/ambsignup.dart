import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import '../services/auth_services.dart';
import '../utills/appvalidator.dart';
import 'amblogin.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MaterialApp(
    home: SignUpView(),

  ));
}

class SignUpView extends StatefulWidget {
  SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {

  final GlobalKey<FormState> _formkey=GlobalKey<FormState>();
  final hospicontroller=TextEditingController();
  final _emailcontroller=TextEditingController();
  final _phonecontroller=TextEditingController();
  final _passwordcontroller=TextEditingController();
  final ambnumber=TextEditingController();
  final addresscontroller=TextEditingController();
  final _passcodecontroller = TextEditingController();
  var isLoader=false;

  var authservice=AuthService();
  Future<void> _submitform() async {

    // Initialize Remote Config with a default value
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await remoteConfig.fetchAndActivate();

    // Retrieve the passcode value from Remote Config
    final FirebaseRemoteConfig iremoteConfig = FirebaseRemoteConfig.instance;
    final defaultPasscode = iremoteConfig.getString('firepasscode');
    remoteConfig.getString('firepasscode');
    print('The code is :$defaultPasscode');


    // Check if the passcode matches
    if (_passcodecontroller.text != defaultPasscode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid passcode. Please enter the correct passcode.'),
          duration: Duration(seconds: 2),
        ),
      );
      return; // Exit the method without creating the user
    }

    setState(() {
      isLoader = true;
    });

    var data = {
      "dname": hospicontroller.text,
      "email": _emailcontroller.text,
      "password": _passwordcontroller.text,
      "mobile": _phonecontroller.text,
      "address": addresscontroller.text,
      "did": ambnumber.text,
    };

    await authservice.createuser(data, context);



    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginView()),
    );

    setState(() {
      isLoader = false;
    });
  }


  var appvalidator=AppValidator();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7F7DE),//green light

      body: Padding(padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
              child: Form(
                  key: _formkey,
                  child: Column(
                    children: [
                      const SizedBox(height: 70.0),
                      const SizedBox(width: 250,
                          child:Text('Join SpotBus',textAlign: TextAlign.center,
                              style:TextStyle(color: Colors.black,fontSize: 25,fontWeight: FontWeight.bold)
                          )
                      ),

                      const SizedBox(height: 30.0,),
                      TextFormField(
                        controller: hospicontroller,
                        style: const TextStyle(color: Colors.black),cursorColor: Colors.green,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: _buildInputdecoration('   Driver name', Icons.admin_panel_settings),

                      ),
                      const SizedBox(height: 16.0,),
                      TextFormField(
                        controller: ambnumber,
                        style: const TextStyle(color: Colors.black),cursorColor: Colors.green,

                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: _buildInputdecoration('   Bus Number', Icons.format_list_numbered),
                      ),
                      const SizedBox(height: 16.0,),
                      TextFormField(
                        controller: addresscontroller,
                        style: const TextStyle(color: Colors.black),cursorColor: Colors.green,

                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: _buildInputdecoration('   Destination', Icons.near_me),

                      ),
                      const SizedBox(height: 16.0,),

                      TextFormField(
                          controller: _emailcontroller,
                          style: const TextStyle(color: Colors.black),cursorColor: Colors.green,
                          keyboardType: TextInputType.emailAddress,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: _buildInputdecoration('   Email', Icons.alternate_email),

                          validator: appvalidator.validateEmail

                      ),


                      const SizedBox(height: 16.0,),

                      TextFormField(
                          controller: _phonecontroller,
                          style: const TextStyle(color: Colors.black),cursorColor: Colors.green,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: _buildInputdecoration('   Mobile number', Icons.add_ic_call),
                          validator: appvalidator.validatemobile),

                      const SizedBox(height: 16.0,),

                      TextFormField(
                          controller: _passwordcontroller,

                          style: const TextStyle(color: Colors.black),cursorColor: Colors.green,
                          keyboardType: TextInputType.visiblePassword,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: _buildInputdecoration('   Password', Icons.password),

                          validator: appvalidator.validatepassword
                      ),

                      const SizedBox(height: 16.0,),

                      TextFormField(
                          controller: _passcodecontroller,

                          style: const TextStyle(color: Colors.black),cursorColor: Colors.green,
                          keyboardType: TextInputType.visiblePassword,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: _buildInputdecoration('   Passcode', Icons.sync_lock),

                          validator: appvalidator.validatepassword
                      ),

                      const SizedBox(height: 20.0),
                      SizedBox(height: 50.0,
                        width: 250,

                        child: ElevatedButton(
                          onPressed: () {
                            isLoader ? print("Loading") : _submitform();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 1, 121, 6), // Background color
                            foregroundColor: Colors.white, // Text color
                            elevation: 4, // Elevation (shadow)
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(80.0), // Border radius
                            ),
                          ),
                          child: isLoader
                              ? Center(child: CircularProgressIndicator())
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.done_all), // Icon widget
                              SizedBox(width: 8), // Space between icon and text
                              Text(
                                'Sign up',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),


                      ),

                      const SizedBox(height: 30.0,),

                      TextButton(

                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) =>  LoginView(),));
                        },
                        child:const Text('Already have an account ?',
                          style: TextStyle(color: Color.fromARGB(255, 1 ,121, 6),
                              fontWeight: FontWeight.bold,
                              fontSize: 18),),

                      ),
                    ],

                  )
              ))

      ),

    );
  }

  InputDecoration _buildInputdecoration(String label,IconData suffixIcon ) {
    return InputDecoration(
        fillColor: Colors.white,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(80.0),
          borderSide: const BorderSide(color: Color(0xFF40E80F)),//sign in acc
        ),

        labelStyle: const TextStyle(color: Colors.black),
        labelText:label,
        suffixIcon:Icon(suffixIcon),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(80.0),
          borderSide: const BorderSide(
              color: Colors.green),));

  }

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
}