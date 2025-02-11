import 'package:flutter/material.dart';

class SnackbarHelper {
  final BuildContext context;

  SnackbarHelper(this.context);

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }
}