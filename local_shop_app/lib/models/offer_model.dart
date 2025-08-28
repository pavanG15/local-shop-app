import 'package:cloud_firestore/cloud_firestore.dart';

class Offer {
  final String offerId;
  final String ownerId;
  final String shopName;
  final String category;
  final String title;
  final String description;
  final int discount;
  final DateTime expiryDate;
  final String? imageUrl;
  final String? imagePublicId; // Cloudinary public ID

  Offer({
    required this.offerId,
    required this.ownerId,
    required this.shopName,
    required this.category,
    required this.title,
    required this.description,
    required this.discount,
    required this.expiryDate,
    this.imageUrl,
    this.imagePublicId,
  });

  factory Offer.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Offer(
      offerId: doc.id,
      ownerId: data['ownerId'] ?? '',
      shopName: data['shopName'] ?? '',
      category: data['category'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      discount: data['discount'] ?? 0,
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
      imagePublicId: data['imagePublicId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'shopName': shopName,
      'category': category,
      'title': title,
      'description': description,
      'discount': discount,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'imageUrl': imageUrl,
      'imagePublicId': imagePublicId,
    };
  }
}
