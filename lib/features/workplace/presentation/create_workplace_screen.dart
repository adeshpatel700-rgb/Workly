import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../workplace/data/workplace_service.dart';

class CreateWorkplaceScreen extends StatefulWidget {
  const CreateWorkplaceScreen({super.key});

  @override
  State<CreateWorkplaceScreen> createState() => _CreateWorkplaceScreenState();
}

class _CreateWorkplaceScreenState extends State<CreateWorkplaceScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _create() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final wpService = Provider.of<WorkplaceService>(context, listen: false);
      
      String id = await wpService.createWorkplace(user.uid, _nameController.text.trim());
      
      // Update admin user doc
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'workplaceId': id,
      });

      // Local persist
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('workplaceId', id);

      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Workplace')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              "Let's set up your team's space.",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Workplace Name',
                hintText: 'e.g. Design Team Alpha',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _create,
                child: const Text('Create Workplace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
