import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:local_shop_app/models/app_user_model.dart';
import 'package:local_shop_app/models/offer_model.dart';
import 'package:local_shop_app/services/auth_service.dart';
import 'dart:typed_data'; // Import for Uint8List
import 'package:local_shop_app/services/firestore_service.dart';
import 'package:local_shop_app/services/cloudinary_service.dart';
// Removed flutter_datetime_picker_plus as it's no longer directly used for date picking

class AddOfferScreen extends StatefulWidget {
  const AddOfferScreen({super.key});

  @override
  State<AddOfferScreen> createState() => _AddOfferScreenState();
}

class _AddOfferScreenState extends State<AddOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  User? _currentUser;
  AppUser? _appUser;
  XFile? _imageFile;
  DateTime? _selectedExpiryDate;
  String? _selectedExpiryDuration;
  bool _isLoading = false;

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
    _selectedExpiryDuration = _expiryDurations.first;
    _calculateExpiryDate(_selectedExpiryDuration!);
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

      String? imageUrl;
      String? imagePublicId;

      try {
        if (_imageFile != null) {
          final uploadResult = await _cloudinaryService.uploadImage(_imageFile!);
          if (uploadResult != null) {
            imageUrl = uploadResult['secure_url'];
            imagePublicId = uploadResult['public_id'];
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image to Cloudinary.')),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }

        final newOffer = Offer(
          offerId: '',
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

        await _firestoreService.addOffer(newOffer);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer added successfully!')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add offer: $e')),
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
        appBar: AppBar(title: const Text('Add New Offer')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Offer'),
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
                    _imageFile == null
                        ? const Text('No image selected.')
                        : FutureBuilder<Uint8List>(
                            future: _imageFile!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                return Image.memory(snapshot.data!, height: 150);
                              }
                              return const CircularProgressIndicator();
                            },
                          ),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Select Image (Optional)'),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: _submitOffer,
                        child: const Text('Add Offer'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
