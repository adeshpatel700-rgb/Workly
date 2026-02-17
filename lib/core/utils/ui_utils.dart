import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class UiUtils {
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showError(BuildContext context, dynamic error) {
    String message = error.toString();
    
    // Clean up common Firebase errors
    if (message.contains('user-not-found')) {
      message = 'User not found. Please check your email.';
    } else if (message.contains('wrong-password') || message.contains('invalid-credential')) {
      message = 'Incorrect password or credentials.';
    } else if (message.contains('network-request-failed')) {
      message = 'Network error. Please check your connection.';
    } else if (message.contains('email-already-in-use')) {
      message = 'This email is already registered.';
    } else if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    }
    
    showSnackBar(context, message, isError: true);
  }
}
