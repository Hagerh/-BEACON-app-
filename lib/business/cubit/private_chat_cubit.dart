import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/services/p2p_service.dart';
import 'package:projectdemo/data/models/message_model.dart';
import 'package:projectdemo/data/local/database_helper.dart';
import 'package:projectdemo/core/services/device_id_service.dart';
import 'package:projectdemo/business/cubit/private_chat_state.dart';

class PrivateChatCubit extends Cubit<PrivateChatState> {
  final P2PService p2pService;
  StreamSubscription<Message>? _messageSubscription;

  /// Optionally provide [networkId] and [currentDeviceId] so messages can be persisted.
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
         ),
       ) {
    _loadHistory();
    _startListeningToMessages();
  }

  // Start listening to incoming messages from P2P service
  void _startListeningToMessages() {
    _messageSubscription = p2pService.messagesStream.listen(
      (message) {
        _receiveMessage(message);
        _persistIncomingMessage(message);
      },
      onError: (error) {
        print('Error receiving message: $error');
      },
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final newMessage = Message(
      text: text,
      isMine: true,
      time: TimeOfDay.now(),
      isDelivered: false, // Will be set to true when ACK arrives
    );

    final updatedMessages = List<Message>.from(state.messages)..add(newMessage);

    emit(state.copyWith(messages: updatedMessages));

    try {
      // Persist outgoing message first so we have a local message id to send
      final localId = await _persistOutgoingMessage(newMessage);

      // Send via P2P service and include local message id so recipient can ACK
      p2pService.sendPrivate(state.recipientDeviceId, text, localMessageId: localId);

      // Optimistically mark delivered in UI after a short delay (ACK will update DB for real)
      Future.delayed(const Duration(milliseconds: 300), () {
        final deliveredMessage = newMessage.copyWith(isDelivered: true);

        final index = updatedMessages.length - 1;

        if (index >= 0 && index < updatedMessages.length) {
          updatedMessages[index] = deliveredMessage;

          emit(state.copyWith(messages: List.from(updatedMessages)));
        }
      });
    } catch (e) {
      print('Failed to send message: $e');

      // Optionally mark message as failed
    }
  }
  // Receive a message from the P2P service

  void _receiveMessage(Message message) {
    final updatedMessages = List<Message>.from(state.messages)..add(message);
    emit(state.copyWith(messages: updatedMessages));
  }

  Future<void> _loadHistory() async {
    // Load recent messages for this chat from DB if network id is known
    try {
      final db = DatabaseHelper.instance;

      // Ensure we have a local currentDeviceId for proper persistence
      if (state.currentDeviceId == null) {
        final id = await DeviceIdService.getDeviceId();
        emit(state.copyWith(currentDeviceId: id));
      }

      final msgs = await db.fetchRecentMessages(
        networkId: state.networkId,
        forDeviceId: state.recipientDeviceId,
        limit: 100,
      );

      if (msgs.isNotEmpty) {
        emit(state.copyWith(messages: List.from(msgs)));
      }

      // Reset unread count for this peer when opening chat
      try {
        await db.resetDeviceUnread(state.recipientDeviceId);
      } catch (_) {}
    } catch (e) {
      // ignore - failure to read history should not crash chat
      print('Failed to load chat history: $e');
    }
  }

  Future<void> _persistIncomingMessage(Message message) async {
    try {
      final db = DatabaseHelper.instance;
      if (state.networkId == null) return;

      await db.insertMessage(
        networkId: state.networkId!,
        senderDeviceId: message.senderDeviceId,
        receiverDeviceId: message.receiverDeviceId ?? state.currentDeviceId,
        messageContent: message.text,
        isMine: message.isMine,
        isDelivered: message.isDelivered,
      );
    } catch (e) {
      print('Failed to persist incoming message: $e');
    }
  }

  Future<int> _persistOutgoingMessage(Message message) async {
    try {
      final db = DatabaseHelper.instance;
      if (state.networkId == null) return -1;

      final id = await db.insertMessage(
        networkId: state.networkId!,
        senderDeviceId: state.currentDeviceId,
        receiverDeviceId: state.recipientDeviceId,
        messageContent: message.text,
        isMine: true,
        isDelivered: false,
      );

      return id;
    } catch (e) {
      print('Failed to persist outgoing message: $e');
      return -1;
    }
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