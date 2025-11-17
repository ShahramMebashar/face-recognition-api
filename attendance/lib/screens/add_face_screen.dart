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

      // Extract user-friendly error message
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      // Show specific error messages
      if (errorMessage.contains('No face detected')) {
        _showErrorDialog(
          'No Face Detected',
          'Please ensure your photos clearly show a face. Tips:\n'
              '• Take photos in good lighting\n'
              '• Face should be clearly visible\n'
              '• Avoid blurry or dark images\n'
              '• Face should be looking at camera',
        );
      } else if (errorMessage.contains('Connection refused') ||
          errorMessage.contains('Failed host lookup')) {
        _showErrorDialog(
          'Connection Error',
          'Unable to reach the server. Please check your internet connection and try again.',
        );
      } else {
        _showError(errorMessage);
      }

      setState(() => _isUploading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.grey800,
        duration: const Duration(seconds: 4),
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

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Add New Person'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          children: [
            _buildTipsCard(),
            const SizedBox(height: AppTheme.spacing20),
            _buildNameInput(),
            const SizedBox(height: AppTheme.spacing20),
            _buildImageSection(),
            const SizedBox(height: AppTheme.spacing32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tips for Best Results',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTip('Take 3-5 photos from different angles'),
          _buildTip('Ensure good lighting and clear face visibility'),
          _buildTip('Face the camera directly in at least one photo'),
          _buildTip('Avoid sunglasses, masks, or face obstructions'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 20, color: AppTheme.grey600),
              const SizedBox(width: 8),
              const Text(
                'Person Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter full name',
              filled: true,
              fillColor: AppTheme.grey50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing12,
              ),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a name';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final hasMinimumImages = _selectedImages.length >= 3;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera_outlined,
                  size: 20, color: AppTheme.grey600),
              const SizedBox(width: 8),
              const Text(
                'Photos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: hasMinimumImages
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasMinimumImages
                          ? Icons.check_circle
                          : Icons.info_outline,
                      size: 14,
                      color: hasMinimumImages
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_selectedImages.length}/3 min',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasMinimumImages
                            ? Colors.green.shade900
                            : Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildImagePickers(),
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing16),
            _buildImageGrid(),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 48,
                      color: AppTheme.grey300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No photos selected',
                      style: TextStyle(
                        color: AppTheme.grey600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePickers() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : _takePicture,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Take Photo'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.white,
              side: BorderSide(color: AppTheme.grey300),
              foregroundColor: AppTheme.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius8),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : _pickImages,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.white,
              side: BorderSide(color: AppTheme.grey300),
              foregroundColor: AppTheme.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius8),
              ),
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
