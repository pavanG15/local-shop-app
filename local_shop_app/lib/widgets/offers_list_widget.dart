import 'package:flutter/material.dart';

class OffersListWidget extends StatelessWidget {
  final List<Map<String, String>> offers = [
    {
      "title": "Special Discount",
      "description": "Get 20% off on all electronics.",
      "discount": "20%",
      "shopName": "ElectroShop",
      "image":
          "https://via.placeholder.com/300x180.png?text=Electronics+Offer",
    },
    {
      "title": "Fashion Sale",
      "description": "Flat 40% off on selected fashion items.",
      "discount": "40%",
      "shopName": "StyleHub",
      "image":
          "https://via.placeholder.com/300x180.png?text=Fashion+Sale",
    },
    {
      "title": "Grocery Bonanza",
      "description": "Buy 1 Get 1 Free on groceries.",
      "discount": "B1G1",
      "shopName": "FreshMart",
      "image":
          "https://via.placeholder.com/300x180.png?text=Grocery+Offer",
    },
  ];

  OffersListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // breakpoint
        bool isMobile = constraints.maxWidth < 600;
        int crossAxisCount = isMobile ? 1 : (constraints.maxWidth > 1000 ? 3 : 2);

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isMobile ? 0.75 : 0.85,
          ),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            return _OfferCard(
              title: offer["title"]!,
              description: offer["description"]!,
              discount: offer["discount"]!,
              shopName: offer["shopName"] ?? '',
              imageUrl: offer["image"]!,
              isMobile: isMobile,
            );
          },
        );
      },
    );
  }
}

class _OfferCard extends StatefulWidget {
  final String title;
  final String description;
  final String discount;
  final String shopName;
  final String imageUrl;
  final bool isMobile;

  const _OfferCard({
    required this.title,
    required this.description,
    required this.discount,
    required this.shopName,
    required this.imageUrl,
    required this.isMobile,
  });

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered && !widget.isMobile
            ? (Matrix4.identity()..scale(1.03))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: _isHovered ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                widget.imageUrl,
                height: widget.isMobile ? 180 : 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Container(
                  height: 150,
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),

            // content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.shopName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Discount: ${widget.discount}",
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: widget.isMobile
                          ? Alignment.center
                          : Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(
                            widget.isMobile ? double.infinity : 120,
                            40,
                          ),
                        ),
                        child: const Text("View Details"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
