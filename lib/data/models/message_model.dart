import 'package:flutter/material.dart';

class Message {
  final String text;
  final bool isMine;
  final TimeOfDay time;
  final bool isDelivered;

  Message({
    required this.text,
    required this.isMine,
    required this.time,
    required this.isDelivered,
  });

  Message copyWith({bool? isDelivered}) {
    return Message(
      text: text,
      isMine: isMine,
      time: time,
      isDelivered: isDelivered ?? this.isDelivered,
    );
  }

  factory Message.fromMap(Map<String, dynamic> m) {
    TimeOfDay time = TimeOfDay.now();
    if (m['sent_at'] != null) {
      try {
        final dt = DateTime.parse(m['sent_at'].toString());
        time = TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (_) {}
    }
    final isMine = (m['is_mine'] is int)
        ? (m['is_mine'] as int) == 1
        : m['is_mine'] == true;
    final isDelivered = (m['is_delivered'] is int)
        ? (m['is_delivered'] as int) == 1
        : m['is_delivered'] == true;
    return Message(
      text: m['message_content']?.toString() ?? '',
      isMine: isMine,
      time: time,
      isDelivered: isDelivered,
    );
  }
}
