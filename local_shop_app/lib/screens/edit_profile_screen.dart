import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_shop_app/models/app_user_model.dart';
import 'package:local_shop_app/services/auth_service.dart';
import 'package:local_shop_app/services/cloudinary_service.dart';
import 'package:local_shop_app/utils/image_picker_util.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser? appUser;

  const EditProfileScreen({super.key, this.appUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _photoUrl;
  bool _isLoading = false;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    if (widget.appUser != null) {
      _nameController.text = widget.appUser!.name ?? '';
      _phoneController.text = widget.appUser!.phone ?? '';
      _photoUrl = widget.appUser!.photoUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    XFile? image = await ImagePickerUtil.pickImageFromGallery();
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _cloudinaryService.uploadImage(_selectedImage!);
      if (result != null) {
        setState(() {
          _photoUrl = result['secure_url'];
          _selectedImage = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_selectedImage != null) {
      await _uploadImage();
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.updateProfile(
        widget.appUser!.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: _photoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _selectedImage != null
                        ? Image.file(File(_selectedImage!.path)).image
                        : _photoUrl != null
                            ? NetworkImage(_photoUrl!)
                            : null,
                    child: _selectedImage == null && _photoUrl == null
                        ? const Icon(Icons.account_circle, size: 120)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            if (_selectedImage != null)
              ElevatedButton(
                onPressed: _uploadImage,
                child: const Text('Upload Image'),
              ),
          ],
        ),
      ),
    );
  }
}
