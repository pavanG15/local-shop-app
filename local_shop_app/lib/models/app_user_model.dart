import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String role; // 'customer' or 'business'
  final String? shopName; // For business owners
  final String? category; // For business owners
  final String? name; // Customer name
  final String? phone; // Phone number
  final String? photoUrl; // Profile picture URL
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.shopName,
    this.category,
    this.name,
    this.phone,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'customer', // Default to customer
      shopName: data['shopName'],
      category: data['category'],
      name: data['name'],
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role,
      'shopName': shopName,
      'category': category,
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
