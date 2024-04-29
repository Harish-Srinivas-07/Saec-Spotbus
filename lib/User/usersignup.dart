import 'package:collegebustracking/User/userlogin.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import '../services/auth_services.dart';
import '../utills/appvalidator.dart';

//create new acc student

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    home: usersignup(),
  ));
}
class usersignup extends StatefulWidget {
  usersignup({super.key});

  @override
  State<usersignup> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<usersignup> {

  final GlobalKey<FormState> _formkey=GlobalKey<FormState>();
  final _namecontroller=TextEditingController();
  final _emailcontroller=TextEditingController();
  final locacontroller=TextEditingController();
  final _passwordcontroller=TextEditingController();
  var isLoader=false;
  var authservice=AuthService();
  Future<void> _submitform() async {
    var email = _emailcontroller.text.trim();

    if (!email.endsWith('@saec.ac.in')) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Invalid Email'),
            content: Text('Please enter a valid SAEC email ending with "@saec.ac.in"'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return; // Exit the method without submitting the form
    }
    if (!_formkey.currentState!.validate()) {
      // Form is not valid, return without submitting
      return;
    }

    setState(() {
      isLoader = true;
    });

    var data = {
      "email": _emailcontroller.text,
      "name": _namecontroller.text,
      "password": _passwordcontroller.text,
      "location": locacontroller.text,
    };

    await authservice.createuseruser(data, context);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => userlogin()));

    setState(() {
      isLoader = false;
    });
  }


  var appvalidator=AppValidator();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7F2FE),

      body: Padding(padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
              child: Form(
                  key: _formkey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 90.0),
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
                      const SizedBox(width: 250,
                        child:Text('Join SpotBus',textAlign: TextAlign.center,
                            style:TextStyle(color: Colors.black,fontSize: 25,fontWeight: FontWeight.w800)
                        )
                        ,),

                      const SizedBox(height: 16.0),
                      const SizedBox(height: 20),

                      TextFormField(
                          controller: _emailcontroller,
                          style: const TextStyle(color: Color.fromARGB(255, 46, 48, 146)),
                          cursorColor: Colors.blue,
                          keyboardType: TextInputType.emailAddress,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: _buildInputdecoration('   Email', Icons.alternate_email_rounded),

                          validator: appvalidator.stuvalidateEmail


                      ),

                      const SizedBox(height: 16.0),

                      TextFormField(
                          controller: _namecontroller,
                          style: const TextStyle(color: Color.fromARGB(255, 46, 48, 146)),
                          cursorColor: Colors.blue,
                          keyboardType: TextInputType.text,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: _buildInputdecoration('   Name', Icons.three_p),

                          validator: appvalidator.stuvalidateName


                      ),

                      const SizedBox(height: 16.0),

                      TextFormField(
                          controller: _passwordcontroller,

                          style: const TextStyle(color: Color.fromARGB(255, 46, 48, 146)),
                          cursorColor: Colors.blue,
                          keyboardType: TextInputType.visiblePassword,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: _buildInputdecoration('   Password', Icons.password),

                          validator: appvalidator.validatepassword


                      ),

                      const SizedBox(height: 16.0),

                      TextFormField(
                          controller: locacontroller,

                          style: const TextStyle(color:  Color.fromARGB(255, 46, 48, 146)),
                          cursorColor: Colors.blue,
                          keyboardType: TextInputType.visiblePassword,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: _buildInputdecoration('   Location', Icons.near_me_rounded),

                          validator: appvalidator.validatepassword

                      ),

                      const SizedBox(height: 40.0),

                      SizedBox(height: 50.0,
                        width: 250,

                        child: ElevatedButton(
                          onPressed: () {
                            isLoader ? print("Loading") : _submitform();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 46, 48, 146), // Background color
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
                                'Sign Up',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),


                      ),

                      const SizedBox(height: 30.0),

                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) =>  userlogin(),));

                        },
                        child:const Text('Already have an account ?',
                          style: TextStyle(color: Color.fromARGB(255, 46, 48, 146),fontSize: 18 , fontWeight: FontWeight.bold)),

                      ),

                    ],

                  )
              ))

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
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(80.0),
      ),
    );
  }


  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
}