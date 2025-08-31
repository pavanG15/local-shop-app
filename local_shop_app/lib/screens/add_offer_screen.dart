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
  final TextEditingController _termsController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  User? _currentUser;
  AppUser? _appUser;
  XFile? _imageFile;
  DateTime? _selectedStartDate;
  DateTime? _selectedExpiryDate;
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Food',
    'Grocery',
    'Clothing',
    'Electronics',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.getCurrentUser();
    _loadUserData();
    _selectedCategory = _categories.first;
    _selectedStartDate = DateTime.now();
    _startDateController.text = DateFormat('yyyy-MM-dd').format(_selectedStartDate!);
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

  Future<void> _submitOffer() async {
    if (_formKey.currentState!.validate()) {
      if (_appUser == null || _appUser!.shopName == null) {
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
          category: _selectedCategory!,
          title: _titleController.text,
          description: _descriptionController.text,
          discount: int.parse(_discountController.text),
          startDate: _selectedStartDate!,
          expiryDate: _selectedExpiryDate!,
          imageUrl: imageUrl,
          imagePublicId: imagePublicId,
          status: 'active',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            debugPrint('Back button pressed');
            Navigator.of(context).pop();
          },
        ),
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
                    TextFormField(
                      controller: _termsController,
                      decoration: const InputDecoration(labelText: 'Terms'),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter terms';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          },
                          items: _categories.map<DropdownMenuItem<String>>((String value) {
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
                      controller: _startDateController,
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedStartDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedStartDate = picked;
                            _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _expiryDateController,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedExpiryDate = picked;
                            _expiryDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an expiry date';
                        }
                        return null;
                      },
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
