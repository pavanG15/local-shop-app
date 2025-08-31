import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_shop_app/models/offer_model.dart';
import 'package:local_shop_app/services/auth_service.dart';
import 'package:local_shop_app/services/firestore_service.dart';
import 'package:local_shop_app/screens/offer_detail_screen.dart';
import 'package:local_shop_app/widgets/offer_card_widget.dart';
import 'package:local_shop_app/widgets/offer_card_skeleton_widget.dart';

class SavedOffersScreen extends StatefulWidget {
  const SavedOffersScreen({super.key});

  @override
  State<SavedOffersScreen> createState() => _SavedOffersScreenState();
}

class _SavedOffersScreenState extends State<SavedOffersScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  User? _currentUser;
  List<String> _savedOfferIds = [];
  List<Offer> _savedOffers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.getCurrentUser();
    _loadSavedOffers();
  }

  Future<void> _loadSavedOffers() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final appUser = await _authService.getAppUser(_currentUser!.uid);
      setState(() {
        _savedOfferIds = appUser?.savedOffers ?? [];
      });
    } catch (e) {
      print('Error loading saved offers: $e');
      setState(() {
        _savedOfferIds = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleBookmark(String offerId) async {
    if (_currentUser == null) return;

    try {
      if (_savedOfferIds.contains(offerId)) {
        await _firestoreService.unsaveOffer(_currentUser!.uid, offerId);
        setState(() {
          _savedOfferIds.remove(offerId);
          _savedOffers.removeWhere((offer) => offer.offerId == offerId);
        });
      } else {
        await _firestoreService.saveOffer(_currentUser!.uid, offerId);
        // Reload to get the offer details
        _loadSavedOffers();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating bookmark: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 1;
    if (screenWidth > 1200) {
      crossAxisCount = 4;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
    } else if (screenWidth > 600) {
      crossAxisCount = 2;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Offers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            debugPrint('Back button pressed');
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _currentUser == null
          ? const Center(child: Text('Please log in to view saved offers'))
          : StreamBuilder<List<Offer>>(
              stream: _firestoreService.getSavedOffers(_currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingView(crossAxisCount);
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final savedOffers = snapshot.data ?? [];

                if (savedOffers.isEmpty) {
                  return _buildEmptyView();
                }

                return _buildOffersGrid(crossAxisCount, savedOffers);
              },
            ),
    );
  }

  Widget _buildLoadingView(int crossAxisCount) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const OfferCardSkeletonWidget(),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No saved offers yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the ❤️ icon on any offer to save it here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              debugPrint('Browse Offers button pressed');
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.explore),
            label: const Text('Browse Offers'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersGrid(int crossAxisCount, List<Offer> offers) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.75,
      ),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        return OfferCardWidget(
          offer: offer,
          isSaved: true, // All offers in this screen are saved
          onBookmarkToggle: () => _toggleBookmark(offer.offerId),
          onShare: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share functionality coming soon!')),
            );
          },
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => OfferDetailScreen(offer: offer),
              ),
            );
          },
        );
      },
    );
  }
}