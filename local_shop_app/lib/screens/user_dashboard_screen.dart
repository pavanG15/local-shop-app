import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_shop_app/models/offer_model.dart';
import 'package:local_shop_app/services/auth_service.dart';
import 'package:local_shop_app/services/firestore_service.dart';
import 'package:local_shop_app/screens/edit_offer_screen.dart'; // Assuming this exists
import 'package:shimmer/shimmer.dart'; // Import shimmer package

import 'package:local_shop_app/screens/add_offer_screen.dart'; // Import for "Add Product" button
import 'package:local_shop_app/screens/profile_screen.dart'; // Import ProfileScreen

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  User? _currentUser;

  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Grocery',
    'Restaurant',
    'Clothing',
    'Electronics',
    'Other',
  ];

  String _selectedSortOption = 'newest'; // 'newest', 'oldest', 'highest_discount', 'lowest_discount'
  final Map<String, String> _sortOptions = {
    'newest': 'Newest First',
    'oldest': 'Oldest First',
    'highest_discount': 'Highest Discount',
    'lowest_discount': 'Lowest Discount',
  };

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Pagination variables
  List<Offer> _offers = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _offersPerPage = 10;
  final ScrollController _scrollController = ScrollController();

  // Analytics variables
  int _totalProducts = 0;
  int _activeProducts = 0;
  double _averageDiscount = 0.0;
  String _mostPopularCategory = 'N/A';

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.getCurrentUser();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _resetPagination(); // Reset pagination on search/filter change
      });
    });
    _scrollController.addListener(_onScroll);
    _fetchInitialOffers();
    _fetchAnalytics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetPagination() {
    setState(() {
      _offers = [];
      _lastDocument = null;
      _hasMore = true;
      _isLoadingMore = false;
    });
    _fetchInitialOffers();
  }

  void _fetchInitialOffers() {
    if (_currentUser == null) return;
    _firestoreService.getUserOffersStream(
      _currentUser!.uid,
      category: _selectedCategory == 'All' ? null : _selectedCategory,
      searchQuery: _searchQuery,
      sortOption: _selectedSortOption,
      limit: _offersPerPage,
    ).listen((paginatedOffers) {
      if (mounted) {
        setState(() {
          _offers = paginatedOffers.offers;
          _lastDocument = paginatedOffers.lastDocument;
          _hasMore = paginatedOffers.hasMore;
        });
      }
    });
  }

  void _loadMoreOffers() async {
    if (_isLoadingMore || !_hasMore || _currentUser == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    _firestoreService.getUserOffersStream(
      _currentUser!.uid,
      category: _selectedCategory == 'All' ? null : _selectedCategory,
      searchQuery: _searchQuery,
      sortOption: _selectedSortOption,
      startAfterDoc: _lastDocument,
      limit: _offersPerPage,
    ).listen((paginatedOffers) {
      if (mounted) {
        setState(() {
          _offers.addAll(paginatedOffers.offers);
          _lastDocument = paginatedOffers.lastDocument;
          _hasMore = paginatedOffers.hasMore;
          _isLoadingMore = false;
        });
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreOffers();
    }
  }

  void _fetchAnalytics() {
    if (_currentUser == null) return;
    _firestoreService.getAllUserOffersForAnalytics(_currentUser!.uid).listen((allOffers) {
      if (mounted) {
        setState(() {
          _totalProducts = allOffers.length;
          _activeProducts = allOffers.where((offer) => offer.expiryDate.isAfter(DateTime.now())).length;

          if (allOffers.isNotEmpty) {
            _averageDiscount = allOffers.map((offer) => offer.discount).reduce((a, b) => a + b) / allOffers.length;

            final categoryCounts = <String, int>{};
            for (var offer in allOffers) {
              categoryCounts[offer.category] = (categoryCounts[offer.category] ?? 0) + 1;
            }
            _mostPopularCategory = categoryCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
          } else {
            _averageDiscount = 0.0;
            _mostPopularCategory = 'N/A';
          }
        });
      }
    });
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
        title: const Text('User Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            debugPrint('Back button pressed');
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              debugPrint('Logout button pressed');
              await _authService.signOut();
              if (mounted) {
                // Navigate to login or home screen after logout
                Navigator.of(context).pushReplacementNamed('/'); // Adjust route as needed
              }
            },
          ),
        ],
      ),
      body: _currentUser == null
          ? const Center(child: Text('Please log in to view your dashboard.'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: _currentUser!.photoURL != null
                            ? NetworkImage(_currentUser!.photoURL!)
                            : null,
                        child: _currentUser!.photoURL == null
                            ? const Icon(Icons.account_circle, size: 80)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentUser!.displayName ?? 'User Name',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              _currentUser!.email ?? 'user@example.com',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.settings),
                              label: const Text('Manage Profile'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Analytics Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Analytics',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: screenWidth > 600 ? 2 : 1,
                        childAspectRatio: screenWidth > 600 ? 2.5 : 3.5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildStatCard('Total Products', _totalProducts.toString(), Icons.inventory_2),
                          _buildStatCard('Active Products', _activeProducts.toString(), Icons.check_circle_outline),
                          _buildStatCard('Avg. Discount', '${_averageDiscount.toStringAsFixed(0)}%', Icons.percent),
                          _buildStatCard('Top Category', _mostPopularCategory, Icons.category),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Your Products',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                // Filter, Sort, and Search Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search products by title',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                isDense: true,
                                labelText: 'Category',
                              ),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedCategory = newValue!;
                                  _resetPagination();
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSortOption,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                isDense: true,
                                labelText: 'Sort By',
                              ),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedSortOption = newValue!;
                                  _resetPagination();
                                });
                              },
                              items: _sortOptions.entries.map<DropdownMenuItem<String>>((entry) {
                                return DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(entry.value),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // User Products List
                Expanded(
                  child: _offers.isEmpty && !_isLoadingMore && !_hasMore
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 100, color: Colors.grey[400]),
                              const SizedBox(height: 20),
                              Text(
                                'No products yet!',
                                style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Looks like you haven\'t added any products.',
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton.icon(
                                onPressed: () {
                                  debugPrint('Add Offer button pressed');
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const AddOfferScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add_business),
                                label: const Text('Create Your First Product'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  textStyle: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                            childAspectRatio: 0.75, // Adjust as needed
                          ),
                          itemCount: _offers.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _offers.length) {
                              if (_isLoadingMore) {
                                return Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(width: double.infinity, height: 16.0, color: Colors.white),
                                              const SizedBox(height: 4),
                                              Container(width: 100.0, height: 14.0, color: Colors.white),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(child: Container(height: 36.0, color: Colors.white)),
                                                  const SizedBox(width: 8),
                                                  Expanded(child: Container(height: 36.0, color: Colors.white)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                    child: _hasMore
                                        ? ElevatedButton(
                                            onPressed: _loadMoreOffers,
                                            child: const Text('Load More'),
                                          )
                                        : const Text('No more products'),
                                  ),
                                );
                              }
                            }
                            final offer = _offers[index];
                            return ProductCard(
                              offer: offer,
                              onEdit: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EditOfferScreen(offer: offer),
                                  ),
                                );
                              },
                              onDelete: () => _confirmDelete(context, offer),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Offer offer) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "${offer.title}"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteOffer(offer.offerId, imagePublicId: offer.imagePublicId);
        if (mounted) {
          _showSnackBar(context, 'Product "${offer.title}" deleted successfully!');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar(context, 'Failed to delete product: $e', isError: true);
        }
      }
    }
  }
}

class ProductCard extends StatefulWidget {
  final Offer offer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.offer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Card(
        elevation: _isHovering ? 8 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  children: [
                    Image.network(
                      widget.offer.imageUrl ?? 'https://via.placeholder.com/150', // Default image if null
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                              onPressed: () {
                                debugPrint('Edit Product button pressed');
                                widget.onEdit();
                              },
                              tooltip: 'Edit Product',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                              onPressed: () {
                                debugPrint('Delete Product button pressed');
                                widget.onDelete();
                              },
                              tooltip: 'Delete Product',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.offer.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Discount: ${widget.offer.discount}%', // Assuming discount is a percentage
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  // Removed original buttons as quick actions are added
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
