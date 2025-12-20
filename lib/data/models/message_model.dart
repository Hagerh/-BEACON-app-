import 'package:flutter/material.dart';

class Message {
  final int? messageId;
  final String? senderUserId; // Permanent user ID
  final String? receiverUserId; // Permanent user ID (null for broadcast)
  final String text;
  final bool isMine;
  final TimeOfDay time;
  final DateTime? sentAt;
  final bool isDelivered;

  Message({
    this.messageId,
    this.senderUserId,
    this.receiverUserId,
    required this.text,
    required this.isMine,
    required this.time,
    this.sentAt,
    required this.isDelivered,
  });

  Message copyWith({
    bool? isDelivered,
    int? messageId,
    String? senderUserId,
    String? receiverUserId,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      senderUserId: senderUserId ?? this.senderUserId,
      receiverUserId: receiverUserId ?? this.receiverUserId,
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
      'sender_user_id': senderUserId,
      'receiver_user_id': receiverUserId,
      'message_content': text,
      'is_mine': isMine ? 1 : 0,
      'is_delivered': isDelivered ? 1 : 0,
      'sent_at':
          sentAt?.toIso8601String() ??
          DateTime(
            now.year,
            now.month,
            now.day,
            time.hour,
            time.minute,
          ).toIso8601String(),
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
      senderUserId: m['sender_user_id']?.toString(),
      receiverUserId: m['receiver_user_id']?.toString(),
      text: m['message_content']?.toString() ?? '',
      isMine: isMine,
      time: time,
      sentAt: sentAt,
      isDelivered: isDelivered,
    );
  }
}
