import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart'; // Import Login Page

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    final String apiUrl = "https://spk.amisys.in/android/php/v0/registration.php";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "full_name": _fullNameController.text,
          "username": _usernameController.text,
          "password": _passwordController.text,
          "phone": _phoneController.text,
        },
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "success") {
        print("✅ Registration Successful!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registration Successful! Now you can log in."),
            backgroundColor: Colors.green,
          ),
        );

        // ✅ Save Registration Status
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('isRegistered', true);

        // ✅ Navigate to Login Page
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${data["message"]}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong! Check your connection."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // ✅ Navigate to Login Page on Back Press
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)],
                        ),
                        child: Column(
                          children: [
                            Text("Registration", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                            SizedBox(height: 20),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _fullNameController,
                                    decoration: InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                                    validator: (value) => value!.isEmpty ? "Please enter your full name" : null,
                                  ),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: InputDecoration(labelText: "Username", border: OutlineInputBorder()),
                                    validator: (value) => value!.isEmpty ? "Please enter a username" : null,
                                  ),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                                    obscureText: true,
                                    validator: (value) => value!.isEmpty || value.length < 6 ? "Password must be at least 6 characters" : null,
                                  ),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    decoration: InputDecoration(labelText: "Confirm Password", border: OutlineInputBorder()),
                                    obscureText: true,
                                    validator: (value) => value != _passwordController.text ? "Passwords do not match" : null,
                                  ),
                                  SizedBox(height: 12),
                                  TextFormField(
                                    controller: _phoneController,
                                    decoration: InputDecoration(labelText: "Phone Number", border: OutlineInputBorder()),
                                    keyboardType: TextInputType.phone,
                                    validator: (value) => value!.isEmpty || !RegExp(r'^[0-9]{10}$').hasMatch(value)
                                        ? "Enter a valid 10-digit phone number"
                                        : null,
                                  ),
                                  SizedBox(height: 20),
                                  SizedBox(
                                    width: 150, // Button width
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange, // Button color
                                        padding: EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      onPressed: registerUser,
                                      child: Text("Register", style: TextStyle(fontSize: 18, color: Colors.white)),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  // ✅ Navigate to Login Page
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => LoginPage()),
                                      );
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(fontSize: 16),
                                        children: [
                                          TextSpan(
                                            text: "Already have an account? ",
                                            style: TextStyle(color: Colors.black, fontSize: 18),
                                          ),
                                          TextSpan(
                                            text: "Log in",
                                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
}
