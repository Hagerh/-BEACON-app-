import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/services/p2p_service.dart';
import 'package:projectdemo/data/models/message_model.dart';
import 'package:projectdemo/data/local/database_helper.dart';
import 'package:projectdemo/business/cubit/private_chat/private_chat_state.dart';

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
        debugPrint(
          "🥰Received message in PrivateChatCubit: ${message.text} from ${message.senderUserId}",
        );

        // Check if message is from the current peer (by user_id)
        // We need to look up the peer's user_id
        try {
          final db = DatabaseHelper.instance;
          final peerProfile = await db.getUserProfile(state.recipientDeviceId);
          if (peerProfile != null &&
              message.senderUserId != peerProfile.userId) {
            return; // Ignore messages from other peers
          }
        } catch (_) {
          // If lookup fails, skip filtering
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
      // Get recipient's userId for P2P transmission
      String? receiverUserId;
      try {
        final db = DatabaseHelper.instance;
        final recipientProfile = await db.getUserProfile(
          state.recipientDeviceId,
        );
        receiverUserId = recipientProfile?.userId;
      } catch (_) {}

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

      // Send via P2P service with receiverUserId
      p2pService.sendPrivate(
        state.recipientDeviceId,
        text,
        receiverUserId: receiverUserId,
      );
    } catch (e) {
      debugPrint('Failed to send message: $e');

      // Optionally mark message as failed
    }
  }
  // Receive a message from the P2P service

  void _receiveMessage(Message message) {
    final updatedMessages = List<Message>.from(state.messages)..add(message);
    emit(state.copyWith(messages: updatedMessages));
  }

  Future<void> _loadHistory() async {
    // Load recent messages for this chat from DB
    try {
      final db = DatabaseHelper.instance;

      // Get current user's userId
      String? currentUserId = p2pService.currentUser?.userId;

      // Get peer's userId from their device_id
      String? peerUserId;
      final peerProfile = await db.getUserProfile(state.recipientDeviceId);
      peerUserId = peerProfile?.userId;

      if (currentUserId != null && peerUserId != null) {
        final msgs = await db.fetchRecentMessages(
          currentUserId: currentUserId,
          peerUserId: peerUserId,
          limit: 100,
        );

        if (msgs.isNotEmpty) {
          emit(state.copyWith(messages: List.from(msgs)));
        }
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

      // Get user IDs
      String? senderUserId = message.senderUserId;
      String? receiverUserId = message.receiverUserId;

      // If not in message, try to look up from database using device IDs
      if (senderUserId == null) {
        final senderProfile = await db.getUserProfile(state.recipientDeviceId);
        senderUserId = senderProfile?.userId;
      }
      if (receiverUserId == null) {
        // Get current user's userId from P2P service
        receiverUserId = p2pService.currentUser?.userId;
      }

      // Can't persist without sender
      if (senderUserId == null) {
        debugPrint("❌ Cannot persist incoming message: senderUserId is null");
        return message;
      }

      final id = await db.insertMessage(
        senderUserId: senderUserId,
        receiverUserId: receiverUserId,
        messageContent: message.text,
        isMine: false,
        isDelivered: message.isDelivered,
      );

      debugPrint(
        "✅ Persisted incoming message: id=$id, sender=$senderUserId, receiver=$receiverUserId",
      );

      return message.copyWith(
        messageId: id,
        senderUserId: senderUserId,
        receiverUserId: receiverUserId,
      );
    } catch (e) {
      debugPrint('❌ Failed to persist incoming message: $e');
      return message;
    }
  }

  Future<int> _persistOutgoingMessage(Message message) async {
    try {
      final db = DatabaseHelper.instance;

      // Get current user's userId
      String? senderUserId = p2pService.currentUser?.userId;
      if (senderUserId == null && state.currentDeviceId != null) {
        final senderProfile = await db.getUserProfile(state.currentDeviceId!);
        senderUserId = senderProfile?.userId;
      }

      // Get recipient's userId
      String? receiverUserId = message.receiverUserId;
      if (receiverUserId == null) {
        final recipientProfile = await db.getUserProfile(
          state.recipientDeviceId,
        );
        receiverUserId = recipientProfile?.userId;
      }

      if (senderUserId == null) {
        debugPrint("❌ Cannot persist outgoing message: senderUserId is null");
        return -1; // Can't persist without sender
      }

      final id = await db.insertMessage(
        senderUserId: senderUserId,
        receiverUserId: receiverUserId,
        messageContent: message.text,
        isMine: true,
        isDelivered: false,
      );

      debugPrint(
        "✅ Persisted outgoing message: id=$id, sender=$senderUserId, receiver=$receiverUserId",
      );
      return id;
    } catch (e) {
      debugPrint('❌ Failed to persist outgoing message: $e');
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
