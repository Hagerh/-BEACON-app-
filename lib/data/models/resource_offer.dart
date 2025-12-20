class ResourceOffer {
  final String offerId; // UUID
  final String providerDeviceId; // device ID of provider
  final String providerName;
  int quantity;

  ResourceOffer({
    required this.offerId,
    required this.providerDeviceId,
    required this.providerName,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    "offerId": offerId,
    "providerDeviceId": providerDeviceId,
    "providerName": providerName,
    "quantity": quantity,
  };

  factory ResourceOffer.fromJson(Map<String, dynamic> json) {
    return ResourceOffer(
      offerId: json["offerId"],
      providerDeviceId: json["providerDeviceId"],
      providerName: json["providerName"],
      quantity: json["quantity"],
    );
  }
}
