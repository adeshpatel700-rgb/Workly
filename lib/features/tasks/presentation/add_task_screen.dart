import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:workly/core/constants/app_colors.dart';
import '../../workplace/data/workplace_service.dart';
import '../../workplace/data/models.dart';

class AddTaskScreen extends StatefulWidget {
  final String workplaceId;
  final TaskItem? taskToEdit;

  const AddTaskScreen({
    super.key,
    required this.workplaceId,
    this.taskToEdit,
  });

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

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      _titleController.text = widget.taskToEdit!.title;
      _descController.text = widget.taskToEdit!.description;
      _locController.text = widget.taskToEdit!.location ?? '';
      _base64Image = widget.taskToEdit!.imageBase64;
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 600,
    );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title required')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.taskToEdit == null) {
        await Provider.of<WorkplaceService>(context, listen: false).addTask(
          widget.workplaceId,
          _titleController.text.trim(),
          _descController.text.trim(),
          _locController.text.trim(),
          _base64Image,
        );
      } else {
        await Provider.of<WorkplaceService>(context, listen: false).updateTask(
          widget.workplaceId,
          widget.taskToEdit!.id,
          _titleController.text.trim(),
          _descController.text.trim(),
          _locController.text.trim(),
          _base64Image,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.taskToEdit == null
                  ? 'Task created successfully'
                  : 'Task updated successfully',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskToEdit == null ? 'Create New Task' : 'Edit Task'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: (_imageFile == null && _base64Image == null)
                      ? AppColors.primary.withOpacity(0.05)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : (_base64Image != null
                          ? DecorationImage(
                              image: MemoryImage(base64Decode(_base64Image!)),
                              fit: BoxFit.cover,
                            )
                          : null),
                ),
                child: (_imageFile == null && _base64Image == null)
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Add Task Photo',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Optional • Tap to capture',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
             if (_imageFile != null || _base64Image != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => setState(() {
                  _imageFile = null;
                  _base64Image = null;
                }),
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                label: const Text(
                  'Remove Photo',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.error.withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Task Title *',
                hintText: 'Enter task title',
                prefixIcon: const Icon(Icons.title),
                labelStyle: const TextStyle(fontWeight: FontWeight.w500),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Add task details...',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.description),
                ),
                labelStyle: const TextStyle(fontWeight: FontWeight.w500),
              ),
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),
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
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle, size: 24),
                label: Text(
                  _isLoading
                      ? (widget.taskToEdit == null
                          ? 'Creating Task...'
                          : 'Updating Task...')
                      : (widget.taskToEdit == null
                          ? 'Create Task'
                          : 'Update Task'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: _isLoading ? 0 : 4,
                  shadowColor: AppColors.primary.withOpacity(0.3),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
