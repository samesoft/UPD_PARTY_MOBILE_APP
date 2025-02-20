import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:async'; // For Timer
import 'dart:convert';
import 'package:upd_party/constants/constants.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  _ScannerPageState createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scannedData;
  bool _isLoading = false; // To prevent multiple requests
  Timer? _debounceTimer; // For debounce mechanism

  @override
  void dispose() {
    controller?.dispose();
    _debounceTimer?.cancel(); // Cancel the timer on dispose
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!_isLoading && scannedData != scanData.code) {
        _debounceTimer?.cancel(); // Cancel the previous timer
        _debounceTimer = Timer(const Duration(seconds: 1), () {
          setState(() {
            scannedData = scanData.code;
          });
          _fetchEventMemberDetails(scannedData!);
        });
      }
    });
  }

  Future<void> _fetchEventMemberDetails(String qrcode) async {
    if (_isLoading) return; // Prevent multiple requests

    setState(() {
      _isLoading = true;
    });

    try {
      print("QR code: $qrcode");
      final response = await http.get(
        Uri.parse('${devBaseUrl}api/events/ticket/verify-ticket?qrcode=$qrcode'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventMemberDetailsPage(details: data),
          ),
        );
      } else {
        // Handle specific error status codes
        final errorResponse = jsonDecode(response.body);
        final errorMessage = errorResponse['error'] ?? 'An unknown error occurred';

        if (response.statusCode == 404) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        } else if (response.statusCode == 400) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch details: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      // Handle network or other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(scannedData ?? 'Scan a QR code'),
            ),
          ),
        ],
      ),
    );
  }
}

class EventMemberDetailsPage extends StatelessWidget {
  final Map<String, dynamic> details;

  const EventMemberDetailsPage({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event & Member Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Event Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    _buildDetailRow('Title', details['event_title']),
                    _buildDetailRow('Description', details['event_description']),
                    _buildDetailRow('Location', details['event_location']),
                    _buildDetailRow('Start Time', details['event_start_time']),
                    _buildDetailRow('End Time', details['event_end_time']),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Member Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    _buildDetailRow('Name', details['member_name']),
                    _buildDetailRow('Mobile', details['member_mobile']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}