import 'package:flutter/material.dart';
import 'package:local_shop_app/models/offer_model.dart';
import 'package:intl/intl.dart';

class OfferCardWidget extends StatelessWidget {
  final Offer offer;
  final VoidCallback onTap;
  final bool isSaved;
  final VoidCallback? onBookmarkToggle;
  final VoidCallback? onShare;

  const OfferCardWidget({
    super.key,
    required this.offer,
    required this.onTap,
    this.isSaved = false,
    this.onBookmarkToggle,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4.0,
      child: InkWell(
        onTap: () {
          debugPrint('Offer card tapped: ${offer.title}');
          onTap();
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with aspect 4:3
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                    child: offer.imageUrl != null
                        ? Image.network(
                            offer.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.image_not_supported, size: 40),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image_not_supported, size: 40),
                          ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Top-left badge
                  Positioned(
                    top: 8.0,
                    left: 8.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E), // Green for discounts
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${offer.discount}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  // Top-right bookmark
                  if (onBookmarkToggle != null)
                    Positioned(
                      top: 8.0,
                      right: 8.0,
                      child: IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? Theme.of(context).primaryColor : Colors.white,
                        ),
                        onPressed: () {
                          debugPrint('Bookmark button pressed');
                          onBookmarkToggle?.call();
                        },
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    offer.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Shop name
                  Text(
                    offer.shopName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6B6B6B),
                        ),
                  ),
                  const SizedBox(height: 8),
                  // Distance / Expiry
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Expires: ${DateFormat('dd/MM/yyyy').format(offer.expiryDate)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B6B6B),
                            ),
                      ),
                      // Share icon
                      if (onShare != null)
                        IconButton(
                          icon: const Icon(Icons.share, size: 20),
                          onPressed: () {
                            debugPrint('Share button pressed');
                            onShare?.call();
                          },
                          color: const Color(0xFF6B6B6B),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}