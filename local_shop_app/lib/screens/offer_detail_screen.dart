import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:local_shop_app/models/offer_model.dart';
import 'package:local_shop_app/services/auth_service.dart';
import 'package:local_shop_app/services/firestore_service.dart';
import 'package:local_shop_app/models/app_user_model.dart';
import 'package:share_plus/share_plus.dart';

class OfferDetailScreen extends StatefulWidget {
  final Offer offer;

  const OfferDetailScreen({super.key, required this.offer});

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  AppUser? _shopOwner;

  @override
  void initState() {
    super.initState();
    _loadShopDetails();
  }

  Future<void> _loadShopDetails() async {
    _shopOwner = await _authService.getAppUser(widget.offer.ownerId);
    setState(() {});
  }

  void _saveOffer() async {
    debugPrint('Save button pressed');
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save offers')),
      );
      return;
    }

    try {
      await _firestoreService.saveOffer(currentUser.uid, widget.offer.offerId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save offer: $e')),
      );
    }
  }

  void _shareOffer() {
    debugPrint('Share button pressed');
    final String shareText = '''
Check out this amazing offer!

${widget.offer.title}
${widget.offer.discount}% OFF at ${widget.offer.shopName}

Description: ${widget.offer.description}

Expires: ${widget.offer.expiryDate != null ? DateFormat('yyyy-MM-dd').format(widget.offer.expiryDate!) : 'No expiry date'}

Shared from Local Shop App
''';

    Share.share(shareText, subject: 'Great offer from ${widget.offer.shopName}');
  }

  void _redeemOffer() {
    debugPrint('Redeem button pressed');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redeem Offer'),
        content: const Text('Show this screen to the shop owner to redeem the offer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building OfferDetailScreen for offer: ${widget.offer.title}');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.offer.title ?? 'Offer Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            debugPrint('Back button pressed from OfferDetailScreen');
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large image with error handling
            if (widget.offer.imageUrl != null && widget.offer.imageUrl!.isNotEmpty)
              Center(
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.offer.imageUrl!,
                      height: 300,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Error loading offer image: $error');
                        return Container(
                          height: 300,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Image not available', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              )
            else
              Center(
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No image available', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Title, description, discount info
            Text(
              widget.offer.title ?? 'Untitled Offer',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.offer.discount ?? 0}% OFF',
              style: TextStyle(fontSize: 20, color: Colors.green[700], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.offer.description ?? 'No description available',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            // Shop details
            const Text(
              'Shop Details:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Name: ${widget.offer.shopName ?? 'Unknown Shop'}', style: const TextStyle(fontSize: 16)),
            Text('Category: ${widget.offer.category ?? 'Uncategorized'}', style: const TextStyle(fontSize: 16)),
            if (_shopOwner != null && _shopOwner!.phone != null && _shopOwner!.phone!.isNotEmpty)
              Text('Contact: ${_shopOwner!.phone}', style: const TextStyle(fontSize: 16)),
            // Placeholder for address
            const Text('Address: 123 Main St, City, Country', style: TextStyle(fontSize: 16)),
            Text('Expires: ${widget.offer.expiryDate != null ? DateFormat('yyyy-MM-dd').format(widget.offer.expiryDate!) : 'No expiry date'}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 32),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _saveOffer,
                  icon: const Icon(Icons.bookmark),
                  label: const Text('Save'),
                ),
                ElevatedButton.icon(
                  onPressed: _shareOffer,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
                ElevatedButton.icon(
                  onPressed: _redeemOffer,
                  icon: const Icon(Icons.redeem),
                  label: const Text('Redeem'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
