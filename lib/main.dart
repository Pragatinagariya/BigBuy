import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'registration.dart'; // Import Registration Page
import 'login.dart'; // Import Login Page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(), // Start with Splash Screen
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _appVersion = "Loading..."; // Placeholder for app version

  @override
  void initState() {
    super.initState();
    _getAppVersion();
    _navigateToNextScreen();
  }

  // Fetch the app version
  Future<void> _getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
    //  _appVersion = "v${packageInfo.version} (${packageInfo.buildNumber})";
    });
  }

  // ✅ Navigate to Login Page after Splash Screen
  void _navigateToNextScreen() async {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()), // Go to Login Page
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/Logo1.jpg', // Add image to assets folder
              width: 600,
              height: 800,
            ),
            const SizedBox(height: 20),
            Text(
              _appVersion, // Display app version
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
