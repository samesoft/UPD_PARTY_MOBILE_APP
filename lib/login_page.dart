import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upd_party/otp_for_passward_reset.dart';
import 'package:upd_party/otp_screen.dart';
import 'dart:convert';
import 'dart:io';
import 'home_page.dart';
import 'constants/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool notVisiblePassword = true;
  Icon passwordIcon = const Icon(Icons.visibility);
  bool isLoading = false;
  String selectedCountryCode = "+252"; // Default country code
  String appVersion = "Version 1.7";
  String? _deviceToken;

 void togglePasswordVisibility() {
    setState(() {
      notVisiblePassword = !notVisiblePassword;
      passwordIcon = notVisiblePassword
          ? const Icon(Icons.visibility)
          : const Icon(Icons.visibility_off);
    });
  }
  @override
  void initState() {
    super.initState();
    _getDeviceToken();
  }

  // Get device token from Firebase
  Future<void> _getDeviceToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      print("device token: $token");
      setState(() {
        _deviceToken = token;
      });
    } catch (e) {
      print("Failed to get device token: $e");
    }
  }

  Future<void> _saveLoginStatus(String memberId, String roleId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('member_id', memberId);
    await prefs.setString('role_id', roleId);
  }

  Future<void> login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('${devBaseUrl}api/members/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'mobile': phoneNumberController.text.trim(),
            'password_hash': passwordController.text.trim(),
            'device_token': _deviceToken, // Optional device token
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['message'] == 'Login successful') {
            String memberId = data['member_id'].toString();
            String roleId = data['role_id'].toString();
            await _saveLoginStatus(memberId, roleId);

            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) {
              return const HomePage();
            }));
          } else {
            _showSnackBar(data['message'] ?? 'Login failed');
          }
        } else {
          _showSnackBar('Invalid login credentials');
        }
      } on SocketException {
        _showSnackBar('No internet connection. Please check your network.');
      } on TimeoutException {
        _showSnackBar('Request timed out. Please try again later.');
      } on FormatException {
        _showSnackBar('Invalid response format. Please try again later.');
      } catch (e) {
        _showSnackBar('An unexpected error occurred: ${e.toString()}');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Image.asset('assets/logo.jpg'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CountryCodePicker(
                          onChanged: (country) {
                            setState(() {
                              selectedCountryCode = country.dialCode!;
                            });
                          },
                          initialSelection: 'SO',
                          countryFilter: ['SO'],
                          showOnlyCountryWhenClosed: false,
                          alignLeft: false,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: phoneNumberController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone number',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Phone number is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: passwordController,
                      obscureText: notVisiblePassword,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        icon: const Icon(Icons.lock_outline, color: Colors.grey),
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: passwordIcon,
                          onPressed: togglePasswordVisibility,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const OtpScreenForReset()),
                          );
                        },
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        disabledBackgroundColor: Colors.blue[900],
                        minimumSize: const Size.fromHeight(45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            )
                          : const Text(
                              "Sign in",
                              style: TextStyle(fontSize: 15, color: Colors.white),
                            ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const OtpScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.black87),
                        minimumSize: const Size.fromHeight(45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Text(
                          appVersion,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}