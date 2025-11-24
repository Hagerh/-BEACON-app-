

import 'package:flutter/material.dart';
import 'package:projectdemo/data/model/message_model.dart';

@immutable
class PrivateChatState {
  final List<Message> messages;
  final String recipientName;
  final String recipientStatus;

  const PrivateChatState({
    required this.messages,
    required this.recipientName,
    required this.recipientStatus,
  });

  PrivateChatState copyWith({
    List<Message>? messages,
    String? recipientName,
    String? recipientStatus,
  }) {
    return PrivateChatState(
      messages: messages ?? this.messages,
      recipientName: recipientName ?? this.recipientName,
      recipientStatus: recipientStatus ?? this.recipientStatus,
    );
  }
}