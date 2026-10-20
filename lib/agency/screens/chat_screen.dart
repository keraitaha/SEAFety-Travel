import 'package:flutter/material.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/conversation_model.dart';
import '../../shared/theme/app_theme.dart';
import '../services/conversation_service.dart';

class ChatScreen extends StatefulWidget {
  final AppUser currentUser;
  final ConversationModel conversation;
  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.conversation,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ConversationService _service = ConversationService();
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    await _service.sendMessage(
      conversationid: widget.conversation.conversationid,
      senderuserid: widget.currentUser.userid,
      text: text,
    );
    _messageController.clear();
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _changeStatus() async {
    const options = [
      'new',
      'in_progress',
      'waiting_for_customer',
      'confirmed',
    ];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (o) => ListTile(
                  title: Text(o),
                  onTap: () => Navigator.pop(ctx, o),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected != null) {
      await _service.updateStatus(
        widget.conversation.conversationid,
        selected,
      );
    }
  }

  Future<void> _setFollowUp() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (date != null) {
      await _service.setFollowUp(widget.conversation.conversationid, date);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Follow-up reminder set.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversation.touristdisplayname),
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm_add),
            tooltip: 'Set follow-up',
            onPressed: _setFollowUp,
          ),
          IconButton(
            icon: const Icon(Icons.flag),
            tooltip: 'Change status',
            onPressed: _changeStatus,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _service.messages(widget.conversation.conversationid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Could not load messages.'),
                  );
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Say hello!'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final isMine =
                        m.senderuserid == widget.currentUser.userid;
                    return _MessageBubble(text: m.text, isMine: isMine);
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primaryBlue),
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  const _MessageBubble({required this.text, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primaryBlue : AppColors.paleBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMine ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
