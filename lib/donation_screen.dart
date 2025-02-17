import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants/constants.dart';
import 'dart:math';
import 'dart:io';

class DonationScreen extends StatefulWidget {
  final String memberId;
  final String phone;

  DonationScreen({required this.memberId, required this.phone});

  @override
  _DonationScreenState createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _alternativePhoneController = TextEditingController();
  String _selectedPaymentMethod = 'EVC';
  bool _isLoading = false;
  bool _useAnotherPhone = false;

  // Payment methods
  final List<String> _paymentMethods = ['EVC', 'E-Dahab', 'My Cash', 'Premier Wallet'];

  // Function to generate a unique transaction ID
  String _generateTransactionId() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomString = String.fromCharCodes(
      Iterable.generate(
        6, // Length of the random string
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    return '${widget.memberId}_$timestamp$randomString';
  }

  Future<void> _submitDonation() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
  });

  try {
    // Prepare the phone number (remove "+252" if present)
    String phone = _useAnotherPhone
        ? (_alternativePhoneController.text.startsWith('+252')
            ? _alternativePhoneController.text.substring(4)
            : _alternativePhoneController.text)
        : (widget.phone.startsWith('+252')
            ? widget.phone.substring(4)
            : widget.phone);

    // Generate a unique transaction ID
    final transactionId = _generateTransactionId();

    // Trigger payment request
    final paymentResponse = await http.get(
      Uri.parse(
        '${devBaseUrl}api/members/payment/requestPayment?phone=$phone&amount=${_amountController.text}',
      ),
    );

    print('Payment Response: ${paymentResponse.body}');
    print('Payment Status: ${paymentResponse.statusCode}');

    if (paymentResponse.statusCode == 200) {
      final responseData = json.decode(paymentResponse.body);

      if (responseData['success'] == true) {
        final waafipayResponse = responseData['waafipayResponse'];

        if (waafipayResponse != null && waafipayResponse['responseCode'] == "2001") {
          // Payment successful, proceed with donation submission
          final donationResponse = await http.post(
            Uri.parse('${devBaseUrl}api/members/donation'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'member_id': widget.memberId,
              'amount': _amountController.text,
              'payment_method': _selectedPaymentMethod,
              'transaction_id': transactionId,
            }),
          );

          if (donationResponse.statusCode == 201) {
            showSnackbar('Donation successful!', Colors.green);
            _amountController.clear();
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.pop(context);
            });
          } else {
            throw Exception('Failed to submit donation');
          }
        } else {
          // Handle WaafiPay error responses
          final responseMsg = waafipayResponse?['responseMsg'] ?? 'Unknown error';
          showSnackbar(responseMsg, Colors.red);
        }
      } else {
        // Handle generic failure messages
        final errorMessage = responseData['message'] ?? 'Payment failed.';
        showSnackbar(errorMessage, Colors.red);
      }
    } else {
      // Handle non-200 status codes
      final errorResponse = json.decode(paymentResponse.body);
      final errorMessage = errorResponse['details'] ?? 
          errorResponse['message'] ?? 
          'Error occurred. Status: ${paymentResponse.statusCode}';
      showSnackbar(errorMessage, Colors.red);
    }
  } on FormatException {
    showSnackbar('Invalid response format from server. Please try again.', Colors.red);
  } on SocketException {
    showSnackbar('No internet connection. Please check your connection.', Colors.red);
  } catch (error) {
    showSnackbar(
      error.toString().contains('SocketException')
          ? 'No internet connection. Please check your connection.'
          : error.toString(),
      Colors.red,
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

void showSnackbar(String message, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Make a Donation',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Method Dropdown
              Text(
                'Payment Method',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                items: _paymentMethods.map<DropdownMenuItem<String>>((method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(
                      method,
                      style: GoogleFonts.poppins(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                value: _selectedPaymentMethod,
              ),
              const SizedBox(height: 20),

              // Amount Input
              Text(
                'Amount',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter donation amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Other Phone Number Toggle
              Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Use different phone number',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Switch(
                          value: _useAnotherPhone,
                          onChanged: (value) {
                            setState(() {
                              _useAnotherPhone = value;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_useAnotherPhone) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _alternativePhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Alternative Phone Number',
                          hintText: 'Enter phone number',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          prefixText: '+252 ',
                          prefixStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Submit Donation',
                          style: GoogleFonts.poppins(
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