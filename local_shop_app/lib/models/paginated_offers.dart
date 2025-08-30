import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_shop_app/models/offer_model.dart';

class PaginatedOffers {
  final List<Offer> offers;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  PaginatedOffers({
    required this.offers,
    this.lastDocument,
    required this.hasMore,
  });
}
