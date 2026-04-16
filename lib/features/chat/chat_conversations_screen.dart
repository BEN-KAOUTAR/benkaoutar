import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_screen.dart';
import 'models/chat_thread_model.dart';
import 'viewmodels/chat_view_model.dart';
import '../../core/services/auth_service.dart';

class ChatConversationsScreen extends StatefulWidget {
  const ChatConversationsScreen({Key? key}) : super(key: key);

  @override
  State<ChatConversationsScreen> createState() => _ChatConversationsScreenState();
}

class _ChatConversationsScreenState extends State<ChatConversationsScreen> {
  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      await AuthService.instance.init();
      final token = AuthService.instance.getStoredToken();
      final user = AuthService.instance.getStoredUser();

      if (token != null && mounted) {
        // Get ChatViewModel from Provider and initialize WebSocket
        final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
        
        // Initialize user info
        chatViewModel.setUserId(user?.id ?? '');
        chatViewModel.setUserName(user?.name ?? '');
        
        // Initialize WebSocket with token and base URL
        await chatViewModel.initializeWebSocket(
          token: token,
          baseUrl: 'https://api-demo.intranet.ikenas.com/api',
        );
        
        // Load conversations
        await chatViewModel.loadConversations();
      }
    } catch (e) {
      debugPrint('Error initializing chat: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, chatViewModel, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Chats'),
            elevation: 2,
            actions: [
              if (chatViewModel.isConnected)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Connected',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Connecting...',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          body: chatViewModel.loading
              ? const Center(child: CircularProgressIndicator())
              : chatViewModel.conversations.isEmpty
                  ? const Center(
                      child: Text('No conversations yet.'),
                    )
                  : ListView.builder(
                      itemCount: chatViewModel.conversations.length,
                      itemBuilder: (context, index) {
                        final thread = chatViewModel.conversations[index];
                        return _buildConversationTile(context, thread);
                      },
                    ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // TODO: Implement new conversation
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildConversationTile(BuildContext context, ChatThread thread) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade200,
        child: Text(
          thread.name[0].toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(thread.name),
      subtitle: Text(
        thread.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(thread.lastMessageTime),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (thread.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                thread.unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(threadId: thread.id, threadName: thread.name),
          ),
        );
      },
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
      return '${time.day}/${time.month}';
    }
  }
}
