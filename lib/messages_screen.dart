import 'package:flutter/material.dart';
import 'models/message.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MessagesScreen extends StatefulWidget {
  final String token;
  final int currentUserId;
  final int receiverId;
  final String receiverName;

  const MessagesScreen({
    Key? key,
    required this.token,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
  }) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late Future<List<Message>> _futureMessages;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  void _fetchMessages() {
    setState(() {
      _futureMessages = ApiService()
          .fetchMessagesWithUser(widget.token, widget.currentUserId, widget.receiverId);
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await ApiService().sendMessage(
      token: widget.token,
      senderId: widget.currentUserId,
      receiverId: widget.receiverId,
      message: text,
    );

    _controller.clear();
    _fetchMessages();

    await Future.delayed(const Duration(milliseconds: 200));

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _clearConversation() async {
    final baseUrl = const String.fromEnvironment('API_URL', defaultValue: 'https://api.astromend.com');
    final url = Uri.parse('$baseUrl/api/messages/delete-conversation');
    try {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user1': widget.currentUserId,
          'user2': widget.receiverId,
        }),
      );
      _fetchMessages();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sohbet temizlendi')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sohbet temizlenemedi!')),
      );
    }
  }

  Widget _buildMessages(List<Message> messages) {
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final m = messages[i];
        final isMe = m.senderId == widget.currentUserId;
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              top: 8,
              bottom: 8,
              left: isMe ? 50 : 8,
              right: isMe ? 8 : 50,
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.white.withOpacity(0.82)
                  : Colors.deepPurple.withOpacity(0.86),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(2),
                bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.message,
                  style: TextStyle(
                    fontSize: 16,
                    color: isMe ? Colors.black87 : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "${m.createdAt.hour.toString().padLeft(2, '0')}:${m.createdAt.minute.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontSize: 11,
                        color: isMe ? Colors.black38 : Colors.white54,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.done_all, size: 16, color: Colors.greenAccent),
                    ]
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMenu() async {
    final result = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 60, 12, 0),
      items: [
        const PopupMenuItem<String>(
          value: 'clear',
          child: Text('Sohbeti Temizle'),
        ),
        const PopupMenuItem<String>(
          value: 'block',
          child: Text('Kullanıcıyı Engelle'),
        ),
      ],
      elevation: 2,
    );
    if (result == 'clear') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Sohbeti Temizle"),
          content: const Text("Bu kullanıcıyla olan tüm mesajları silmek istediğine emin misin?"),
          actions: [
            TextButton(child: const Text("Vazgeç"), onPressed: () => Navigator.pop(ctx, false)),
            TextButton(child: const Text("Evet, Sil"), onPressed: () => Navigator.pop(ctx, true)),
          ],
        ),
      );
      if (confirm == true) {
        await _clearConversation();
      }
    } else if (result == 'block') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcıyı engelleme özelliği henüz aktif değil.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/images/loginbackground.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(color: Colors.black.withOpacity(0.65)),
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.person)),
                    const SizedBox(width: 8),
                    Text(
                      widget.receiverName,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
                centerTitle: false,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.white, size: 28),
                    onPressed: _showMenu,
                  ),
                ],
              ),
              Expanded(
                child: FutureBuilder<List<Message>>(
                  future: _futureMessages,
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    } else if (snap.hasError) {
                      return const Center(
                        child: Text('Mesajlar yüklenemedi', style: TextStyle(color: Colors.red)),
                      );
                    }
                    final msgs = snap.data;
                    if (msgs == null || msgs.isEmpty) {
                      return const Center(
                        child: Text('Henüz mesaj yok.', style: TextStyle(color: Colors.grey)),
                      );
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                    return _buildMessages(msgs);
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Mesaj yaz...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.white12,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.deepPurple, size: 28),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
