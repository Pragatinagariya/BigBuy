import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({Key? key}) : super(key: key);

  final String adminName = "Pankti";
  final String adminPhone = "+91 7698903026";
  final String adminEmail = "prajapatipankti1575@gmail.com";

  // ✅ Function to Call Admin
  void _makePhoneCall() async {
    final Uri uri = Uri.parse("tel:$adminPhone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print("Could not launch $uri");
    }
  }

  // ✅ Function to Send SMS to Admin
  void _sendSMS() async {
    final Uri uri = Uri.parse("sms:$adminPhone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print("Could not launch $uri");
    }
  }

  // ✅ Function to Send Email to Admin
  void _sendEmail() async {
    final Uri uri = Uri.parse("mailto:$adminEmail?subject=Support Request&body=Hello Admin,");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print("Could not launch $uri");
    }
  }

  // ✅ Function to Open WhatsApp Chat
  void _openWhatsApp() async {
    final String phoneNumber = "7698903026"; // Without +91
    final Uri uri = Uri.parse("https://wa.me/$phoneNumber?text=Hello%20Admin");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print("Could not launch $uri");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Us"),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✅ Admin Info Card
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // ✅ Ensures everything is centered
                  children: [
                    const Text(
                      "Contact Admin",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
                      textAlign: TextAlign.center, // ✅ Centered Text
                    ),
                    const SizedBox(height: 10),
                    Text("Name: $adminName",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center), // ✅ Centered Name
                    const SizedBox(height: 5),
                    Text("Phone: $adminPhone",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center), // ✅ Centered Phone
                    const SizedBox(height: 5),

                    // ✅ Center-align the Email Section properly
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center, // ✅ Ensures email section is centered
                      children: [
                        const Text(
                          "Email:",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(adminEmail,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center), // ✅ Centered Email ID
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ✅ Buttons Row 1: Call & SMS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildContactButton("Call", Icons.call, Colors.green, _makePhoneCall),
                _buildContactButton("SMS", Icons.message, Colors.blue, _sendSMS),
              ],
            ),
            const SizedBox(height: 15), // Add spacing between rows

            // ✅ Buttons Row 2: Email & WhatsApp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildContactButton("Email", Icons.email, Colors.blue, _sendEmail),
                _buildContactButton("WhatsApp", FontAwesomeIcons.whatsapp, Colors.green, _openWhatsApp, isFaIcon: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Custom Button Widget (For Better UI)
  Widget _buildContactButton(String text, IconData icon, Color color, VoidCallback onTap, {bool isFaIcon = false}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: isFaIcon
          ? FaIcon(icon, color: Colors.white) // For FontAwesome Icons
          : Icon(icon, color: Colors.white), // For Regular Icons
      label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(160, 55), // ✅ Slightly bigger buttons
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // ✅ Rounded edges
        elevation: 3, // ✅ Adds slight shadow
      ),
    );
  }
}
