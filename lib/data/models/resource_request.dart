class ResourceRequest {
  final String resourceId;
  final String offerId;
  final String requestorDeviceId;
  final String requestorName;
  final int quantity;

  ResourceRequest({
    required this.resourceId,
    required this.offerId,
    required this.requestorDeviceId,
    required this.requestorName,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    "type": "resource_request",
    "resourceId": resourceId,
    "offerId": offerId,
    "requestorDeviceId": requestorDeviceId,
    "requestorName": requestorName,
    "quantity": quantity,
  };

  static ResourceRequest fromJson(Map<String, dynamic> json) => ResourceRequest(
    resourceId: json["resourceId"],
    offerId: json["offerId"],
    requestorDeviceId: json["requestorDeviceId"],
    requestorName: json["requestorName"],
    quantity: json["quantity"],
  );
}
