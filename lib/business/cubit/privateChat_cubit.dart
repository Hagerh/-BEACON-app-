import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/business/cubit/privateChat_state.dart';
import 'package:projectdemo/services/p2p_service.dart';
import 'package:projectdemo/data/model/message_model.dart';

class PrivateChatCubit extends Cubit<PrivateChatState> {
  final P2PService p2pService;
  StreamSubscription<Message>? _messageSubscription;

  PrivateChatCubit({
    required this.p2pService,
    required String recipientName,
    required String recipientDeviceId,
    required String recipientStatus,
  }) : super(
         PrivateChatState(
           messages: [],
           recipientName: recipientName,
           recipientDeviceId: recipientDeviceId,
           recipientStatus: recipientStatus,
         ),
       ) {
    _startListeningToMessages();
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

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final newMessage = Message(
      text: text,
      isMine: true,
      time: TimeOfDay.now(),
      isDelivered: false, // Will be updated after sending
    );

    final updatedMessages = List<Message>.from(state.messages)..add(newMessage);

    emit(state.copyWith(messages: updatedMessages));

    // Send via P2P service

    try {
      p2pService.sendPrivate(state.recipientDeviceId, text);

      // Mark as delivered after a brief delay

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
