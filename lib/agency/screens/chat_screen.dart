import 'package:flutter/material.dart';
import 'package:seafety_travel/shared/models/app_user.dart';
import 'package:seafety_travel/shared/models/conversation_model.dart';
import 'package:seafety_travel/shared/theme/app_theme.dart';
import '../services/conversation_service.dart';

class ChatScreen extends StatefulWidget {
  final AppUser currentUser;
  final ConversationModel conversation;
  final ConversationService? service;
  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.conversation,
    this.service,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ConversationService _service;
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ConversationService();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _service.sendMessage(
        conversationid: widget.conversation.conversationid,
        senderuserid: widget.currentUser.userid,
        text: text,
      );
      if (mounted) _messageController.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not send message. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _changeStatus() async {
    const options = ['new', 'in_progress', 'waiting_for_customer', 'confirmed'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (o) => ListTile(
                  title: Text(_service.statusLabel(o)),
                  onTap: () => Navigator.pop(ctx, o),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected != null) {
      await _service.updateStatus(widget.conversation.conversationid, selected);
    }
  }

  Future<void> _pickFollowUpDate() async {
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

  Future<void> _removeFollowUp() async {
    await _service.clearFollowUp(widget.conversation.conversationid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Follow-up reminder removed.')),
      );
    }
  }

  Future<void> _followUp() async {
    final hasFollowUp = widget.conversation.followupat != null;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(hasFollowUp ? 'Change follow-up date' : 'Set follow-up date'),
              onTap: () => Navigator.pop(ctx, 'set'),
            ),
            if (hasFollowUp)
              ListTile(
                leading: const Icon(Icons.alarm_off),
                title: const Text('Remove follow-up'),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (action == 'set') {
      await _pickFollowUpDate();
    } else if (action == 'remove') {
      await _removeFollowUp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversation.touristdisplayname),
        actions: [
          IconButton(
            icon: Icon(
              widget.conversation.followupat != null
                  ? Icons.alarm_on
                  : Icons.alarm_add,
            ),
            tooltip: widget.conversation.followupat != null
                ? 'Follow-up set'
                : 'Set follow-up',
            onPressed: _followUp,
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
                  return const Center(child: Text('Could not load messages.'));
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
                    final isMine = m.senderuserid == widget.currentUser.userid;
                    final date = m.sentat?.toDate();
                    final prevDate = i > 0
                        ? messages[i - 1].sentat?.toDate()
                        : null;
                    final showDate = date != null &&
                        (prevDate == null || !_sameDay(date, prevDate));
                    return Column(
                      children: [
                        if (showDate) _DateSeparator(date: date),
                        _MessageBubble(
                          text: m.text,
                          isMine: isMine,
                          sentat: date,
                        ),
                      ],
                    );
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

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _dateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(date.year, date.month, date.day);
  final diff = today.difference(that).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.paleBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _dateLabel(date),
          style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final DateTime? sentat;
  const _MessageBubble({
    required this.text,
    required this.isMine,
    this.sentat,
  });

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(color: isMine ? Colors.white : Colors.black87),
            ),
            if (sentat != null) ...[
              const SizedBox(height: 4),
              Text(
                '${sentat!.hour.toString().padLeft(2, '0')}:${sentat!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 10,
                  color: isMine ? Colors.white70 : Colors.blueGrey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
