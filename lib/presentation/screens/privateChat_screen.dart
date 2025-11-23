import 'package:flutter/material.dart';
import 'package:projectdemo/constants/colors.dart';


class PrivatechatScreen extends StatefulWidget {
  const PrivatechatScreen({super.key});

  @override
  State<PrivatechatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State< PrivatechatScreen > {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hey! Are you safe?',
      'isMine': false,
      'time': '10:30 AM',
      'isDelivered': true,
    },
    {
      'text': 'Yes, I\'m okay. Just staying indoors.',
      'isMine': true,
      'time': '10:32 AM',
      'isDelivered': true,
    },
    {
      'text': 'Good to hear! Do you need any supplies?',
      'isMine': false,
      'time': '10:33 AM',
      'isDelivered': true,
    },
    {
      'text': 'I could use some water and batteries if possible',
      'isMine': true,
      'time': '10:35 AM',
      'isDelivered': true,
    },
    {
      'text': 'I have extras. I\'ll bring them over in about 30 mins',
      'isMine': false,
      'time': '10:36 AM',
      'isDelivered': true,
    },
    {
      'text': 'That would be amazing! Thank you so much',
      'isMine': true,
      'time': '10:37 AM',
      'isDelivered': true,
    },
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({
        'text': _messageController.text,
        'isMine': true,
        'time': TimeOfDay.now().format(context),
        'isDelivered': false,
      });
      _messageController.clear();
    });
    
    // Auto scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? deviceInfo = 
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    final String userName = deviceInfo?['name'] ?? 'User';
    final String avatar = deviceInfo?['avatar'] ?? 'U';
    final Color avatarColor = deviceInfo?['color'] ?? Colors.blue;
    final String status = deviceInfo?['status'] ?? 'Online';

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
        title: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                // Navigate to the user's profile screen using named route and pass device info
                Navigator.of(context).pushNamed(
                  "/profile",
                  arguments: {
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: status == 'Online' ? Colors.lightGreenAccent : Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: AppColors.alertRed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield, size: 16, color: AppColors.alertRed),
                const SizedBox(width: 8),
                const Text(
                  'Emergency Mode: Messages are encrypted',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
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
                          icon: const Icon(Icons.attach_file, color: AppColors.textSecondary),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Attachment feature coming soon')),
                            );
                          },
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: _sendMessage,
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

  

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMine = message['isMine'] as bool;                                    ///////////////////////
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
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
              crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    message['text'],
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
                      message['time'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message['isDelivered'] ? Icons.done_all : Icons.done,
                        size: 14,
                        color: message['isDelivered'] 
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
