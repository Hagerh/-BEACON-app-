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
  StreamSubscription<DeliveryUpdate>? _deliverySubscription;

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

    // Listen for delivery ACKs and update UI state
    _deliverySubscription = p2pService.deliveryStream.listen((update) {
      _handleDeliveryUpdate(update);
    });
  }

  // Start listening to incoming messages from P2P service
  void _startListeningToMessages() {
    _messageSubscription = p2pService.messagesStream.listen(
      (message) async {
        try {
          final persisted = await _persistIncomingMessage(message);

          // Add the persisted message (with messageId) to state
          _receiveMessage(persisted);
        } catch (e) {
          // If persistence failed, still show message without id
          _receiveMessage(message);
        }
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

    try {
      // Persist outgoing message first so we have a local message id to send
      final localId = await _persistOutgoingMessage(newMessage);

      if (localId == -1) {
        // Persistence failed, add message without id so user still sees it
        final updatedMessages = List<Message>.from(state.messages)..add(newMessage);
        emit(state.copyWith(messages: updatedMessages));
        return;
      }

      // Add persisted message (with id) to UI
      final saved = newMessage.copyWith(messageId: localId);
      final updatedMessages = List<Message>.from(state.messages)..add(saved);
      emit(state.copyWith(messages: updatedMessages));

      // Send via P2P service and include local message id so recipient can ACK
      p2pService.sendPrivate(state.recipientDeviceId, text, localMessageId: localId);
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
      String? currentId = state.currentDeviceId;
      if (currentId == null) {
        currentId = await DeviceIdService.getDeviceId();
        emit(state.copyWith(currentDeviceId: currentId));
      }

      final msgs = await db.fetchRecentMessages(
        networkId: state.networkId,
        peerDeviceId: state.recipientDeviceId,
        currentDeviceId: currentId,
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

  Future<Message> _persistIncomingMessage(Message message) async {
    try {
      final db = DatabaseHelper.instance;
      if (state.networkId == null) return message;

      // Ensure we have a local currentDeviceId for proper persistence
      String? currentId = state.currentDeviceId;
      if (currentId == null) {
        currentId = await DeviceIdService.getDeviceId();
        emit(state.copyWith(currentDeviceId: currentId));
      }

      // Use the chat's peer/current IDs so history queries line up
      final peerId = state.recipientDeviceId;

      final id = await db.insertMessage(
        networkId: state.networkId!,
        senderDeviceId: peerId,
        receiverDeviceId: currentId,
        messageContent: message.text,
        isMine: false,
        isDelivered: message.isDelivered,
      );

      return message.copyWith(
        messageId: id,
        senderDeviceId: peerId,
        receiverDeviceId: currentId,
      );
    } catch (e) {
      print('Failed to persist incoming message: $e');
      return message;
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
    _deliverySubscription?.cancel();

    _messageSubscription = null;
    _deliverySubscription = null;
  }

  void _handleDeliveryUpdate(DeliveryUpdate update) {
    final index = state.messages.indexWhere((m) => m.messageId == update.messageId);
    if (index == -1) return;

    final updated = List<Message>.from(state.messages);
    final msg = updated[index].copyWith(isDelivered: update.delivered);
    updated[index] = msg;

    emit(state.copyWith(messages: updated));
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _deliverySubscription?.cancel();

    return super.close();
  }
}