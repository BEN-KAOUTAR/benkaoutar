import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/chat_view_model.dart';
import 'models/chat_message_model.dart';
import 'screens/chat_search_screen.dart';

class ChatScreen extends StatefulWidget {
  final String? threadId;
  final String? threadName;

  const ChatScreen({
    Key? key,
    this.threadId,
    this.threadName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  late String _threadId;

  @override
  void initState() {
    super.initState();
    _threadId = widget.threadId ?? 'general';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadThread();
    });
  }

  void _loadThread() {
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
    chatViewModel.loadMessages(_threadId);
  }

  void _sendMessage(ChatViewModel chatViewModel) {
    if (_controller.text.trim().isNotEmpty) {
      chatViewModel.sendMessage(_controller.text.trim());
      _controller.clear();
      // Send typing stop indicator
      chatViewModel.stopTypingIndicator();
    }
  }

  void _onTyping(ChatViewModel chatViewModel) {
    chatViewModel.sendTypingIndicator();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, chatViewModel, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.threadName ?? 'Chat'),
            elevation: 2,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatSearchScreen(messages: chatViewModel.messages),
                    ),
                  );
                  if (result is ChatMessage) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Found: ${result.content}')),
                    );
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: chatViewModel.isConnected
                      ? const Tooltip(
                          message: 'Connected',
                          child: Chip(
                            label: Text('Online'),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        )
                      : const Tooltip(
                          message: 'Disconnected',
                          child: Chip(
                            label: Text('Offline'),
                            backgroundColor: Colors.red,
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              if (chatViewModel.loading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )
              else if (chatViewModel.messages.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No messages yet. Start a conversation!'),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: chatViewModel.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatViewModel.messages[chatViewModel.messages.length - 1 - index];
                      return _buildMessageBubble(msg, chatViewModel);
                    },
                  ),
                ),
              // Typing Indicators
              if (chatViewModel.isConnected && chatViewModel.messages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 30,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Others typing', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 30,
                            height: 20,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                3,
                                (i) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: (_) {
                          _onTyping(chatViewModel);
                        },
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      onPressed: () => _sendMessage(chatViewModel),
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, ChatViewModel chatViewModel) {
    final isOwn = msg.isOwn;
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '😭'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isOwn) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade300,
                  child: msg.senderAvatar.isNotEmpty
                      ? Image.network(msg.senderAvatar)
                      : Text(msg.senderName[0].toUpperCase()),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: () => _showMessageOptions(context, msg, emojis),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isOwn ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!isOwn)
                          Text(
                            msg.senderName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        if (msg.isDeleted)
                          Text(
                            'This message was deleted',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                          )
                        else
                          Text(
                            msg.content,
                            style: const TextStyle(fontSize: 14),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(msg.timestamp),
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                            if (msg.isEdited) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(edited)',
                                style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isOwn) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: Text(
                    (chatViewModel.userName?.isNotEmpty ?? false)
                        ? chatViewModel.userName![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          // Show reactions if any
          if (msg.reactions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 4, left: isOwn ? 0 : 56, right: isOwn ? 56 : 0),
              child: Wrap(
                spacing: 4,
                children: msg.reactions.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${e.key} ${e.value}', style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context, ChatMessage msg, List<String> emojis) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Message Options',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (!msg.isDeleted) ...[
            ListTile(
              leading: const Icon(Icons.add_reaction),
              title: const Text('React'),
              onTap: () {
                Navigator.pop(context);
                _showReactionMenu(context, msg, emojis);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
          ],
          if (msg.isOwn && !msg.isDeleted) ...[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(msg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(msg);
              },
            ),
          ],
          if (msg.isDeleted)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'This message was deleted',
                style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(ChatMessage msg) {
    final editController = TextEditingController(text: msg.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Edit your message',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ChatMessage msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReactionMenu(BuildContext context, ChatMessage msg, List<String> emojis) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          children: emojis.map((emoji) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reacted with $emoji')),
                );
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(time.year, time.month, time.day);

    if (msgDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
