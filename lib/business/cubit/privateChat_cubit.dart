import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/business/cubit/privateChat_state.dart';
import 'package:projectdemo/data/model/message_model.dart';
import 'package:projectdemo/data/local/database_helper.dart';

class PrivateChatCubit extends Cubit<PrivateChatState> {
  final int? networkId;

  PrivateChatCubit({
    this.networkId,
    required String name,
    required String status,
  }) : super(
          PrivateChatState(
            messages: [],
            recipientName: name,
            recipientStatus: status,
          ),
        ) {
    // asynchronously load recent messages from local DB
    Future.microtask(() => _loadInitialMessages());
  }

  Future<void> _loadInitialMessages() async {
    try {
      final msgs = await DatabaseHelper.instance.fetchRecentMessages(
        networkId: networkId,
        limit: 50,
      );
      emit(state.copyWith(messages: msgs));
    } catch (e) {
      print('Failed to load messages: $e');
    }
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final newMessage = Message(
      text: text,
      isMine: true,
      time: TimeOfDay.now(),
      isDelivered: false, // Start as not delivered
    );

    final updatedMessages = List<Message>.from(state.messages)..add(newMessage);
    
    emit(state.copyWith(messages: updatedMessages));


    Future.delayed(const Duration(seconds: 1), () {
      final deliveredMessage = newMessage.copyWith(isDelivered: true);
      final index = updatedMessages.length - 1;
      
      // Replace the message with the delivered one
      updatedMessages[index] = deliveredMessage;
      
      emit(state.copyWith(messages: updatedMessages));
    });
  }

  // a received message from the other user
  void receiveMessage(String text) {
    final receivedMessage = Message(
      text: text,
      isMine: false,
      time: TimeOfDay.now(),
      isDelivered: true,
    );
    final updatedMessages = List<Message>.from(state.messages)..add(receivedMessage);
    emit(state.copyWith(messages: updatedMessages));
  }
}
