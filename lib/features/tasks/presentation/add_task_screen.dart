import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:workly/core/constants/app_colors.dart';
import '../../workplace/data/workplace_service.dart';

class AddTaskScreen extends StatefulWidget {
  final String workplaceId;
  const AddTaskScreen({super.key, required this.workplaceId});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locController = TextEditingController();
  String? _base64Image;
  File? _imageFile;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, maxWidth: 600);
    if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
        // Convert to base64
        List<int> imageBytes = await _imageFile!.readAsBytes();
        setState(() {
          _base64Image = base64Encode(imageBytes);
        });
    }
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title required')));
        return;
    }

    setState(() => _isLoading = true);
    try {
      await Provider.of<WorkplaceService>(context, listen: false).addTask(
        widget.workplaceId,
        _titleController.text.trim(),
        _descController.text.trim(),
        _locController.text.trim(),
        _base64Image,
      );
      if (mounted) Navigator.pop(context);
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
      appBar: AppBar(title: const Text('New Task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Add Photo (Optional)', style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : null,
              ),
            ),
            if (_imageFile != null)
              TextButton.icon(
                onPressed: () => setState(() {
                  _imageFile = null;
                  _base64Image = null;
                }),
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Remove Image', style: TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locController,
              decoration: const InputDecoration(
                labelText: 'Location Tag',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Post Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
