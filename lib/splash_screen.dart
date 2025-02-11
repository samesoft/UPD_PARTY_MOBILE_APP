import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // For delay

import 'home_page.dart';
import 'login_page.dart';


// Global variables for latitude and longitude

String? roleId;


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
     setRolePermission();
    _initializeApp(); // Initialize the app
  }


void setRolePermission() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    roleId = prefs.getString('roleId') ?? '';
  }

  Future<void> _initializeApp() async {
    await _checkLoginStatus(); // Check login status after splash animation
  }

  
  Future<void> _checkLoginStatus() async {
    // Simulate a splash delay for a polished experience
    await Future.delayed(const Duration(seconds: 3));

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // Navigate based on login status
    if (isLoggedIn) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return const HomePage();
      }));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return const LoginPage();
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/logo.jpg', width: 150, height: 150),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              "Loading...",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
