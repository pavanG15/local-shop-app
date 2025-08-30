import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_shop_app/models/offer_model.dart';
import 'package:local_shop_app/models/app_user_model.dart';
import 'package:local_shop_app/models/paginated_offers.dart'; // Import PaginatedOffers
import 'package:local_shop_app/services/cloudinary_service.dart'; // Import CloudinaryService

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService(); // Initialize CloudinaryService

  // --- Offer Operations ---

  Stream<PaginatedOffers> getUserOffersStream(
    String ownerId, {
    String? category,
    String? searchQuery,
    String? sortOption,
    DocumentSnapshot? startAfterDoc,
    int limit = 10,
  }) {
    Query query = _db.collection('offers').where('ownerId', isEqualTo: ownerId);

    // Filter by category
    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    // Apply sorting for Firestore query (only one field can be ordered directly)
    // For complex sorting, in-memory sorting will be used after fetching.
    String orderByField = 'expiryDate'; // Default sort
    bool descending = true;

    switch (sortOption) {
      case 'oldest':
        orderByField = 'expiryDate';
        descending = false;
        break;
      case 'highest_discount':
        orderByField = 'discount';
        descending = true;
        break;
      case 'lowest_discount':
        orderByField = 'discount';
        descending = false;
        break;
      case 'newest':
      default:
        orderByField = 'expiryDate';
        descending = true;
        break;
    }
    query = query.orderBy(orderByField, descending: descending);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }
    query = query.limit(limit + 1); // Fetch one extra document to check if there's more

    return query.snapshots().map((snapshot) {
      final docs = snapshot.docs;
      final hasMore = docs.length > limit;
      final actualDocs = hasMore ? docs.take(limit).toList() : docs;

      List<Offer> offers = actualDocs
          .map((doc) => Offer.fromFirestore(doc))
          .toList();

      // Apply search filter in-memory
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerCaseSearchQuery = searchQuery.toLowerCase();
        offers = offers.where((offer) {
          return offer.title.toLowerCase().contains(lowerCaseSearchQuery);
        }).toList();
      }

      return PaginatedOffers(
        offers: offers,
        lastDocument: hasMore ? actualDocs.last : null,
        hasMore: hasMore,
      );
    });
  }

  // New method to get all user offers for analytics (without pagination/search/sort)
  Stream<List<Offer>> getAllUserOffersForAnalytics(String ownerId) {
    return _db
        .collection('offers')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Offer.fromFirestore(doc))
            .toList());
  }

  Stream<List<Offer>> getActiveOffers({
    String? category,
    String? searchQuery,
  }) {
    Query query = _db.collection('offers');

    // Filter by active offers (expiryDate >= today)
    query = query.where('expiryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()));

    // Filter by category
    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    // Sort by expiryDate (soonest first)
    // query = query.orderBy('expiryDate');

    return query.snapshots().map((snapshot) {
      List<Offer> offers = snapshot.docs
          .map((doc) => Offer.fromFirestore(doc))
          .toList();

      // Apply search filter in-memory for now, as Firestore doesn't support
      // case-insensitive search or OR queries directly without extensive indexing.
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerCaseSearchQuery = searchQuery.toLowerCase();
        offers = offers.where((offer) {
          return offer.title.toLowerCase().contains(lowerCaseSearchQuery) ||
                 offer.shopName.toLowerCase().contains(lowerCaseSearchQuery);
        }).toList();
      }
      
      // Sort offers by expiry date in-memory
      offers.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      
      return offers;
    });
  }

  Future<void> addOffer(Offer offer) async {
    await _db.collection('offers').add(offer.toFirestore());
  }

  Future<void> updateOffer(Offer offer) async {
    await _db.collection('offers').doc(offer.offerId).update(offer.toFirestore());
  }

  Future<void> deleteOffer(String offerId, {String? imagePublicId}) async {
    // Delete image from Cloudinary via webhook if publicId is provided
    if (imagePublicId != null) {
      await _cloudinaryService.deleteImage(imagePublicId);
    }
    await _db.collection('offers').doc(offerId).delete();
  }

  // New function to purge expired offers
  Future<void> purgeExpiredOffers() async {
    final now = DateTime.now();
    final expiredOffersSnapshot = await _db.collection('offers')
        .where('expiryDate', isLessThan: now)
        .get();

    for (final doc in expiredOffersSnapshot.docs) {
      final offer = Offer.fromFirestore(doc);
      // Delete image from Cloudinary via webhook if publicId is provided
      if (offer.imagePublicId != null) {
        await _cloudinaryService.deleteImage(offer.imagePublicId!);
      }
      await doc.reference.delete();
    }
    print('Purged ${expiredOffersSnapshot.size} expired offers.');
  }

  // --- User Operations ---

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> createUserData(String uid, String email, String role, {String? shopName, String? category, String? name, String? phone, String? photoUrl}) async {
    await _db.collection('users').doc(uid).set(AppUser(
      uid: uid,
      email: email,
      role: role,
      shopName: shopName,
      category: category,
      name: name,
      phone: phone,
      photoUrl: photoUrl,
    ).toFirestore());
  }

  Future<void> updateProfile(String uid, {String? name, String? phone, String? photoUrl}) async {
    Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await updateUserData(uid, data);
  }
}
