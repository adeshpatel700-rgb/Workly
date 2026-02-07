import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workly/core/constants/app_colors.dart';
import '../data/auth_service.dart';
import '../../workplace/presentation/create_workplace_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController(text: 'satyrendrapatel2302@gmail.com');
  final _passController = TextEditingController(); // Password: Try?12345
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final email = _emailController.text.trim();
    final pass = _passController.text.trim();
    
    try {
      await auth.signInAdmin(email, pass);
      // Navigation handled by auth wrapper in main.dart
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      // Auto-provision the single admin if not found
      if (e.toString().contains('user-not-found') && email == 'satyrendrapatel2302@gmail.com') {
        try {
          await auth.signUpAdmin(email, pass);
          if (mounted) {
             Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => const CreateWorkplaceScreen())
            );
          }
          return;
        } catch (signUpError) {
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to create admin: $signUpError'), backgroundColor: AppColors.error),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passController,
              decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Log In'),
              ),
            ),
            // Signup removed as per requirements (Single Admin Policy)
          ],
        ),
      ),
    );
  }
}
