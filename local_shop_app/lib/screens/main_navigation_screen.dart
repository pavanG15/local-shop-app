import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_shop_app/screens/user_home_screen.dart';
import 'package:local_shop_app/screens/saved_offers_screen.dart';
import 'package:local_shop_app/screens/profile_screen.dart';
import 'package:local_shop_app/widgets/bottom_navigation_widget.dart';
import 'package:local_shop_app/widgets/top_bar_widget.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Widget> get _screens => [
    UserHomeScreen(searchQuery: _searchQuery),
    const SavedOffersScreen(),
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // Gesture handling
      },
      child: Scaffold(
        appBar: _currentIndex == 0
            ? TopBarWidget(
                searchController: _searchController,
                onSearchChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
              )
            : _currentIndex == 1
                ? AppBar(
                    title: const Text('Saved Offers'),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: _signOut,
                        tooltip: 'Sign Out',
                      ),
                    ],
                  )
                : AppBar(
                    title: const Text('Profile'),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: _signOut,
                        tooltip: 'Sign Out',
                      ),
                    ],
                  ),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationWidget(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}