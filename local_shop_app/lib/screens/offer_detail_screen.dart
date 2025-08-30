import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:local_shop_app/models/offer_model.dart';

class OfferDetailScreen extends StatelessWidget {
  final Offer offer;

  const OfferDetailScreen({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(offer.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (offer.imageUrl != null && offer.imageUrl!.isNotEmpty)
              Center(
                child: Image.network(
                  offer.imageUrl!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              offer.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${offer.discount}% OFF',
              style: TextStyle(fontSize: 20, color: Colors.green[700], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Shop: ${offer.shopName}', style: const TextStyle(fontSize: 16)),
            Text('Category: ${offer.category}', style: const TextStyle(fontSize: 16)),
            Text('Expires: ${DateFormat('yyyy-MM-dd').format(offer.expiryDate)}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text(
              'Description:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              offer.description,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
