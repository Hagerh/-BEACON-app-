import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/services/p2p_service.dart';
import 'package:projectdemo/data/local/database_helper.dart';
import 'package:projectdemo/data/models/message_model.dart';
import 'package:projectdemo/business/cubit/private_chat_state.dart';

class PrivateChatCubit extends Cubit<PrivateChatState> {
  final P2PService p2pService;
  final DatabaseHelper _db = DatabaseHelper.instance;
  StreamSubscription<Message>? _messageSubscription;

  PrivateChatCubit({
    required this.p2pService,
    required String recipientName,
    required String recipientDeviceId,
    required String recipientStatus,
    int? networkId,
    String? currentDeviceId,
  }) : super(
         PrivateChatState(
           messages: [],
           recipientName: recipientName,
           recipientDeviceId: recipientDeviceId,
           recipientStatus: recipientStatus,
           networkId: networkId,
           currentDeviceId: currentDeviceId,
           isLoading: true,
         ),
       ) {
    _initializeChat();
  }

  /// Initialize chat: load message history and start listening
  Future<void> _initializeChat() async {
    await _loadMessageHistory();
    _startListeningToMessages();
    // Reset unread count when opening chat
    await _db.resetUnreadCount(state.recipientDeviceId);
  }

  /// Load message history from database
  Future<void> _loadMessageHistory() async {
    try {
      final messages = await _db.fetchRecentMessages(
        networkId: state.networkId,
        forDeviceId: state.recipientDeviceId,
        limit: 100,
      );
      emit(state.copyWith(messages: messages, isLoading: false));
    } catch (e) {
      print('Failed to load message history: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  // Start listening to incoming messages from P2P service
  void _startListeningToMessages() {
    _messageSubscription = p2pService.messagesStream.listen(
      (message) {
        _receiveMessage(message);
      },
      onError: (error) {
        print('Error receiving message: $error');
      },
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final now = DateTime.now();
    final newMessage = Message(
      networkId: state.networkId ?? 1,
      senderDeviceId: state.currentDeviceId,
      receiverDeviceId: state.recipientDeviceId,
      text: text,
      isMine: true,
      time: TimeOfDay.now(),
      sentAt: now,
      isDelivered: false,
    );

    final updatedMessages = List<Message>.from(state.messages)..add(newMessage);
    emit(state.copyWith(messages: updatedMessages));

    try {
      // Save to database
      final messageId = await _db.insertMessage(newMessage);

      // Send via P2P service
      p2pService.sendPrivate(state.recipientDeviceId, text);

      // Mark as delivered after a brief delay
      Future.delayed(const Duration(milliseconds: 300), () async {
        final deliveredMessage = newMessage.copyWith(
          isDelivered: true,
          messageId: messageId,
        );

        // Update delivery status in database
        await _db.updateMessageDeliveryStatus(messageId, true);

        final index = updatedMessages.length - 1;
        if (index >= 0 && index < updatedMessages.length) {
          updatedMessages[index] = deliveredMessage;
          emit(state.copyWith(messages: List.from(updatedMessages)));
        }
      });
    } catch (e) {
      print('Failed to send message: $e');
    }
  }

  // Receive a message from the P2P service
  Future<void> _receiveMessage(Message message) async {
    // Add network and device info to the message
    final enrichedMessage = Message(
      networkId: state.networkId ?? 1,
      senderDeviceId: state.recipientDeviceId,
      receiverDeviceId: state.currentDeviceId,
      text: message.text,
      isMine: false,
      time: message.time,
      sentAt: DateTime.now(),
      isDelivered: true,
    );

    // Save to database
    try {
      await _db.insertMessage(enrichedMessage);
      // Update last seen for the sender device
      await _db.updateDeviceLastSeen(state.recipientDeviceId);
    } catch (e) {
      print('Failed to save received message: $e');
    }

    final updatedMessages = List<Message>.from(state.messages)..add(enrichedMessage);
    emit(state.copyWith(messages: updatedMessages));
  }

  // Stop listening when closing the chat
  void stopListening() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}
