import 'package:flutter/foundation.dart';
import 'package:projectdemo/data/models/message_model.dart';

@immutable
class PrivateChatState {
  final List<Message> messages;
  final String recipientName;
  final String recipientDeviceId;
  final String recipientStatus;
  final int? networkId;
  final String? currentDeviceId;
  final bool isLoading;

  const PrivateChatState({
    required this.messages,
    required this.recipientName,
    required this.recipientDeviceId,
    required this.recipientStatus,
    this.networkId,
    this.currentDeviceId,
    this.isLoading = false,
  });

  PrivateChatState copyWith({
    List<Message>? messages,
    String? recipientName,
    String? recipientDeviceId,
    String? recipientStatus,
    int? networkId,
    String? currentDeviceId,
    bool? isLoading,
  }) {
    return PrivateChatState(
      messages: messages ?? this.messages,
      recipientName: recipientName ?? this.recipientName,
      recipientDeviceId: recipientDeviceId ?? this.recipientDeviceId,
      recipientStatus: recipientStatus ?? this.recipientStatus,
      networkId: networkId ?? this.networkId,
      currentDeviceId: currentDeviceId ?? this.currentDeviceId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
