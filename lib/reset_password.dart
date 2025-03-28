import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String username;

  ResetPasswordScreen({required this.username});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final String apiUrl = "https://spk.amisys.in/android/php/v0/forgot_password.php";

  // ✅ Function to Reset Password
  Future<void> resetPassword() async {
    if (_passwordController.text.isEmpty) {
      showSnackbar("New Password cannot be empty!", Colors.red);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},  // ✅ Ensure JSON format
        body: jsonEncode({  // ✅ Encode as JSON
          'action': 'reset_password',
          'username': widget.username,
          'new_password': _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      print("Response Data: $data"); // ✅ Debugging response

      if (data["status"] == "success") {
        showSnackbar("Password updated successfully!", Colors.green);

        // ✅ Navigate to Login Page
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
      } else {
        showSnackbar(data["message"], Colors.red);
      }
    } catch (e) {
      showSnackbar("Error occurred. Please try again.", Colors.red);
    }
  }

  // ✅ Show Snackbar
  void showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reset Password"),backgroundColor: Colors.orange,),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              "Enter your new password below.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "New Password", border: OutlineInputBorder()),
              obscureText: true,
            ),
            SizedBox(height: 12),
            ElevatedButton(onPressed: resetPassword, child: Text("Update Password")),
          ],
        ),
      ),
    );
  }
}
