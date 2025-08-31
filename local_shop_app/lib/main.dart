import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_shop_app/services/auth_service.dart';
import 'package:local_shop_app/firebase_options.dart';
import 'package:local_shop_app/screens/signup_screen.dart';
import 'package:local_shop_app/screens/business_owner_dashboard_screen.dart';
import 'package:local_shop_app/screens/user_home_screen.dart';
import 'package:local_shop_app/screens/main_navigation_screen.dart';
import 'package:local_shop_app/services/auth_service.dart';
import 'package:local_shop_app/services/firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Shop App',
      theme: ThemeData(
        // Define the color palette
        primaryColor: const Color(0xFF6C63FF), // Indigo Purple
        hintColor: const Color(0xFF00C9A7),    // Teal Green
        scaffoldBackgroundColor: const Color(0xFFF9FAFB), // Light Gray
        cardColor: Colors.white,

        // Define text theme
        textTheme: const TextTheme(
          // Use your specified text colors here
        ),

        // Define button theme
        buttonTheme: const ButtonThemeData(
          buttonColor: Color(0xFF6C63FF), // Primary color background
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),

        // Define an elevated button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, // Text color
            backgroundColor: const Color(0xFF6C63FF), // Background color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Define Chip Theme
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF9FAFB), // Light Gray
          selectedColor: const Color(0xFF6C63FF), // Active state with primary color
          secondarySelectedColor: const Color(0xFF6C63FF),
          labelStyle: const TextStyle(color: Colors.black),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        ),

        // Define a color scheme to use the colors consistently
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF6C63FF),
          secondary: const Color(0xFF00C9A7),
          error: const Color(0xFFFF4B5C),
          surface: Colors.white,
          background: const Color(0xFFF9FAFB),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Authentication Error: ${snapshot.error}')),
          );
        }

        final User? user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        // Run background cleanup for expired offers
        FirestoreService().purgeExpiredOffers().catchError((e) {
          // Log error in production app
        });

        return FutureBuilder<String?>(
          future: AuthService().getUserRole(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (roleSnapshot.hasError) {
              return Scaffold(
                body: Center(child: Text('Role Error: ${roleSnapshot.error}')),
              );
            }
            if (!roleSnapshot.hasData) {
              return const LoginScreen();
            }

            final role = roleSnapshot.data;

            if (role == 'business') {
              return const BusinessOwnerDashboardScreen();
            } else {
              return const MainNavigationScreen();
            }
          },
        );
      },
    );
  }
}


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _showLoginPage = true; // To toggle between login and signup

  void toggleView() {
    setState(() {
      _showLoginPage = !_showLoginPage;
    });
  }

  Future<void> _signIn() async {
    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    User? user = await _authService.signInWithGoogle();
    if (user != null) {
      // AuthWrapper will handle redirection based on role
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showLoginPage) {
      return Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: const ValueKey('login_form'),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to your account',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Semantics(
                    label: 'Email input field',
                    child: TextFormField(
                      key: const ValueKey('email_field'),
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'Password input field',
                    child: TextFormField(
                      key: const ValueKey('password_field'),
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      autocorrect: false,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    label: 'Login button',
                    button: true,
                    child: ElevatedButton(
                      key: const ValueKey('login_button'),
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'Sign up link',
                    link: true,
                    child: TextButton(
                      key: const ValueKey('signup_link'),
                      onPressed: () {
                        toggleView();
                      },
                      child: const Text('Need an account? Sign Up'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    label: 'Google sign in button',
                    button: true,
                    child: OutlinedButton.icon(
                      key: const ValueKey('google_button'),
                      onPressed: _signInWithGoogle,
                      icon: Image.asset(
                        'assets/google_logo.png',
                        height: 24.0,
                        width: 24.0,
                      ),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return SignupScreen(toggleView: toggleView);
    }
  }
}
