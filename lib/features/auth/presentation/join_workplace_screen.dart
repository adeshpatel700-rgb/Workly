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
      await Provider.of<AuthService>(context, listen: false).joinWorkplace(
        _nameController.text.trim(),
        _idController.text.trim(),
      );
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join: $e'),
            backgroundColor: AppColors.error,
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
