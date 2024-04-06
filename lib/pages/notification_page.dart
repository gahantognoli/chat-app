import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/notification/chat_notification_service.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatNotificationService>(context);
    final items = provider.items;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas notificações'),
      ),
      body: ListView.builder(
        itemCount: provider.itemsCount,
        itemBuilder: (ctx, index) => ListTile(
          title: Text(items[index].title),
          subtitle: Text(items[index].body),
          onTap: () => provider.remove(index),
        ),
      ),
    );
  }
}
