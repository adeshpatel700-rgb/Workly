import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workly/core/constants/app_colors.dart';
import '../data/auth_service.dart';

class JoinWorkplaceScreen extends StatefulWidget {
  const JoinWorkplaceScreen({super.key});

  @override
  State<JoinWorkplaceScreen> createState() => _JoinWorkplaceScreenState();
}

class _JoinWorkplaceScreenState extends State<JoinWorkplaceScreen> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  bool _isLoading = false;

  Future<void> _join() async {
    if (_nameController.text.isEmpty || _idController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // 1. Verify Workplace Exists First (Requires Auth, so we try anonymous login first)
      // If Anonymous Auth is disabled, this will throw immediately.
      await authService.joinWorkplace(
        _nameController.text.trim(),
        _idController.text.trim(),
      );

      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        String message = 'Failed to join';
        final err = e.toString().toLowerCase();

        if (err.contains('operation-not-allowed')) {
          message =
              'Anonymous Login disabled in Firebase Console. Please enable "Anonymous" provider in Auth settings.';
        } else if (err.contains('not-found') ||
            err.contains('permission-denied')) {
          message = 'Workplace not found or access denied. Check ID.';
        } else {
          message = 'Error: $e';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Workplace'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  size: 56,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Join Your Team',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your details and workplace ID to get started',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'John Doe',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Workplace ID',
                hintText: 'Enter the ID from your admin',
                prefixIcon: Icon(Icons.business_rounded),
                helperText: 'Ask your admin for the workplace ID',
                helperStyle: TextStyle(fontSize: 12),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _join,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.group_add_rounded),
                label: Text(_isLoading ? 'Joining...' : 'Join Workplace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
