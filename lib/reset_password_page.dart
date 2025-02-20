import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'constants/constants.dart';
import 'login_page.dart';


class ResetPasswordPage extends StatefulWidget {
  final String phoneNumber;

  const ResetPasswordPage({super.key, required this.phoneNumber});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;

  Future<void> resetPassword() async {
    if (_formKey.currentState!.validate()) {
      if (newPasswordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Passwords do not match'),
              backgroundColor: Colors.red),
        );
        return;
      }

      setState(() {
        isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('${devBaseUrl}api/members/reset-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'mobile': widget.phoneNumber,
            'new_password': newPasswordController.text.trim(),
            'otp': otpController.text.trim(),
          }),
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(data['message']), backgroundColor: Colors.green),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(data['error'] ?? 'Failed to reset password'),
                backgroundColor: Colors.red),
          );
        }
      } on SocketException {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No internet connection'),
              backgroundColor: Colors.red),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('An error occurred: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // OTP Input Field
              TextFormField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'OTP',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'OTP is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // New Password Input Field
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'New password is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Confirm Password Input Field
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Confirm password is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              // Reset Password Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Reset Password',
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
    );
  }
}
