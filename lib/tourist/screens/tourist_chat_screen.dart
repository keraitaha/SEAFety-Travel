import 'package:flutter/material.dart';
import 'package:seafety_travel/shared/models/tourist_data.dart';
import '../services/tourist_store.dart';
import '../widgets/tourist_ui.dart';

class TouristInboxScreen extends StatelessWidget {
  final TouristStore store;
  const TouristInboxScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Conversations', subtitle: 'Speak directly with travel agencies and tourism officers'),
        if (store.threads.isEmpty)
          const InfoCard(
            child: Column(
              children: [
                Icon(Icons.forum_outlined, size: 38, color: TouristPalette.blue),
                SizedBox(height: 10),
                Text('No conversations yet.'),
                Text('Open a package to contact its travel agency.'),
              ],
            ),
          ),
        ...store.threads.map(
          (thread) => InfoCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: TouristPalette.ice,
                child: Icon(thread.type == 'agency' ? Icons.storefront : Icons.shield, color: TouristPalette.navy),
              ),
              title: Text(thread.type == 'agency' ? 'Travel agency' : 'Tourism officer'),
              subtitle: Text('Status: ${thread.status}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TouristChatScreen(store: store, thread: thread),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: store.officerId == null
              ? null
              : () async {
                  try {
                    final thread = await store.openConversation(staffId: store.officerId!, type: 'officer');
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TouristChatScreen(store: store, thread: thread),
                      ),
                    );
                  } catch (error) {
                    showNotice(context, shortError(error));
                  }
                },
          icon: const Icon(Icons.support_agent),
          label: const Text('Contact a tourism officer'),
        ),
        const SizedBox(height: 14),
        Text(
          'For immediate danger, contact local emergency services. Chat is not an emergency response service.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}

class TouristChatScreen extends StatefulWidget {
  final TouristStore store;
  final ChatThread thread;
  const TouristChatScreen({super.key, required this.store, required this.thread});

  @override
  State<TouristChatScreen> createState() => _TouristChatScreenState();
}

class _TouristChatScreenState extends State<TouristChatScreen> {
  final controller = TextEditingController();
  bool sending = false;

  @override
  void initState() {
    super.initState();
    widget.store.loadMessages(widget.thread.id).catchError((Object error) {
      if (mounted) showNotice(context, shortError(error));
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() => sending = true);
    try {
      await widget.store.sendMessage(widget.thread.id, text);
      if (mounted) controller.clear();
    } catch (error) {
      if (mounted) showNotice(context, shortError(error));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, child) {
      final messages = widget.store.messages[widget.thread.id] ?? <ChatMessage>[];
      return Scaffold(
        backgroundColor: TouristPalette.background,
        appBar: AppBar(title: Text(widget.thread.type == 'agency' ? 'Agency chat' : 'Tourism officer chat')),
        body: Column(
          children: [
            if (widget.thread.type == 'officer')
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'For urgent danger, call local emergency services.',
                  style: TextStyle(color: Colors.deepOrange),
                ),
              ),
            Expanded(
              child: messages.isEmpty
                  ? const Center(child: Text('No messages yet. Say hello!'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final message = messages[i];
                        final own = message.senderId == widget.store.userId;
                        final prev = i > 0 ? messages[i - 1] : null;
                        final showDate = prev == null || !_sameDay(message.createdAt, prev.createdAt);
                        return Column(
                          children: [
                            if (showDate) _DateSeparator(date: message.createdAt),
                            Align(
                              alignment: own ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                                margin: const EdgeInsets.only(bottom: 9),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: own ? TouristPalette.navy : TouristPalette.ice,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(message.text, style: TextStyle(color: own ? Colors.white : Colors.black87)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: own ? Colors.white70 : Colors.blueGrey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(hintText: 'Type a message…'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(onPressed: sending ? null : _send, icon: const Icon(Icons.send)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

String _dateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(date.year, date.month, date.day);
  final diff = today.difference(that).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
        decoration: BoxDecoration(color: TouristPalette.ice, borderRadius: BorderRadius.circular(12)),
        child: Text(_dateLabel(date), style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700)),
      ),
    );
  }
}
