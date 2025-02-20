import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants/constants.dart';

class EventScreen extends StatefulWidget {
  final int stateId;
  final String memberId;

  const EventScreen({super.key, required this.stateId, required this.memberId});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  List<dynamic> events = [];
  bool isLoading = true;
  Map<String, bool> loadingStates = {}; // Track loading state for each event

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
  try {
    final response = await http.get(
      Uri.parse('${devBaseUrl}api/events/Unregisted/memberEventsByState/${widget.stateId}?member_id=${widget.memberId}'),
    );
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
        setState(() {
          events = jsonResponse['data']; // Extracting the list from "data"
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unexpected response format'), backgroundColor: Colors.green),
        );
      }
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch events: ${response.statusCode}'), backgroundColor: Colors.red),
      );
    }
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred: ${e.toString()}'), backgroundColor: Colors.red),
    );
  }
}



  Future<void> _registerToEvent(String eventId) async {
    setState(() {
      loadingStates[eventId] = true; // Set loading state for this event
    });

    try {
      final response = await http.post(
        Uri.parse('${devBaseUrl}api/events/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'member_id': widget.memberId,
          'event_id': eventId,
          'status': 'active',
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registered to event successfully'), backgroundColor: Colors.green),
        );
        _fetchEvents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register: ${response.statusCode}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        loadingStates[eventId] = false; // Reset loading state for this event
      });
    }
  }

  void _showRegistrationDialog(int eventId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Registration'),
          content: const Text('Are you sure you want to register for this event?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Register'),
              onPressed: () {
                Navigator.of(context).pop();
                _registerToEvent(eventId.toString()); // Convert int to String
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String isoDate) {
    final dateTime = DateTime.parse(isoDate);
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} $hour:$minute';
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Upcoming Events'),
      // Remove the invalid backgroundColor line
    ),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : events.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50, // Light blue background
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available, // Use a relevant icon
                          size: 60,
                          color: Colors.blue.shade900,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No Upcoming Events',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 120, 192, 228),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'There are no events in your state at the moment. Check back later!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final eventId = event['id'].toString();
                  final isRegistering = loadingStates[eventId] ?? false;

                  return Card(
                    margin: const EdgeInsets.all(10),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade50, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'],
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event['description'],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 20, color: Colors.blue.shade900),
                                const SizedBox(width: 8),
                                Text(
                                  event['location'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 20, color: Colors.blue.shade900),
                                const SizedBox(width: 8),
                                Text(
                                  'Start: ${_formatDate(event['start_time'])}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 20, color: Colors.blue.shade900),
                                const SizedBox(width: 8),
                                Text(
                                  'End: ${_formatDate(event['end_time'])}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.info, size: 20, color: Colors.blue.shade900),
                                const SizedBox(width: 8),
                                Text(
                                  'Status: ${event['Status']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton(
                                onPressed: isRegistering
                                    ? null
                                    : () {
                                        if (event['id'] != null) {
                                          _showRegistrationDialog(event['id']); // Pass int directly
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Event ID is missing')),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade900,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: isRegistering
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Register',
                                        style: TextStyle(
                                          fontSize: 16,
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
                },
              ),
  );
}
}