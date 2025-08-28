import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_shop_app/services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  final Function toggleView;
  const SignupScreen({Key? key, required this.toggleView}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final AuthService _authService = AuthService();

  String _selectedRole = 'customer'; // Default role
  String? _businessCategory; // For business owners

  final List<String> _businessCategories = [
    'Grocery',
    'Restaurant',
    'Clothing',
    'Electronics',
    'Other',
  ];

  Future<void> _register() async {
    try {
      if (_passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password should be at least 6 characters.')),
        );
        return;
      }

      if (_selectedRole == 'business' && _businessCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a business category.')),
        );
        return;
      }

      await _authService.registerWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
        shopName: _selectedRole == 'business' ? _shopNameController.text : null,
        category: _selectedRole == 'business' ? _businessCategory : null,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedRole,
              hint: const Text('Sign up as'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRole = newValue!;
                });
              },
              items: const <String>['customer', 'business']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value == 'customer' ? 'Customer' : 'Business Owner'),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (_selectedRole == 'business') ...[
              TextField(
                controller: _shopNameController,
                decoration: const InputDecoration(labelText: 'Shop / Business Name'),
              ),
              DropdownButtonFormField<String>(
                value: _businessCategory,
                hint: const Text('Business Category'),
                onChanged: (String? newValue) {
                  setState(() {
                    _businessCategory = newValue!;
                  });
                },
                items: _businessCategories
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: const Text('Sign Up'),
            ),
            TextButton(
              onPressed: () {
                widget.toggleView();
              },
              child: const Text('Already have an account? Login'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _signInWithGoogle,
              icon: Image.asset(
                'assets/google_logo.png',
                height: 24.0,
              ),
              label: const Text('Sign in with Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
