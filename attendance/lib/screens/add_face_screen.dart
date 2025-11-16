import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/attendance_api_service.dart';
import '../theme/app_theme.dart';

class AddFaceScreen extends StatefulWidget {
  final AttendanceApiService apiService;

  const AddFaceScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<AddFaceScreen> createState() => _AddFaceScreenState();
}

class _AddFaceScreenState extends State<AddFaceScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<XFile> _selectedImages = [];
  bool _isUploading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      _showError('Please select at least one image');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final imagePaths = _selectedImages.map((img) => img.path).toList();
      final success = await widget.apiService.addFace(
        name: _nameController.text.trim(),
        imagePaths: imagePaths,
      );

      if (!mounted) return;

      if (success) {
        _showSuccess('Face added successfully!');
        Navigator.pop(context, true);
      } else {
        _showError('Failed to add face');
        setState(() => _isUploading = false);
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
      setState(() => _isUploading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.grey800,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Face'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          children: [
            _buildNameInput(),
            const SizedBox(height: AppTheme.spacing24),
            _buildImageSection(),
            const SizedBox(height: AppTheme.spacing32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Person Name',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Enter full name',
            prefixIcon: Icon(Icons.person_outline),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photos (${_selectedImages.length})',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              'Min: 3 recommended',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        _buildImagePickers(),
        const SizedBox(height: AppTheme.spacing16),
        if (_selectedImages.isNotEmpty) _buildImageGrid(),
      ],
    );
  }

  Widget _buildImagePickers() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : _pickImages,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Gallery'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
              side: const BorderSide(color: AppTheme.grey300),
              foregroundColor: AppTheme.black,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : _takePicture,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Camera'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
              side: const BorderSide(color: AppTheme.grey300),
              foregroundColor: AppTheme.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppTheme.spacing8,
        crossAxisSpacing: AppTheme.spacing8,
        childAspectRatio: 1,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        return _ImageThumbnail(
          image: _selectedImages[index],
          onRemove: () => _removeImage(index),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _submit,
        child: _isUploading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: AppTheme.white,
                  strokeWidth: 2,
                ),
              )
            : const Text('Add Face'),
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  final XFile image;
  final VoidCallback onRemove;

  const _ImageThumbnail({
    required this.image,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radius8),
          child: Image.file(
            File(image.path),
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppTheme.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: AppTheme.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
