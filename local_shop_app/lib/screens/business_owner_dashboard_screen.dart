import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_shop_app/models/offer_model.dart';
import 'package:local_shop_app/services/firestore_service.dart';
import 'package:local_shop_app/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:local_shop_app/screens/add_offer_screen.dart';
import 'package:local_shop_app/screens/edit_offer_screen.dart';
import 'package:local_shop_app/screens/profile_screen.dart';
import 'package:local_shop_app/widgets/responsive_offers_grid_widget.dart';

class BusinessOwnerDashboardScreen extends StatefulWidget {
  const BusinessOwnerDashboardScreen({super.key});

  @override
  State<BusinessOwnerDashboardScreen> createState() => _BusinessOwnerDashboardScreenState();
}

class _BusinessOwnerDashboardScreenState extends State<BusinessOwnerDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.getCurrentUser();
    _purgeExpiredOffers(); // Call purge function on init
  }

  // New method to purge expired offers
  Future<void> _purgeExpiredOffers() async {
    try {
      await _firestoreService.purgeExpiredOffers();
    } catch (e) {
      print('Error purging expired offers: $e');
      // Optionally show a snackbar or log to a crash reporting service
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: Text('Please log in to view your dashboard.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddOfferScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: ResponsiveOffersGridWidget(ownerId: _currentUser!.uid),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Offer offer) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offer'),
        content: Text('Are you sure you want to delete "${offer.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteOffer(offer.offerId, imagePublicId: offer.imagePublicId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer deleted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete offer: $e')),
        );
      }
    }
  }
}
