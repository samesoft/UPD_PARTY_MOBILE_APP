import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pp_party/login_page.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

import 'constants/constants.dart';

class RegistrationPage extends StatefulWidget {
  final String phone;
  const RegistrationPage({super.key, required this.phone});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final middleNameController = TextEditingController();

  bool notVisiblePassword = true;
  bool notVisibleConfirmPassword = true;
  bool isLoading = false;

  // Dropdown values
  String? selectedDistrict;
  String? selectedAgeGroup;
  String? selectedEduLevel;
  String? selectedPartyRole;
  String? selectedMembershipLevel;

  List<String> genders = ['Male', 'Female'];
  String? selectedGender;


  // Static dropdown options
  final List<Map<String, dynamic>> districts = [
    {'id': 1, 'name': 'District A'},
    {'id': 2, 'name': 'District B'},
    {'id': 3, 'name': 'District C'},
  ];

  final List<Map<String, dynamic>> ageGroups = [
    {'id': 1, 'name': '18-25'},
    {'id': 2, 'name': '26-35'},
    {'id': 3, 'name': '36-45'},
    {'id': 4, 'name': '46+'},
  ];

  final List<Map<String, dynamic>> eduLevels = [
    {'id': 1, 'name': 'High School'},
    {'id': 2, 'name': 'Bachelor\'s Degree'},
    {'id': 3, 'name': 'Master\'s Degree'},
    {'id': 4, 'name': 'PhD'},
  ];

  final List<Map<String, dynamic>> partyRoles = [
    {'id': 1, 'name': 'Member'},
    {'id': 2, 'name': 'Volunteer'},
    {'id': 3, 'name': 'Leader'},
  ];

  final List<Map<String, dynamic>> membershipLevels = [
    {'id': 1, 'name': 'Basic'},
    {'id': 2, 'name': 'Premium'},
    {'id': 3, 'name': 'VIP'},
  ];

  void togglePasswordVisibility() {
    setState(() {
      notVisiblePassword = !notVisiblePassword;
    });
  }

  void toggleConfirmPasswordVisibility() {
    setState(() {
      notVisibleConfirmPassword = !notVisibleConfirmPassword;
    });
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });
    print(widget.phone);

    try {
      final response = await http.post(
        Uri.parse('${devBaseUrl}api/members'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': firstNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'email': emailController.text.trim(),
          'password_hash': passwordController.text.trim(),
          'middle_name': middleNameController.text.trim(),
          'mobile': widget.phone.trim(),
          'district_id': selectedDistrict,
          'age_group_id': selectedAgeGroup,
          'edu_level_id': selectedEduLevel,
          'party_role_id': selectedPartyRole,
          'memb_level_id': selectedMembershipLevel,
          'gender': selectedGender,
        }),
      );

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw const FormatException("Unexpected response format");
      }

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful, login to continue'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FormatException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Unexpected response from the server. Please try again later."),
          backgroundColor: Colors.red,
        ),
      );
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Network error. Please check your internet connection."),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An unexpected error occurred: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
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
          'Register',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey[600],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Please fill in the form below to register.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      hintText: 'Enter your first name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'First name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      hintText: 'Enter your last name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Last name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: passwordController,
                    obscureText: notVisiblePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          notVisiblePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: togglePasswordVisibility,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: notVisibleConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter your password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(
                          notVisibleConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: toggleConfirmPasswordVisibility,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirm password is required';
                      }
                      if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: middleNameController,
                    decoration: InputDecoration(
                      labelText: 'Middle Name (Optional)',
                      hintText: 'Enter your middle name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedDistrict,
                    decoration: InputDecoration(
                      labelText: 'District',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                    items: districts.map((district) {
                      return DropdownMenuItem<String>(
                        value: district['id'].toString(),
                        child: Text(district['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDistrict = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'District is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedAgeGroup,
                    decoration: InputDecoration(
                      labelText: 'Age Group',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    items: ageGroups.map((ageGroup) {
                      return DropdownMenuItem<String>(
                        value: ageGroup['id'].toString(),
                        child: Text(ageGroup['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedAgeGroup = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Age group is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedEduLevel,
                    decoration: InputDecoration(
                      labelText: 'Education Level',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(Icons.school_outlined),
                    ),
                    items: eduLevels.map((eduLevel) {
                      return DropdownMenuItem<String>(
                        value: eduLevel['id'].toString(),
                        child: Text(eduLevel['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedEduLevel = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Education level is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedPartyRole,
                    decoration: InputDecoration(
                      labelText: 'Party Role',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(Icons.people_outline),
                    ),
                    items: partyRoles.map((partyRole) {
                      return DropdownMenuItem<String>(
                        value: partyRole['id'].toString(),
                        child: Text(partyRole['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPartyRole = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Party role is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedMembershipLevel,
                    decoration: InputDecoration(
                      labelText: 'Membership Level',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(Icons.star_outline),
                    ),
                    items: membershipLevels.map((membershipLevel) {
                      return DropdownMenuItem<String>(
                        value: membershipLevel['id'].toString(),
                        child: Text(membershipLevel['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMembershipLevel = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Membership level is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
  value: selectedGender,
  decoration: InputDecoration(
    labelText: 'Gender',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
    prefixIcon: const Icon(Icons.person),
  ),
  items: genders.map((gender) {
    return DropdownMenuItem<String>(
      value: gender,
      child: Text(gender),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      selectedGender = value;
    });
  },
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Gender is required';
    }
    return null;
  },
),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        disabledBackgroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Register',
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