import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants/constants.dart';

class AdminEventManagementScreen extends StatefulWidget {
  const AdminEventManagementScreen({super.key});

  @override
  State<AdminEventManagementScreen> createState() =>
      _AdminEventManagementScreenState();
}

class _AdminEventManagementScreenState extends State<AdminEventManagementScreen> {
  List<dynamic> events = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  Map<String, bool> cancelledLoadingStates = {}; // Track loading state for "Cancelled" button
  Map<String, bool> completedLoadingStates = {}; // Track loading state for "Completed" button

  @override
  void initState() {
    super.initState();
    _fetchActiveEvents();
  }

  Future<void> _fetchActiveEvents() async {
    try {
      final response = await http.get(
        Uri.parse('${devBaseUrl}api/events/active/all'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          setState(() {
            events = jsonResponse['data'];
            isLoading = false;
            hasError = false;
          });
        } else {
          setState(() {
            isLoading = false;
            hasError = true;
            errorMessage = 'Unexpected response format';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'Failed to fetch events: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'An error occurred: ${e.toString()}';
      });
    }
  }

  Future<void> _updateEventStatus(String eventId, String status) async {
    // Set the loading state for the clicked button
    if (status == 'Cancelled') {
      setState(() {
        cancelledLoadingStates[eventId] = true;
      });
    } else if (status == 'Completed') {
      setState(() {
        completedLoadingStates[eventId] = true;
      });
    }

    try {
      final response = await http.put(
        Uri.parse('${devBaseUrl}api/events/updateStatus'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eventId': eventId,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event status updated to $status'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchActiveEvents(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          // Reset the loading state for the clicked button
          if (status == 'Cancelled') {
            cancelledLoadingStates[eventId] = false;
          } else if (status == 'Completed') {
            completedLoadingStates[eventId] = false;
          }
        });
      }
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
        title: const Text('Manage Events'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      fontSize: 18, color: Colors.red.shade900),
                  ),
                )
              : events.isEmpty
                  ? Center(
                      child: Text(
                        'No Active Events',
                        style: TextStyle(
                            fontSize: 24, color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        final eventId = event['id'].toString();
                        final isCancelledLoading =
                            cancelledLoadingStates[eventId] ?? false;
                        final isCompletedLoading =
                            completedLoadingStates[eventId] ?? false;

                        return Card(
                          margin: const EdgeInsets.all(10),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
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
                                    Icon(Icons.location_on,
                                        size: 20, color: Colors.blue.shade900),
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
                                    Icon(Icons.calendar_today,
                                        size: 20, color: Colors.blue.shade900),
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
                                    Icon(Icons.calendar_today,
                                        size: 20, color: Colors.blue.shade900),
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
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    ElevatedButton(
                                      onPressed: isCancelledLoading
                                          ? null
                                          : () => _updateEventStatus(
                                              eventId, 'Cancelled'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade900,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                      ),
                                      child: isCancelledLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Mark as Cancelled', style: TextStyle(color: Colors.white)),
                                    ),
                                    ElevatedButton(
                                      onPressed: isCompletedLoading
                                          ? null
                                          : () => _updateEventStatus(
                                              eventId, 'Completed'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade900,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                      ),
                                      child: isCompletedLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Mark as Completed', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}