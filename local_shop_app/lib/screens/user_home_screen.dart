import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_shop_app/models/offer_model.dart';
import 'package:local_shop_app/services/auth_service.dart';
import 'package:local_shop_app/services/firestore_service.dart';
import 'package:local_shop_app/screens/offer_detail_screen.dart';
import 'package:local_shop_app/screens/profile_screen.dart';
import 'package:local_shop_app/widgets/carousel_banner_widget.dart';
import 'package:local_shop_app/widgets/carousel_banner_skeleton_widget.dart';
import 'package:local_shop_app/widgets/horizontal_offer_list_widget.dart';
import 'package:local_shop_app/widgets/top_bar_widget.dart';
import 'package:local_shop_app/widgets/category_chips_widget.dart';
import 'package:local_shop_app/widgets/offer_card_widget.dart';
import 'package:local_shop_app/widgets/offer_card_skeleton_widget.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class UserHomeScreen extends StatefulWidget {
  final String searchQuery;

  const UserHomeScreen({super.key, required this.searchQuery});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  User? _currentUser;
  List<String> _savedOffers = [];

  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Food',
    'Grocery',
    'Fashion',
    'Electronics',
  ];


  @override
  void initState() {
    super.initState();
    _currentUser = _authService.getCurrentUser();
    _loadSavedOffers();
  }

  Future<void> _loadSavedOffers() async {
    if (_currentUser != null) {
      final appUser = await _authService.getAppUser(_currentUser!.uid);
      setState(() {
        _savedOffers = appUser?.savedOffers ?? [];
      });
    }
  }

  void _toggleBookmark(String offerId) async {
    if (_currentUser == null) return;
    if (_savedOffers.contains(offerId)) {
      await _firestoreService.unsaveOffer(_currentUser!.uid, offerId);
      setState(() {
        _savedOffers.remove(offerId);
      });
    } else {
      await _firestoreService.saveOffer(_currentUser!.uid, offerId);
      setState(() {
        _savedOffers.add(offerId);
      });
    }
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  Widget _buildBody() {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;
    if (screenWidth > 1200) {
      crossAxisCount = 4;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
    } else if (screenWidth > 600) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    return StreamBuilder<List<Offer>>(
      key: ValueKey('${_selectedCategory}_${widget.searchQuery}'),
      stream: _firestoreService.getActiveOffers(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        searchQuery: widget.searchQuery,
      ),
      builder: (context, snapshot) {
        print('StreamBuilder - ConnectionState: ${snapshot.connectionState}');
        print('StreamBuilder - Has Error: ${snapshot.hasError}');
        if (snapshot.hasError) {
          print('StreamBuilder - Error: ${snapshot.error}');
          return _buildErrorWidget(snapshot.error.toString());
        }

        final offers = snapshot.data ?? [];
        print('StreamBuilder - Number of offers: ${offers.length}');
        final topOffers = offers.take(4).toList();
        final savedOffersList = offers.where((o) => _savedOffers.contains(o.offerId)).toList();

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner skeleton
                const CarouselBannerSkeletonWidget(),
                // Category Chips
                CategoryChipsWidget(
                  categories: _categories,
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (category) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                ),
                // Nearby Offers skeleton
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text(
                    'Nearby Offers',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: OfferCardSkeletonWidget(),
                    ),
                  ),
                ),
                // Trending Offers
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text(
                    'Trending Offers',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: 6, // Show 6 skeletons
                  itemBuilder: (context, index) => const OfferCardSkeletonWidget(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        } else if (offers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_offer_outlined,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No offers available',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We\'re working hard to bring you the best deals.\nCheck back soon for amazing offers from local businesses!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Refresh the offers by triggering a rebuild
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    // Could navigate to a help or contact screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feature coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Get notified when offers are available'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
        } else {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner
                CarouselBannerWidget(offers: topOffers),
                // Category Chips
                CategoryChipsWidget(
                  categories: _categories,
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (category) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                ),
                // Nearby Offers
                HorizontalOfferListWidget(
                  offers: offers,
                  title: 'Nearby Offers',
                ),
                // Trending Offers
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text(
                    'Trending Offers',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: offers.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    return RepaintBoundary(
                      child: OfferCardWidget(
                        key: ValueKey(offer.offerId),
                        offer: offer,
                        isSaved: _savedOffers.contains(offer.offerId),
                        onBookmarkToggle: () => _toggleBookmark(offer.offerId),
                        onShare: () {
                          final String shareText = '''
Check out this amazing offer!

${offer.title}
${offer.discount}% OFF at ${offer.shopName}

Description: ${offer.description}

Expires: ${DateFormat('yyyy-MM-dd').format(offer.expiryDate)}

Shared from Local Shop App
''';

                          Share.share(shareText, subject: 'Great offer from ${offer.shopName}');
                        },
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => OfferDetailScreen(offer: offer),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                // Saved Offers
                if (savedOffersList.isNotEmpty)
                  HorizontalOfferListWidget(
                    offers: savedOffersList,
                    title: 'Saved Offers',
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        }
      },
    );
  }
}
