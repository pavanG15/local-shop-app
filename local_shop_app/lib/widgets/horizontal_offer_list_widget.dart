import 'package:flutter/material.dart';
import 'package:local_shop_app/models/offer_model.dart';
import 'package:local_shop_app/screens/offer_detail_screen.dart';

class HorizontalOfferListWidget extends StatelessWidget {
  final List<Offer> offers;
  final String title;

  const HorizontalOfferListWidget({
    super.key,
    required this.offers,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 180.0,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Container(
                width: 150.0,
                margin: const EdgeInsets.only(right: 12.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 3.0,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => OfferDetailScreen(offer: offer),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 4:3 aspect ratio image
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                            child: offer.imageUrl != null
                                ? Image.network(
                                    offer.imageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFFF3F4F6),
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 30,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFFF3F4F6),
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 30,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Discount badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${offer.discount}% OFF',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Title
                              Text(
                                offer.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.0,
                                  color: Color(0xFF1F2937),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Shop name
                              Text(
                                offer.shopName,
                                style: const TextStyle(
                                  fontSize: 11.0,
                                  color: Color(0xFF6B7280),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}