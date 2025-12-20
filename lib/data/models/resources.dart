import 'resource_offer.dart';

class ResourceItem {
  final String resourceId; // NEW: globally unique ID
  final String name;
  final String category;
  final String ownerDeviceId; // NEW: owner device ID
  int version; // NEW: for conflict resolution
  final List<ResourceOffer> offers;

  ResourceItem({
    required this.resourceId,
    required this.name,
    required this.category,
    required this.ownerDeviceId,
    this.version = 1,
    required this.offers,
  });

  int get totalQuantity => offers.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toJson() => {
    "resourceId": resourceId,
    "name": name,
    "category": category,
    "ownerDeviceId": ownerDeviceId,
    "version": version,
    "offers": offers.map((o) => o.toJson()).toList(),
  };

  factory ResourceItem.fromJson(Map<String, dynamic> json) {
    return ResourceItem(
      resourceId: json["resourceId"],
      name: json["name"],
      category: json["category"],
      ownerDeviceId: json["ownerDeviceId"],
      version: json["version"],
      offers: (json["offers"] as List)
          .map((e) => ResourceOffer.fromJson(e))
          .toList(),
    );
  }
}
