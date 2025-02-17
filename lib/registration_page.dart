import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:upd_party/login_page.dart';
import 'dart:convert';
import 'dart:io';

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

  // Dynamic dropdown options
  List<Map<String, dynamic>> districts = [];
  List<Map<String, dynamic>> ageGroups = [];
  List<Map<String, dynamic>> eduLevels = [];
  List<Map<String, dynamic>> partyRoles = [];
  List<Map<String, dynamic>> membershipLevels = [];

  @override
  void initState() {
    super.initState();
    fetchDropdownData();
  }

  Future<void> fetchDropdownData() async {
    try {
      final districtResponse = await http.get(Uri.parse('${devBaseUrl}api/district'));
      final ageGroupResponse = await http.get(Uri.parse('${devBaseUrl}api/age-groups'));
      final eduLevelResponse = await http.get(Uri.parse('${devBaseUrl}api/education-level'));
      final partyRoleResponse = await http.get(Uri.parse('${devBaseUrl}api/party-role'));
      final membershipLevelResponse = await http.get(Uri.parse('${devBaseUrl}api/membership-level'));

      if (districtResponse.statusCode == 200 &&
          ageGroupResponse.statusCode == 200 &&
          eduLevelResponse.statusCode == 200 &&
          partyRoleResponse.statusCode == 200 &&
          membershipLevelResponse.statusCode == 200) {
        setState(() {
          districts = List<Map<String, dynamic>>.from(jsonDecode(districtResponse.body)['data']);
          ageGroups = List<Map<String, dynamic>>.from(jsonDecode(ageGroupResponse.body)['data']);
          eduLevels = List<Map<String, dynamic>>.from(jsonDecode(eduLevelResponse.body)['data']);
          partyRoles = List<Map<String, dynamic>>.from(jsonDecode(partyRoleResponse.body)['data']);
          membershipLevels = List<Map<String, dynamic>>.from(jsonDecode(membershipLevelResponse.body)['data']);
        });
      } else {
        throw Exception('Failed to load dropdown data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load dropdown data: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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

  try {
    // Ensure all required fields are selected
    if (selectedDistrict == null ||
        selectedAgeGroup == null ||
        selectedEduLevel == null ||
        selectedPartyRole == null ||
        selectedMembershipLevel == null ||
        selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Find the selected party role name
    final partyRoleName = partyRoles.firstWhere(
      (role) => role['party_role_id'].toString() == selectedPartyRole,
    )['party_role'];

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
        'party_role': partyRoleName,
        'memb_level_id': selectedMembershipLevel,
        'gender': selectedGender,
        'role_id': 1
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

      // Wait for 2 seconds before navigating to the login page
      await Future.delayed(const Duration(seconds: 2));

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
        content: Text("Unexpected response from the server. Please try again later."),
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
                  // First Name
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
                  // Last Name
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
                  // Email
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
                  // Password
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
                  // Confirm Password
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
                  // Middle Name (Optional)
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
                  // District Dropdown
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
                        value: district['district_id'].toString(),
                        child: Text(district['district']),
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
                  // Age Group Dropdown
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
                        child: Text(ageGroup['age_group']),
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
                  // Education Level Dropdown
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
                        value: eduLevel['edu_level_id'].toString(),
                        child: Text(eduLevel['educ_level']),
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
                  // Party Role Dropdown
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
                        value: partyRole['party_role_id'].toString(),
                        child: Text(partyRole['party_role']),
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
                  // Membership Level Dropdown
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
                  // Gender Dropdown
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
                  // Register Button
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