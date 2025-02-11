import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/constants.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width > 768;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  String? wardCode;
  String login = '';
  String phone = '';
  String? streetNames;

  Future<void> _getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please sign up.')),
      );
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('${devBaseUrl}api/users/$userId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final userData = data[0];
          setState(() {
            login = userData['login'];
            phone = userData['login_Name'];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user data found.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to fetch user data: ${response.statusCode}')),
        );
      }
    } on FormatException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unexpected response format from the server.')),
      );
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Network error. Please check your connection.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
    }
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return const LoginPage();
    }));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Good Morning, $login 👋',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () async {
              final bool shouldLogout = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              ) ?? false;

              if (shouldLogout) {
                await _logout();
              }
            },
            child: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                login.isNotEmpty ? login[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
        child: Column(
          children: [
            // ** Welcome Card **
            Container(
              width: size.width,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0052D4), Color(0xFF6FB1FC)], // Cool Gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 35, color: Colors.white),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome to PP Part",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Thank you for being a valuable member.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ** Empty Space for Future Content **
            Expanded(
              child: Center(
                child: Text(
                  "More features coming soon!",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
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