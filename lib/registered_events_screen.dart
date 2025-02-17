import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants/constants.dart';
import 'qr_code_screen.dart'; // For navigation to the QR code page

class RegisteredEventsScreen extends StatefulWidget {
  final String memberId;

  const RegisteredEventsScreen({super.key, required this.memberId});

  @override
  State<RegisteredEventsScreen> createState() => _RegisteredEventsScreenState();
}

class _RegisteredEventsScreenState extends State<RegisteredEventsScreen> {
  List<dynamic> events = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRegisteredEvents();
  }

  Future<void> _fetchRegisteredEvents() async {
    try {
      final response = await http.get(
        Uri.parse('${devBaseUrl}api/events/active/registered?member_id=${widget.memberId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          events = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch registered events: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
    }
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
        title: const Text('Registered Events'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
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
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 8),
                          Text(
                            'Location: ${event['location']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start: ${_formatDate(event['start_time'])}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'End: ${_formatDate(event['end_time'])}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.qr_code, size: 30),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QrCodeScreen(
                                      eventId: event['id'],
                                      memberId: widget.memberId,
                                      eventTitle: event['title'],
                                      eventDescription: event['description'],
                                      eventLocation: event['location'],
                                      eventStartTime: event['start_time'],
                                      eventEndTime: event['end_time'],
                                    ),
                                  ),
                                );
                              },
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