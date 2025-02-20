import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/constants.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // Dropdown values
  String? selectedState;
  String? selectedDistrict;
  String? selectedAgeGroup;
  String? selectedEduLevel;
  String? selectedPartyRole;
  String? selectedMembershipLevel;

  // Dynamic dropdown options
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> districts = [];
  List<Map<String, dynamic>> ageGroups = [];
  List<Map<String, dynamic>> eduLevels = [];
  List<Map<String, dynamic>> roles = [];


  // Loading states
  bool _isInitialLoading = true; // For initial data loading
  bool _isLoading = false; // For update profile button

  // Profile photo URL
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    fetchDropdownData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final memberId = prefs.getString('member_id');
    if (memberId == null) return;

    final response = await http.get(Uri.parse('${devBaseUrl}api/members/$memberId'));
    if (response.statusCode == 200) {
      final memberData = jsonDecode(response.body)['data'];
      print("member data: $memberData");

      setState(() {
        // Update text fields
        _firstNameController.text = memberData['first_name'] ?? '';
        _lastNameController.text = memberData['last_name'] ?? '';
        _emailController.text = memberData['email'] ?? '';
        _mobileController.text = memberData['mobile'] ?? '';

        // Map names to IDs for dropdowns
        selectedState = memberData['state_id']?.toString();
        selectedDistrict = memberData['district_id']?.toString();
        selectedAgeGroup = memberData['age_group_id']?.toString();
        selectedEduLevel = memberData['edu_level_id']?.toString();
        // Set Party Role and Membership Level as read-only
        selectedPartyRole = memberData['party_role']?? '';
        selectedMembershipLevel = memberData['memb_level']?? '';

        // Fetch profile photo URL
        String profilePhotoUrl = memberData['profile_photo_url'] ?? '';
        String backendBaseUrl = "https://upd-party-backend.samesoft.app";
        _profilePhotoUrl = profilePhotoUrl.isNotEmpty ? "$backendBaseUrl$profilePhotoUrl" : null;

       
      });
    }
  }

  Future<void> fetchDropdownData() async {
    try {
      final stateResponse = await http.get(Uri.parse('${devBaseUrl}api/state/cleaned'));
      final districtResponse = await http.get(Uri.parse('${devBaseUrl}api/district'));
      final ageGroupResponse = await http.get(Uri.parse('${devBaseUrl}api/age-groups'));
      final eduLevelResponse = await http.get(Uri.parse('${devBaseUrl}api/education-level'));
      final rolesResponse = await http.get(Uri.parse('${devBaseUrl}api/roles'));

      if (stateResponse.statusCode == 200 &&
          districtResponse.statusCode == 200 &&
          ageGroupResponse.statusCode == 200 &&
          eduLevelResponse.statusCode == 200) {
        setState(() {
          states = List<Map<String, dynamic>>.from(jsonDecode(stateResponse.body)['data']);
          districts = List<Map<String, dynamic>>.from(jsonDecode(districtResponse.body)['data']);
          ageGroups = List<Map<String, dynamic>>.from(jsonDecode(ageGroupResponse.body)['data']);
          eduLevels = List<Map<String, dynamic>>.from(jsonDecode(eduLevelResponse.body)['data']);
          roles = List<Map<String, dynamic>>.from(jsonDecode(rolesResponse.body)['data']);

          _isInitialLoading = false; // Stop initial loading
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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

 Future<void> _updateProfile() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true; // Start loading
  });

  try {
    final prefs = await SharedPreferences.getInstance();
    final memberId = prefs.getString('member_id');
    if (memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please log in again.')),
      );
      return;
    }

    final uri = Uri.parse('${devBaseUrl}api/members/$memberId');
    final request = http.MultipartRequest('PUT', uri);

    // Required fields
    request.fields['first_name'] = _firstNameController.text.trim();
    request.fields['last_name'] = _lastNameController.text.trim();
    request.fields['email'] = _emailController.text.trim();
    request.fields['mobile'] = _mobileController.text.trim();

    // Optional fields - send only if not empty
    if (selectedState != null) request.fields['state_id'] = selectedState!;
    if (selectedDistrict != null) request.fields['district_id'] = selectedDistrict!;
    if (selectedAgeGroup != null) request.fields['age_group_id'] = selectedAgeGroup!;
    if (selectedEduLevel != null) request.fields['edu_level_id'] = selectedEduLevel!;

    // Handle profile image upload
    if (_profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('profile_photo', _profileImage!.path),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    debugPrint("Server Response: $responseBody"); // Log the response

    if (response.statusCode == 200) {
      final responseData = jsonDecode(responseBody);
      if (responseData['error'] != null) {
        throw Exception(responseData['error']);
      }
      final updatedProfilePhotoUrl = responseData['data']['profile_photo_url'] ?? '';
      String backendBaseUrl = "https://upd-party-backend.samesoft.app";
      setState(() {
        _profilePhotoUrl = updatedProfilePhotoUrl.isNotEmpty ? "$backendBaseUrl$updatedProfilePhotoUrl" : null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      Navigator.pop(context); 
    } else {
      debugPrint("Server Response: $responseBody");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: ${response.reasonPhrase}'), backgroundColor: Colors.red),
      );
    }
  } on SocketException {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No internet connection. Please try again.'), backgroundColor: Colors.red),
    );
  } catch (e) {
    debugPrint("Profile update error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An unexpected error occurred: ${e.toString()}'), backgroundColor: Colors.red),
    );
  } finally {
    setState(() {
      _isLoading = false; // Stop loading
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateProfile, // Disable button when loading
          ),
        ],
      ),
      body: _isInitialLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : _profilePhotoUrl != null
                                ? NetworkImage(_profilePhotoUrl!) as ImageProvider<Object>
                                : null,
                        child: _profileImage == null && _profilePhotoUrl == null
                            ? const Icon(Icons.camera_alt, size: 40)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(labelText: 'Mobile'),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedState,
                      decoration: const InputDecoration(labelText: 'State'),
                      items: states.map((state) {
                        return DropdownMenuItem<String>(
                          value: state['stateid'].toString(),
                          child: Text(state['state']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedState = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedDistrict,
                      decoration: const InputDecoration(labelText: 'District'),
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
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedAgeGroup,
                      decoration: const InputDecoration(labelText: 'Age Group'),
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
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedEduLevel,
                      decoration: const InputDecoration(labelText: 'Education Level'),
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
                    ),
                    const SizedBox(height: 20),
                    // Read-only Party Role
                    TextFormField(
                      initialValue: selectedPartyRole,
                      decoration: const InputDecoration(labelText: 'Party Role'),
                      readOnly: true,
                    ),
                    const SizedBox(height: 20),
                    // Read-only Membership Level
                    TextFormField(
                      initialValue: selectedMembershipLevel,
                      decoration: const InputDecoration(labelText: 'Membership Level'),
                      readOnly: true,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile, // Disable button when loading
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.blue, // Change button color
                        foregroundColor: Colors.white, // Change text color
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Update Profile', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}