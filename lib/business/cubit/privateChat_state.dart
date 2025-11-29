import 'package:flutter/foundation.dart';
import 'package:projectdemo/data/model/message_model.dart';

@immutable
class PrivateChatState {
  final List<Message> messages;
  final String recipientName;
  final String recipientDeviceId;
  final String recipientStatus;

  const PrivateChatState({
    required this.messages,
    required this.recipientName,
    required this.recipientDeviceId,
    required this.recipientStatus,
  });

  PrivateChatState copyWith({
    List<Message>? messages,
    String? recipientName,
    String? recipientDeviceId,
    String? recipientStatus,
  }) {
    return PrivateChatState(
      messages: messages ?? this.messages,
      recipientName: recipientName ?? this.recipientName,
      recipientDeviceId: recipientDeviceId ?? this.recipientDeviceId,
      recipientStatus: recipientStatus ?? this.recipientStatus,
    );
  }
}