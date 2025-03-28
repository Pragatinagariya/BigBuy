import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'reset_password.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isSubmitting = false;
  String _otp = ""; // Store OTP temporarily

  final String apiUrl = "https://spk.amisys.in/android/php/v0/forgot_password.php";

  // ✅ Function to Send OTP
  Future<void> sendOtp({bool isResend = false}) async {
    if (_usernameController.text.isEmpty || _mobileController.text.isEmpty) {
      showSnackbar("Username and Mobile Number are required!", Colors.red);
      return;
    }

    if (_mobileController.text.length != 10) {
      showSnackbar("Mobile number must be 10 digits!", Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'action': 'send_otp',
          'username': _usernameController.text.trim(),
          'mobile': _mobileController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      setState(() => _isSubmitting = false);

      if (data["status"] == "success") {
        setState(() {
          _isOtpSent = true;
          _otp = data["otp"] ?? ""; // Store OTP (for debugging)
        });
        showSnackbar("OTP sent successfully!", Colors.green);
      } else {
        showSnackbar(data["message"], Colors.red);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      showSnackbar("Failed to send OTP. Please try again.", Colors.red);
    }
  }

  // ✅ Function to Verify OTP
  Future<void> verifyOtp() async {
    if (_otpController.text.isEmpty) {
      showSnackbar("Please enter OTP!", Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'action': 'validate_otp',
          'username': _usernameController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'otp': _otpController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      setState(() => _isSubmitting = false);

      if (data["status"] == "success") {
        showSnackbar("OTP Verified!", Colors.green);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(username: _usernameController.text.trim()),
          ),
        );
      } else {
        showSnackbar(data["message"], Colors.red);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      showSnackbar("OTP verification failed. Try again.", Colors.red);
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
      appBar: AppBar(title: const Text("Forgot Password"), backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Username", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mobileController,
              decoration: const InputDecoration(labelText: "Mobile Number", border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
              maxLength: 10, // Ensure mobile number is 10 digits
            ),
            const SizedBox(height: 12),

            // ✅ Send OTP Button (Hidden after OTP is sent)
            if (!_isOtpSent)
              ElevatedButton(
                onPressed: _isSubmitting ? null : () => sendOtp(),
                child: _isSubmitting ? const CircularProgressIndicator() : const Text("Send OTP"),
              ),

            // ✅ OTP Verification Section (Appears after OTP is sent)
            if (_isOtpSent) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: "Enter OTP", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),

              // ✅ Resend OTP Link
              TextButton(
                onPressed: _isSubmitting ? null : () => sendOtp(isResend: true),
                child: const Text("Resend OTP?", style: TextStyle(color: Colors.blue)),
              ),

              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isSubmitting ? null : verifyOtp,
                child: _isSubmitting ? const CircularProgressIndicator() : const Text("Submit OTP"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
