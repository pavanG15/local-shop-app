import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:local_shop_app/models/app_user_model.dart';
import 'package:local_shop_app/models/offer_model.dart';
import 'package:local_shop_app/services/auth_service.dart';
import 'package:local_shop_app/services/firestore_service.dart';
import 'package:local_shop_app/services/cloudinary_service.dart';
// Removed flutter_datetime_picker_plus as it's no longer directly used for date picking

class EditOfferScreen extends StatefulWidget {
  final Offer offer;
  const EditOfferScreen({super.key, required this.offer});

  @override
  State<EditOfferScreen> createState() => _EditOfferScreenState();
}

class _EditOfferScreenState extends State<EditOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _discountController;
  late TextEditingController _expiryDateController;

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  User? _currentUser;
  AppUser? _appUser;
  XFile? _imageFile;
  DateTime? _selectedExpiryDate;
  String? _selectedExpiryDuration;
  bool _isLoading = false;
  String? _currentImageUrl;
  String? _currentImagePublicId;

  final List<String> _expiryDurations = [
    '3 days',
    '7 days',
    '15 days',
    '30 days', // Changed from '1 month' for consistency in calculation
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.getCurrentUser();
    _loadUserData();

    _titleController = TextEditingController(text: widget.offer.title);
    _descriptionController = TextEditingController(text: widget.offer.description);
    _discountController = TextEditingController(text: widget.offer.discount.toString());
    _selectedExpiryDate = widget.offer.expiryDate;
    _expiryDateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(widget.offer.expiryDate));
    _currentImageUrl = widget.offer.imageUrl;
    _currentImagePublicId = widget.offer.imagePublicId;

    _selectedExpiryDuration = _getDurationFromExpiryDate(widget.offer.expiryDate);
  }

  String _getDurationFromExpiryDate(DateTime expiryDate) {
    DateTime now = DateTime.now();
    Duration difference = expiryDate.difference(now);

    if (difference.inDays <= 3) {
      return '3 days';
    } else if (difference.inDays <= 7) {
      return '7 days';
    } else if (difference.inDays <= 15) {
      return '15 days';
    } else if (difference.inDays <= 30) { // Approximately 1 month
      return '30 days';
    }
    return '7 days'; // Default
  }

  Future<void> _loadUserData() async {
    if (_currentUser != null) {
      _appUser = await _authService.getAppUser(_currentUser!.uid);
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = image;
      if (image != null) {
        _currentImageUrl = null;
        _currentImagePublicId = null;
      }
    });
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _currentImageUrl = null;
      _currentImagePublicId = null;
    });
  }

  void _calculateExpiryDate(String duration) {
    DateTime now = DateTime.now();
    DateTime calculatedDate;

    switch (duration) {
      case '3 days':
        calculatedDate = now.add(const Duration(days: 3));
        break;
      case '7 days':
        calculatedDate = now.add(const Duration(days: 7));
        break;
      case '15 days':
        calculatedDate = now.add(const Duration(days: 15));
        break;
      case '30 days':
        calculatedDate = now.add(const Duration(days: 30));
        break;
      default:
        calculatedDate = now.add(const Duration(days: 7));
    }

    setState(() {
      _selectedExpiryDate = calculatedDate;
      _expiryDateController.text = DateFormat('yyyy-MM-dd').format(calculatedDate);
    });
  }

  Future<void> _submitOffer() async {
    if (_formKey.currentState!.validate()) {
      if (_appUser == null || _appUser!.shopName == null || _appUser!.category == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business owner details are missing. Please update your profile.')),
        );
        return;
      }
      if (_selectedExpiryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an expiry date.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      String? imageUrl = _currentImageUrl;
      String? imagePublicId = _currentImagePublicId;

      try {
        if (_imageFile != null) {
          final uploadResult = await _cloudinaryService.uploadImage(_imageFile!);
          if (uploadResult != null) {
            imageUrl = uploadResult['secure_url'];
            imagePublicId = uploadResult['public_id'];
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload new image to Cloudinary.')),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        } else if (_currentImageUrl == null && widget.offer.imageUrl != null) {
          // If image was removed and there was an old image, delete it from Cloudinary via webhook
          if (widget.offer.imagePublicId != null) {
            await _cloudinaryService.deleteImage(widget.offer.imagePublicId!);
          }
        }

        final updatedOffer = Offer(
          offerId: widget.offer.offerId,
          ownerId: _currentUser!.uid,
          shopName: _appUser!.shopName!,
          category: _appUser!.category!,
          title: _titleController.text,
          description: _descriptionController.text,
          discount: int.parse(_discountController.text),
          expiryDate: _selectedExpiryDate!,
          imageUrl: imageUrl,
          imagePublicId: imagePublicId,
        );

        await _firestoreService.updateOffer(updatedOffer);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer updated successfully!')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update offer: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null || _appUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Offer')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Offer'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Offer Title'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _discountController,
                      decoration: const InputDecoration(labelText: 'Discount (%)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a discount percentage';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Expiry Duration',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedExpiryDuration,
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedExpiryDuration = newValue;
                              if (newValue != null) {
                                _calculateExpiryDate(newValue);
                              }
                            });
                          },
                          items: _expiryDurations.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _expiryDateController,
                      decoration: const InputDecoration(
                        labelText: 'Calculated Expiry Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    if (_imageFile != null)
                      Image.network(_imageFile!.path, height: 150)
                    else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                      Image.network(_currentImageUrl!, height: 150)
                    else
                      const Text('No image selected.'),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text('Change Image (Optional)'),
                        ),
                        if (_imageFile != null || (_currentImageUrl != null && _currentImageUrl!.isNotEmpty))
                          TextButton(
                            onPressed: _removeImage,
                            child: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: _submitOffer,
                        child: const Text('Update Offer'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
