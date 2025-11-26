import 'package:flutter/material.dart';

class Message {
  final String text;
  final bool isMine;
  final TimeOfDay time; 
  final bool isDelivered;

  Message({
    required this.text,
    required this.isMine,
    required this.time,
    required this.isDelivered,
  });


  Message copyWith({bool? isDelivered}) {
    return Message(
      text: text,
      isMine: isMine,
      time: time,
      isDelivered: isDelivered ?? this.isDelivered,
    );
  }
}