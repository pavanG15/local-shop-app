import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_shop_app/models/app_user_model.dart';
import 'package:local_shop_app/services/auth_service.dart';
import 'package:local_shop_app/services/firestore_service.dart';
import 'package:local_shop_app/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  AppUser? _appUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    User? user = _authService.getCurrentUser();
    if (user != null) {
      _appUser = await _firestoreService.getUser(user.uid);
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(appUser: _appUser),
                ),
              );
              if (result == true) {
                _loadUserProfile(); // Reload profile after editing
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appUser == null
              ? const Center(child: Text('Failed to load profile'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _appUser!.photoUrl != null
                            ? NetworkImage(_appUser!.photoUrl!)
                            : null,
                        child: _appUser!.photoUrl == null
                            ? const Icon(Icons.account_circle, size: 120)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _appUser!.name ?? 'No name set',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _appUser!.email,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (_appUser!.phone != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _appUser!.phone!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Details',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              ListTile(
                                leading: const Icon(Icons.email),
                                title: const Text('Email'),
                                subtitle: Text(_appUser!.email),
                              ),
                              if (_appUser!.phone != null)
                                ListTile(
                                  leading: const Icon(Icons.phone),
                                  title: const Text('Phone'),
                                  subtitle: Text(_appUser!.phone!),
                                ),
                              ListTile(
                                leading: const Icon(Icons.calendar_today),
                                title: const Text('Member Since'),
                                subtitle: Text(
                                  _appUser!.createdAt != null
                                      ? '${_appUser!.createdAt!.day}/${_appUser!.createdAt!.month}/${_appUser!.createdAt!.year}'
                                      : 'N/A',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
