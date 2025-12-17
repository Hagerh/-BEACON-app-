import 'package:flutter/material.dart';

class Message {
  final int? messageId;
  final int? networkId;
  final String? senderDeviceId;
  final String? receiverDeviceId;
  final String text;
  final bool isMine;
  final TimeOfDay time;
  final DateTime? sentAt;
  final bool isDelivered;

  Message({
    this.messageId,
    this.networkId,
    this.senderDeviceId,
    this.receiverDeviceId,
    required this.text,
    required this.isMine,
    required this.time,
    this.sentAt,
    required this.isDelivered,
  });

  Message copyWith({
    bool? isDelivered,
    int? messageId,
    int? networkId,
    String? senderDeviceId,
    String? receiverDeviceId,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      networkId: networkId ?? this.networkId,
      senderDeviceId: senderDeviceId ?? this.senderDeviceId,
      receiverDeviceId: receiverDeviceId ?? this.receiverDeviceId,
      text: text,
      isMine: isMine,
      time: time,
      sentAt: sentAt,
      isDelivered: isDelivered ?? this.isDelivered,
    );
  }

  /// Convert to map for database insertion
  Map<String, dynamic> toMap() {
    final now = DateTime.now();
    return {
      if (messageId != null) 'message_id': messageId,
      if (networkId != null) 'network_id': networkId,
      'sender_device_id': senderDeviceId,
      'receiver_device_id': receiverDeviceId,
      'message_content': text,
      'is_mine': isMine ? 1 : 0,
      'is_delivered': isDelivered ? 1 : 0,
      'sent_at': sentAt?.toIso8601String() ??
          DateTime(now.year, now.month, now.day, time.hour, time.minute)
              .toIso8601String(),
    };
  }

  factory Message.fromMap(Map<String, dynamic> m) {
    TimeOfDay time = TimeOfDay.now();
    DateTime? sentAt;
    if (m['sent_at'] != null) {
      try {
        sentAt = DateTime.parse(m['sent_at'].toString());
        time = TimeOfDay(hour: sentAt.hour, minute: sentAt.minute);
      } catch (_) {}
    }
    final isMine = (m['is_mine'] is int)
        ? (m['is_mine'] as int) == 1
        : m['is_mine'] == true;
    final isDelivered = (m['is_delivered'] is int)
        ? (m['is_delivered'] as int) == 1
        : m['is_delivered'] == true;
    return Message(
      messageId: m['message_id'] as int?,
      networkId: m['network_id'] as int?,
      senderDeviceId: m['sender_device_id']?.toString(),
      receiverDeviceId: m['receiver_device_id']?.toString(),
      text: m['message_content']?.toString() ?? '',
      isMine: isMine,
      time: time,
      sentAt: sentAt,
      isDelivered: isDelivered,
    );
  }
}
