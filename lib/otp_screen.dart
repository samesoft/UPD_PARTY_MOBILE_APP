import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:http/http.dart' as http;
import 'package:upd_party/login_page.dart';
import 'dart:convert';
import 'package:upd_party/verification_screen.dart'; 
import 'constants/constants.dart'; 
import 'dart:io';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController phoneNumberController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String selectedCountryCode = "+252"; // Default country code
  bool isLoading = false;
  bool hasError = false;

  Future<void> handleContinue() async {
  setState(() {
    hasError = false; // Reset error state
  });

  if (!_formKey.currentState!.validate()) {
    return; // Stop if validation fails
  }

  final fullPhoneNumber = "$selectedCountryCode${phoneNumberController.text.trim()}";

  try {
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('${devBaseUrl}api/members/requestOtp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phoneNumber': fullPhoneNumber}),
    );

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationScreen(phoneNumber: fullPhoneNumber),
        ),
      );
    }
    else if (response.statusCode == 400) {
      // Handle "already registered" error
      final errorResponse = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorResponse['error'] ?? 'You\'re already registered, please login to continue'),
          backgroundColor: Colors.red,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      // Redirect to the parent route (e.g., login screen)
      Navigator.pop(context); // Adjust this based on your navigation stack
    }
    else {
  // Handle valid HTTP responses with errors
  final errorResponse = jsonDecode(response.body);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(errorResponse['error'] ?? 'Failed to request OTP'),
      backgroundColor: Colors.red,
    ),
  );

  // Navigate to the LoginPage after showing the SnackBar
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => const LoginPage(),
    ),
  );
}

  } on FormatException {
    // Handle unexpected response format (e.g., backend not running or invalid URL)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Unexpected response from the server. Please try again later.")),
    );
  } on SocketException {
    // Handle network-related errors
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Network error. Please check your internet connection.")),
    );
  } catch (e) {
    // Handle other unexpected errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("An unexpected error occurred: ${e.toString()}")),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Enter Phone Number",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    "Verify your phone number",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[900]
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Enter your phone number to receive an OTP code for verification.",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Country Code Picker
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: CountryCodePicker(
                          onChanged: (country) {
                            setState(() {
                              selectedCountryCode = country.dialCode!;
                            });
                          },
                          initialSelection: 'SO',
                          countryFilter: const ['SO'],
                          showCountryOnly: false,
                          showOnlyCountryWhenClosed: false,
                          alignLeft: false,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          textStyle: const TextStyle(fontSize: 16),
                          flagWidth: 30,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Phone Number Input
                      Expanded(
                        child: TextFormField(
                          controller: phoneNumberController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone number',
                            hintText: 'e.g., 612345678',
                            errorText: hasError ? "Invalid phone number" : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              setState(() {
                                hasError = true;
                              });
                              return "Phone number is required";
                            }
                            if (value.length < 9 || value.length > 15) {
                              setState(() {
                                hasError = true;
                              });
                              return "Enter a valid phone number";
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        disabledBackgroundColor: Colors.blue[900],
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              "Continue",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

