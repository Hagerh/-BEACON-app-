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
      (message) async {
        // Only handle messages FROM the current chat peer
        // (not TO them - those are our outgoing messages)
        if (message.senderDeviceId != state.recipientDeviceId) {
          return; // Ignore messages from other peers
        }

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
      isDelivered: true, // Always delivered immediately in P2P
    );

    try {
      // Persist outgoing message first so we have a local message id to send
      final localId = await _persistOutgoingMessage(newMessage);

      if (localId == -1) {
        // Persistence failed, add message without id so user still sees it
        final updatedMessages = List<Message>.from(state.messages)
          ..add(newMessage);
        emit(state.copyWith(messages: updatedMessages));
        return;
      }

      // Add persisted message (with id) to UI
      final saved = newMessage.copyWith(messageId: localId);
      final updatedMessages = List<Message>.from(state.messages)..add(saved);
      emit(state.copyWith(messages: updatedMessages));

      // Send via P2P service
      p2pService.sendPrivate(state.recipientDeviceId, text);
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

      // Determine networkId: prefer state, otherwise try to resolve from sender
      int? networkId = state.networkId;

      // Ensure we have a local currentDeviceId for proper persistence
      String? currentId = state.currentDeviceId;
      if (currentId == null) {
        currentId = await DeviceIdService.getDeviceId();
        emit(state.copyWith(currentDeviceId: currentId));
      }

      // Peer id should come from the message sender if available
      final peerId = message.senderDeviceId ?? state.recipientDeviceId;

      // Try to resolve network id if we don't have one yet
      if (networkId == null && peerId != null) {
        networkId = await db.getNetworkIdByDeviceId(peerId);
      }

      // If we still don't know the network, we cannot persist safely
      if (networkId == null) return message;

      // Ensure the sender (peer) exists in Devices table so FK constraint won't fail
      try {
        await db.upsertDevice(
          deviceId: peerId!,
          networkId: networkId,
          name: peerId,
          status: 'Active',
        );
      } catch (_) {}

      // Ensure local device exists in Devices table too
      try {
        final localUser = await db.getUserProfile(currentId!);
        final localName = localUser?.name ?? 'Local Device';
        await db.upsertDevice(
          deviceId: currentId,
          networkId: networkId,
          name: localName,
          status: 'Active',
        );
      } catch (_) {}

      final id = await db.insertMessage(
        networkId: networkId,
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
    _messageSubscription = null;
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();

    return super.close();
  }
}
