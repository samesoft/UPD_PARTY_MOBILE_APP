import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:country_code_picker/country_code_picker.dart';
import 'package:pp_party/otp_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Correct usage

  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool notVisiblePassword = true;
  Icon passwordIcon = const Icon(Icons.visibility);
  bool isLoading = false;
  String selectedCountryCode = "+252"; // Default country code
  String appVersion = "Version 1.0";

  // Toggle password visibility
  void togglePasswordVisibility() {
    setState(() {
      notVisiblePassword = !notVisiblePassword;
      passwordIcon = notVisiblePassword
          ? const Icon(Icons.visibility)
          : const Icon(Icons.visibility_off);
    });
  }

  // Save login status, userId, and roleId in SharedPreferences
  Future<void> _saveLoginStatus(String userId, String roleId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', userId);
    await prefs.setString('roleId', roleId);
    print("Saved userId: $userId");
    print("Saved RoleId: $roleId");
  }

  // HTTP Login Function
  Future<void> login() async {
  if (_formKey.currentState!.validate()) {
    setState(() {
      isLoading = true; // Start loading
    });

    try {
      final response = await http.post(
        Uri.parse('${devBaseUrl}api/users/login'), // Replace with your API URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login_Name': "$selectedCountryCode${phoneNumberController.text.trim()}",
          'password': passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['message'] == 'Login successful') {
          await _saveLoginStatus(
              data['userId'].toString(), data['roleId'].toString());
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
        isLoading = false; // Stop loading
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
              child: Form(
                key: _formKey, // Properly referencing the form key
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
                          // favorite: const ['+252', 'SO'],
                          showCountryOnly: false,
                          countryFilter: const ['SO'],
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
                      keyboardType:
                        TextInputType.number, // Restrict input to numbers
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly, 
                      LengthLimitingTextInputFormatter(4)
                    ],
                      decoration: InputDecoration(
                        icon:
                            const Icon(Icons.lock_outline, color: Colors.grey),
                        labelText: 'PIN',
                        suffixIcon: IconButton(
                          icon: passwordIcon,
                          onPressed: togglePasswordVisibility,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'PIn is required';
                        }
                        if (value.length != 4) {
                        return 'PIN must be exactly 4 digits';
                      }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed:
                          isLoading ? null : login, // Disable button if loading
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        disabledBackgroundColor: Colors.grey[600],
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
                              "Sign in", // Changed "Login" to "Sign in"
                              style: TextStyle(fontSize: 15, color: Colors.white),
                              
                            ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const OtpScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors
                            .white, // White background to match screenshot
                        side: const BorderSide(
                            color: Colors.black87), 
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // App Version Placement (Bottom of Login Screen)
            Padding(
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
          ],
        ),
      ),
    );
  }
}
