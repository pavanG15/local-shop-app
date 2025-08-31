import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_shop_app/models/offer_model.dart';
import 'package:local_shop_app/services/firestore_service.dart';
import 'package:local_shop_app/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:local_shop_app/screens/add_offer_screen.dart';
import 'package:local_shop_app/screens/edit_offer_screen.dart';
import 'package:local_shop_app/screens/profile_screen.dart';
import 'package:local_shop_app/screens/offer_detail_screen.dart'; // Import OfferDetailScreen
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
        title: const Text('My Dashboard'),
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
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              debugPrint('Logout button pressed');
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Stats
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<List<Offer>>(
              stream: _firestoreService.getAllUserOffersForAnalytics(_currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final offers = snapshot.data ?? [];
                final now = DateTime.now();
                final activeOffers = offers.where((o) => o.expiryDate.isAfter(now) && o.status == 'active').length;
                final expiredOffers = offers.where((o) => o.expiryDate.isBefore(now)).length;
                final pausedOffers = offers.where((o) => o.status == 'paused').length;
                final views = 0; // Placeholder
                final saves = 0; // Placeholder

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('Active Offers', activeOffers.toString(), Icons.check_circle),
                    _buildStatCard('Expired', expiredOffers.toString(), Icons.cancel),
                    _buildStatCard('Paused', pausedOffers.toString(), Icons.pause),
                    _buildStatCard('Views', views.toString(), Icons.visibility),
                    _buildStatCard('Saves', saves.toString(), Icons.bookmark),
                  ],
                );
              },
            ),
          ),
          // Add New Offer Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                debugPrint('Add Offer button pressed');
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AddOfferScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Offer'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Offers List
          Expanded(
            child: ResponsiveOffersGridWidget(
              ownerId: _currentUser!.uid,
              onEdit: _handleEditOffer,
              onDelete: _handleDeleteOffer,
              onViewDetails: _handleViewDetails,
              onPause: _handlePauseOffer,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint('FAB Add Offer button pressed');
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddOfferScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _handleEditOffer(Offer offer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditOfferScreen(offer: offer),
      ),
    );
  }

  void _handleViewDetails(Offer offer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OfferDetailScreen(offer: offer),
      ),
    );
  }

  Future<void> _handlePauseOffer(Offer offer) async {
    final newStatus = offer.status == 'active' ? 'paused' : 'active';
    try {
      final updatedOffer = Offer(
        offerId: offer.offerId,
        ownerId: offer.ownerId,
        shopName: offer.shopName,
        category: offer.category,
        title: offer.title,
        description: offer.description,
        discount: offer.discount,
        startDate: offer.startDate,
        expiryDate: offer.expiryDate,
        imageUrl: offer.imageUrl,
        imagePublicId: offer.imagePublicId,
        status: newStatus,
      );
      await _firestoreService.updateOffer(updatedOffer);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Offer "${offer.title}" ${newStatus == 'paused' ? 'paused' : 'activated'}!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update offer: $e')),
      );
    }
  }

  Future<void> _handleDeleteOffer(Offer offer) async {
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
