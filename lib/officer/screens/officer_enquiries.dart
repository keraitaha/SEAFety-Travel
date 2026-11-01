import 'package:flutter/material.dart';
import 'package:seafety_travel/agency/screens/chat_screen.dart';
import 'package:seafety_travel/agency/services/conversation_service.dart';
import 'package:seafety_travel/shared/models/app_user.dart';
import 'package:seafety_travel/shared/models/conversation_model.dart';

class OfficerEnquiries extends StatelessWidget {
  final AppUser currentUser;

  const OfficerEnquiries({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tourist enquiries')),
    body: StreamBuilder<List<ConversationModel>>(
      stream: ConversationService().staffConversations(
        currentUser.userid,
        type: 'officer',
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load enquiries.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final enquiries = snapshot.data!;
        if (enquiries.isEmpty) {
          return const Center(child: Text('No tourist enquiries yet.'));
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: enquiries
              .map(
                (enquiry) => Card(
                  child: ListTile(
                    title: Text(enquiry.touristdisplayname),
                    subtitle: Text(
                      'Status: ${ConversationService().statusLabel(enquiry.status)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          currentUser: currentUser,
                          conversation: enquiry,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}
