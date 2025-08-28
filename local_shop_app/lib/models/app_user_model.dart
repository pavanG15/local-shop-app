import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String role; // 'customer' or 'business'
  final String? shopName; // For business owners
  final String? category; // For business owners

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.shopName,
    this.category,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'customer', // Default to customer
      shopName: data['shopName'],
      category: data['category'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role,
      'shopName': shopName,
      'category': category,
    };
  }
}
