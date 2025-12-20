import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:projectdemo/core/constants/colors.dart';
import 'package:projectdemo/data/models/message_model.dart';
import 'package:projectdemo/business/cubit/private_chat/private_chat_cubit.dart';
import 'package:projectdemo/business/cubit/private_chat/private_chat_state.dart';

class PrivatechatScreen extends StatelessWidget {
  PrivatechatScreen({super.key});

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage(BuildContext context) {
    final cubit = context.read<PrivateChatCubit>();
    if (_messageController.text.trim().isEmpty) return;

    cubit.sendMessage(_messageController.text);
    _messageController.clear();

    // Auto scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // The device info is extracted once to pass to the Cubit and the UI parts
    final Map<String, dynamic>? deviceInfo =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String userName = deviceInfo?['name'] ?? 'User';
    final String avatar = deviceInfo?['avatar'] ?? 'U';
    final Color avatarColor = deviceInfo?['color'] ?? Colors.blue;
    final String status = deviceInfo?['status'] ?? 'Online';
    final String deviceId = deviceInfo?['deviceId'] ?? '';

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 235, 200, 200),
                Color.fromARGB(255, 164, 236, 246),
              ],
            ),
          ),
        ),
        title: BlocBuilder<PrivateChatCubit, PrivateChatState>(
          builder: (context, state) {
            return Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    // Navigate to peer's profile with deviceId to load full profile
                    Navigator.of(context).pushNamed(
                      "/profile",
                      arguments: {
                        'deviceId': deviceId,
                        'isSelf': false, // Viewing peer's profile
                        'name': userName,
                        'avatar': avatar,
                        'color': avatarColor,
                        'status': status,
                      },
                    );
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: avatarColor,
                    child: Text(
                      avatar,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          color: status == 'Online'
                              ? Colors.lightGreenAccent
                              : Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<PrivateChatCubit, PrivateChatState>(
              builder: (context, state) {
                final messages = state.messages;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubble(context, message);
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.secondaryBackground),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.primaryBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.attach_file,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Attachment feature coming soon'),
                              ),
                            );
                          },
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: () => _sendMessage(context),
                    backgroundColor: AppColors.connectionTeal,
                    mini: true,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, Message message) {
    final isMine = message.isMine;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[700],
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMine
                        ? AppColors.connectionTeal
                        : AppColors.secondaryBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMine ? 18 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 18),
                    ),
                    border: !isMine
                        ? Border.all(color: AppColors.textSecondary)
                        : null,
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isMine ? Colors.white : AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.time.format(context),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isDelivered ? Icons.done_all : Icons.done,
                        size: 14,
                        color: message.isDelivered
                            ? AppColors.connectionTeal
                            : AppColors.textSecondary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
