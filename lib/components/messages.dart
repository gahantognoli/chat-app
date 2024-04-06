import 'package:chat/components/message_bubble.dart';
import 'package:chat/core/models/chat_message.dart';
import 'package:chat/core/services/auth/auth_service.dart';
import 'package:chat/core/services/chat/chat_service.dart';
import 'package:flutter/material.dart';

class Messages extends StatelessWidget {
  const Messages({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    return StreamBuilder<List<ChatMessage>>(
      stream: ChatService().messagesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Sem dados, vamos conversar?'));
        } else {
          var messages = snapshot.data!;
          return ListView.builder(
            itemCount: messages.length,
            reverse: true,
            itemBuilder: (ctx, index) {
              return MessageBubble(
                key: ValueKey(messages[index].id),
                message: messages[index],
                belongsToCurrentUser: currentUser?.id == messages[index].userId,
              );
            },
          );
        }
      },
    );
  }
}
