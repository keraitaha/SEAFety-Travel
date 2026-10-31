import 'package:flutter/material.dart';
import 'package:seafety_travel/shared/models/app_user.dart';
import 'package:seafety_travel/shared/models/conversation_model.dart';
import '../services/conversation_service.dart';
import 'chat_screen.dart';

class EnquiriesScreen extends StatelessWidget {
  final AppUser currentUser;
  const EnquiriesScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final service = ConversationService();
    return StreamBuilder<List<ConversationModel>>(
      stream: service.agencyConversations(currentUser.userid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load enquiries.'));
        }
        final conversations = snapshot.data ?? [];
        if (conversations.isEmpty) {
          return const Center(child: Text('No enquiries yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: conversations.length,
          itemBuilder: (context, i) {
            final c = conversations[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(c.touristdisplayname),
                subtitle: Text('Status: ${service.statusLabel(c.status)}'),
                trailing: c.followupat != null
                    ? const Icon(Icons.alarm, color: Colors.orange)
                    : const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        currentUser: currentUser,
                        conversation: c,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
