import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/services/p2p_service.dart';
import 'package:projectdemo/data/models/message_model.dart';
import 'package:projectdemo/data/models/resource_request.dart';
import 'package:projectdemo/data/local/database_helper.dart';
import 'package:projectdemo/core/services/device_id_service.dart';
import 'package:projectdemo/business/cubit/private_chat/private_chat_state.dart';

class PrivateChatCubit extends Cubit<PrivateChatState> {
  final P2PService p2pService;
  StreamSubscription<Message>? _messageSubscription;
  final BuildContext context; // Needed for dialogs

  PrivateChatCubit({
    required this.p2pService,
    required this.context,
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

  // -----------------------------
  // Message listener
  // -----------------------------
  void _startListeningToMessages() {
    _messageSubscription = p2pService.messagesStream.listen(
      (message) async {
        // Only handle messages FROM the current chat peer
        // (not TO them - those are our outgoing messages)
        debugPrint(
          "🥰Received message in PrivateChatCubit: ${message.text} from ${message.senderDeviceId} and!! ${state.recipientDeviceId}",
        );
        if (message.senderDeviceId != state.recipientDeviceId) {
          return; // Ignore messages from other peers
        }

        try {
          // If the message is JSON and contains a type, handle as special request
          if (_isJson(message.text)) {
            final data = jsonDecode(message.text);
            if (data.containsKey('type')) {
              handleIncomingMessage(message.text, context);
              return;
            }
          }

          // Normal chat message
          final persisted = await _persistIncomingMessage(message);
          _receiveMessage(persisted);
        } catch (e) {
          _receiveMessage(message);
        }
      },
      onError: (error) {
        print('Error receiving message: $error');
      },
    );
  }

  // -----------------------------
  // Sending normal chat messages
  // -----------------------------
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final newMessage = Message(
      text: text,
      isMine: true,
      time: TimeOfDay.now(),
      isDelivered: true,
    );

    try {
      final localId = await _persistOutgoingMessage(newMessage);

      final saved = localId != -1
          ? newMessage.copyWith(messageId: localId)
          : newMessage;
      final updatedMessages = List<Message>.from(state.messages)..add(saved);
      emit(state.copyWith(messages: updatedMessages));

      // Send via P2P
      p2pService.sendPrivate(state.recipientDeviceId, text);
    } catch (e) {
      print('Failed to send message: $e');
    }
  }

  void _receiveMessage(Message message) {
    final updatedMessages = List<Message>.from(state.messages)..add(message);
    emit(state.copyWith(messages: updatedMessages));
  }

  // -----------------------------
  // Resource request handling
  // -----------------------------
  void handleIncomingMessage(String messageJson, BuildContext context) {
    final Map<String, dynamic> data = jsonDecode(messageJson);

    switch (data['type']) {
      case 'resource_request':
        final request = ResourceRequest.fromJson(data);
        _showResourceRequestDialog(context, request);
        break;

      case 'resource_request_approved':
        _receiveMessage(
          Message(
            text: "Your request for ${data['resourceId']} was approved!",
            isMine: false,
            time: TimeOfDay.now(),
            isDelivered: true, // <-- add this
          ),
        );
        break;

      case 'resource_request_rejected':
        _receiveMessage(
          Message(
            text: "Your request for ${data['resourceId']} was rejected.",
            isMine: false,
            time: TimeOfDay.now(),
            isDelivered: true, // <-- add this
          ),
        );
        break;

      default:
        // normal chat
        _receiveMessage(
          Message(
            text: data['text'] ?? '',
            isMine: false,
            time: TimeOfDay.now(),
            isDelivered: true,
            senderDeviceId: data['senderDeviceId'],
            receiverDeviceId: data['receiverDeviceId'],
          ),
        );
    }
  }

  void _showResourceRequestDialog(
    BuildContext context,
    ResourceRequest request,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Resource Request"),
        content: Text(
          "${request.requestorName} requests ${request.quantity} of ${request.resourceId}",
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Reject
              p2pService.sendResourceResponse(request.requestorDeviceId, {
                "type": "resource_request_rejected",
                "resourceId": request.resourceId,
                "offerId": request.offerId,
              });
              Navigator.pop(context);
            },
            child: const Text("Reject"),
          ),
          TextButton(
            onPressed: () {
              // Approve
              p2pService.sendResourceResponse(request.requestorDeviceId, {
                "type": "resource_request_approved",
                "resourceId": request.resourceId,
                "offerId": request.offerId,
                "quantity": request.quantity,
              });
              Navigator.pop(context);
            },
            child: const Text("Approve"),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // History persistence
  // -----------------------------
  Future<void> _loadHistory() async {
    try {
      final db = DatabaseHelper.instance;

      String? currentId =
          state.currentDeviceId ?? await DeviceIdService.getDeviceId();
      emit(state.copyWith(currentDeviceId: currentId));

      final msgs = await db.fetchRecentMessages(
        peerDeviceId: state.recipientDeviceId,
        currentDeviceId: currentId,
        limit: 100,
      );

      if (msgs.isNotEmpty) {
        emit(state.copyWith(messages: List.from(msgs)));
      }
    } catch (e) {
      print('Failed to load chat history: $e');
    }
  }

  Future<Message> _persistIncomingMessage(Message message) async {
    try {
      final db = DatabaseHelper.instance;
      int? networkId = state.networkId;
      String? currentId =
          state.currentDeviceId ?? await DeviceIdService.getDeviceId();
      emit(state.copyWith(currentDeviceId: currentId));

      final peerId = message.senderDeviceId ?? state.recipientDeviceId;
      if (networkId == null) {
        networkId = await db.getNetworkIdByDeviceId(peerId!);
      }
      if (networkId == null) return message;

      await db.upsertDevice(
        deviceId: peerId!,
        networkId: networkId,
        name: peerId,
        status: 'Active',
      );
      final localName =
          (await db.getUserProfile(currentId!))?.name ?? 'Local Device';
      await db.upsertDevice(
        deviceId: currentId,
        networkId: networkId,
        name: localName,
        status: 'Active',
      );

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

      return await db.insertMessage(
        networkId: state.networkId!,
        senderDeviceId: state.currentDeviceId,
        receiverDeviceId: state.recipientDeviceId,
        messageContent: message.text,
        isMine: true,
        isDelivered: false,
      );
    } catch (e) {
      print('Failed to persist outgoing message: $e');
      return -1;
    }
  }

  // -----------------------------
  // Utility
  // -----------------------------
  bool _isJson(String str) {
    try {
      jsonDecode(str);
      return true;
    } catch (_) {
      return false;
    }
  }

  // -----------------------------
  // Cleanup
  // -----------------------------
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
