import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/business/cubit/privateChat_state.dart';
import 'package:projectdemo/data/model/message_model.dart';

class PrivateChatCubit extends Cubit<PrivateChatState> {
  PrivateChatCubit({
    required String name,
    required String status,
  }) : super(
          PrivateChatState(
            messages: _initialMessages,
            recipientName: name,
            recipientStatus: status,
          ),
        );

  // Initial dummy messages 
  static final List<Message> _initialMessages = [
    Message(
      text: 'Hey! Are you safe?',
      isMine: false,
      time: TimeOfDay(hour: 10, minute: 30),
      isDelivered: true,
    ),
    Message(
      text: 'Yes, I\'m okay. Just staying indoors.',
      isMine: true,
      time:  TimeOfDay(hour: 10, minute: 32),
      isDelivered: true,
    ),
    Message(
      text: 'Good to hear! Do you need any supplies?',
      isMine: false,
      time: TimeOfDay(hour: 10, minute: 33),
      isDelivered: true,
    ),
  ];

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