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
          message = 'Anonymous Login disabled in Firebase Console. Please enable "Anonymous" provider in Auth settings.';
        } else if (err.contains('not-found') || err.contains('permission-denied')) {
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
      appBar: AppBar(title: const Text('Join Workplace')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Workplace ID',
                prefixIcon: Icon(Icons.numbers),
                helperText: 'Ask your admin for the ID',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _join,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Join Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
