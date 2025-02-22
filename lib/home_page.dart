import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upd_party/create_event_page.dart';
import 'package:upd_party/donation_screen.dart';
import 'package:upd_party/event_screen.dart';
import 'package:upd_party/registered_events_screen.dart';
import 'package:upd_party/profile_page.dart'; // Import the profile page
import 'constants/constants.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'scanner_page.dart';
import 'dart:convert';
import 'admin_event_management_screen.dart';

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

  String login = '';
  String phone = '';
  String? memberId;
  int? districtId;
  int? stateId;
  int? roleId;
  String? roleIdString;
  String? fullProfilePhotoUrl;

  Future<void> _getUser() async {
    final prefs = await SharedPreferences.getInstance();
    memberId = prefs.getString('member_id');
    roleIdString = prefs.getString('role_id');
    if (roleIdString != null) {
      roleId = int.tryParse(roleIdString!);
    }
    // print("memberId from homepage: $memberId");
    // print("role id from homepage: $roleId");

    if (memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member not found. Please sign up.')),
      );
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('${devBaseUrl}api/members/$memberId'),
      );
      // print("Response status: ${response.statusCode}");
      // print("Response body: ${response.body}");
      if (response.statusCode == 200) {
        final memberData = jsonDecode(response.body);
        // print("memberdata: $memberData");
        // print("ProfilePhotoUrl: ${memberData['data']['profile_photo_url']}");

        if (memberData != null) {
          setState(() {
            login = memberData['data']['first_name'] ?? '';
            phone = memberData['data']['mobile'] ?? '';
            districtId = memberData['data']['district_id'];
            stateId = memberData['data']['state_id'];
            String profilePhotoUrl = memberData['data']['profile_photo_url'] ??
                ''; // Handle null value
            String backendBaseUrl = "https://upd-party-backend.samesoft.app";
            fullProfilePhotoUrl = profilePhotoUrl.isNotEmpty
                ? "$backendBaseUrl$profilePhotoUrl"
                : null;
          });
          // print("fullProfilePhotoUrl: $fullProfilePhotoUrl");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No member data found.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to fetch member data: ${response.statusCode}')),
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
        SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}')),
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
          'Welcome $login!',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[900],
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
                  ) ??
                  false;

              if (shouldLogout) {
                await _logout();
              }
            },
            child: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: fullProfilePhotoUrl != null
                  ? NetworkImage(fullProfilePhotoUrl!)
                  : null,
              child: fullProfilePhotoUrl == null
                  ? Text(
                      login.isNotEmpty ? login[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
        child: Column(
          children: [
            // ** Motivational Message Section **
            Container(
              width: size.width,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
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
              child: const Text(
                "Together, we build a stronger Somalia!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // ** Dashboard Buttons **
            Expanded(
              child:
                  roleId == 1 ? _buildAdminDashboard() : _buildUserDashboard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminDashboard() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 13,
      children: [
        CardButton(
          title: "Scan & Verify Ticket",
          icon: Icons.qr_code_scanner,
          gradient: const LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScannerPage(),
              ),
            );
          },
        ),
        CardButton(
          title: "Create Event",
          icon: Icons.event,
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onPressed: () {
            if (memberId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CreateEventPage(memberId: int.parse(memberId!)),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Member ID not found. Please log in again.')),
              );
            }
          },
        ),
        CardButton(
        title: "Manage Events",
        icon: Icons.manage_history,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA726), Color(0xFFFB8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminEventManagementScreen(),
            ),
          );
        },
      ),
        CardButton(
          title: "My Profile",
          icon: Icons.person,
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onPressed: () {
            if (memberId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(),
                ),
              ).then((_) {
                _getUser(); // Refresh profile data after returning
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Member ID not found. Please log in again.')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildUserDashboard() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 13,
      children: [
        CardButton(
          title: "Support the Cause",
          icon: Icons.volunteer_activism,
          gradient: const LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onPressed: () {
            if (memberId != null && phone.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DonationScreen(memberId: memberId!, phone: phone),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Member ID not found. Please log in again.')),
              );
            }
          },
        ),
        CardButton(
          title: "Upcoming Events",
          icon: Icons.event,
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onPressed: () {
            if (stateId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EventScreen(stateId: stateId!, memberId: memberId!),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('District ID not found. Please log in again.')),
              );
            }
          },
        ),
        CardButton(
          title: "Registered Events",
          icon: Icons.event_available,
          gradient: const LinearGradient(
            colors: [Color(0xFFFFA726), Color(0xFFFB8C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onPressed: () {
            if (memberId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RegisteredEventsScreen(memberId: memberId!),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Member ID not found. Please log in again.')),
              );
            }
          },
        ),
        CardButton(
          title: "My Profile",
          icon: Icons.person,
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onPressed: () {
            if (memberId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(),
                ),
              ).then((_) {
                _getUser(); // Refresh profile data after returning
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Member ID not found. Please log in again.')),
              );
            }
          },
        ),
      ],
    );
  }
}

class CardButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onPressed;

  const CardButton({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
