import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_shop_app/models/offer_model.dart';
import 'package:local_shop_app/services/firestore_service.dart';
import 'package:local_shop_app/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:local_shop_app/screens/add_offer_screen.dart';
import 'package:local_shop_app/screens/edit_offer_screen.dart';

class BusinessOwnerDashboardScreen extends StatefulWidget {
  const BusinessOwnerDashboardScreen({Key? key}) : super(key: key);

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
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddOfferScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Offer>>(
        stream: _firestoreService.getOffersForBusinessOwner(_currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No offers created yet. Click + to add one!'));
          }

          final offers = snapshot.data!;
          return ListView.builder(
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Shop: ${offer.shopName}'),
                      Text('Discount: ${offer.discount}%'),
                      Text('Expires: ${DateFormat('yyyy-MM-dd').format(offer.expiryDate)}'),
                      if (offer.imageUrl != null && offer.imageUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Image.network(
                            offer.imageUrl!,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => EditOfferScreen(offer: offer),
                                ),
                              );
                            },
                            child: const Text('Edit'),
                          ),
                          TextButton(
                            onPressed: () => _confirmDelete(context, offer),
                            child: const Text('Delete'),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
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
