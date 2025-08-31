import 'package:cloud_firestore/cloud_firestore.dart';

class Offer {
  final String offerId;
  final String ownerId;
  final String shopName;
  final String category;
  final String title;
  final String description;
  final int discount;
  final DateTime startDate;
  final DateTime expiryDate;
  final String? imageUrl;
  final String? imagePublicId; // Cloudinary public ID
  final String status; // 'active', 'paused', 'expired'

  Offer({
    required this.offerId,
    required this.ownerId,
    required this.shopName,
    required this.category,
    required this.title,
    required this.description,
    required this.discount,
    required this.startDate,
    required this.expiryDate,
    this.imageUrl,
    this.imagePublicId,
    this.status = 'active',
  });

  factory Offer.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    print('Offer.fromFirestore: Raw data for doc ${doc.id}: $data');
    final offer = Offer(
      offerId: doc.id,
      ownerId: data['ownerId'] ?? '',
      shopName: data['shopName'] ?? '',
      category: data['category'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      discount: data['discount'] ?? 0,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'],
      imagePublicId: data['imagePublicId'],
      status: data['status'] ?? 'active',
    );
    print('Offer.fromFirestore: Constructed Offer: ${offer.toJson()}');
    return offer;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'shopName': shopName,
      'category': category,
      'title': title,
      'description': description,
      'discount': discount,
      'startDate': Timestamp.fromDate(startDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'imageUrl': imageUrl,
      'imagePublicId': imagePublicId,
      'status': status,
    };
  }

  // Added for debugging purposes
  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId,
      'ownerId': ownerId,
      'shopName': shopName,
      'category': category,
      'title': title,
      'description': description,
      'discount': discount,
      'startDate': startDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'imageUrl': imageUrl,
      'imagePublicId': imagePublicId,
      'status': status,
    };
  }
}
