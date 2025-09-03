import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models/message.dart';
import 'messages_screen.dart';

class MessageListScreen extends StatefulWidget {
  final String token;
  final int currentUserId;

  const MessageListScreen({
    Key? key,
    required this.token,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  bool selectionMode = false;
  Set<int> selectedIds = {};
  Future<List<Message>>? _messagesFuture;

  bool searchMode = false;
  String searchQuery = '';

  List<MapEntry<int, Message>> _allEntries = [];
  List<MapEntry<int, Message>> _filteredEntries = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _messagesFuture = ApiService().fetchMessages(widget.token);
    });
  }

  void _showPopupMenu(BuildContext context, Offset offset) async {
    await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx + 160,
        offset.dy + 60,
      ),
      color: Colors.transparent,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      items: [
        PopupMenuItem(
          value: 'select',
          padding: EdgeInsets.zero,
          height: 58,
          child: Center(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context, 'select');
                setState(() {
                  selectionMode = true;
                  selectedIds.clear();
                });
              },
              child: Container(
                width: 195,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 15,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    SizedBox(width: 14),
                    Icon(Icons.check_circle_outline, size: 20, color: Colors.grey),
                    SizedBox(width: 13),
                    Text(
                      "Seç",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sohbetleri Sil'),
        content: const Text('Seçili sohbetleri silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hayır'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService().deleteConversations(
        widget.token,
        widget.currentUserId,
        selectedIds.toList(),
      );

      setState(() {
        _allEntries.removeWhere((entry) => selectedIds.contains(entry.key));
        _filteredEntries.removeWhere((entry) => selectedIds.contains(entry.key));
        selectionMode = false;
        selectedIds.clear();
      });

      // 🔹 Backend’den tekrar güncelle
      _reload();
    }
  }

  Future<void> _confirmDeleteSingle(int otherId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sohbeti Sil'),
        content: const Text('Bu sohbeti silmek istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService().deleteConversation(
        widget.token,
        widget.currentUserId,
        otherId,
      );

      setState(() {
        _allEntries.removeWhere((entry) => entry.key == otherId);
        _filteredEntries.removeWhere((entry) => entry.key == otherId);
        selectionMode = false;
        selectedIds.clear();
      });

      // 🔹 Backend’den tekrar güncelle
      _reload();
    }
  }

  void _openSearch() {
    setState(() {
      searchMode = true;
      searchQuery = '';
      _filteredEntries = _allEntries;
    });
  }

  void _closeSearch() {
    setState(() {
      searchMode = false;
      searchQuery = '';
      _filteredEntries = _allEntries;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
      _filteredEntries = _allEntries
          .where((entry) {
            final name = _getReceiverName(entry.value, entry.key);
            return name.toLowerCase().contains(searchQuery.toLowerCase());
          })
          .toList();
    });
  }

  String _getReceiverName(Message msg, int otherId) {
    final isSentByMe = msg.senderId == widget.currentUserId;
    return isSentByMe
        ? "Kullanıcı ${msg.receiverId}"
        : "Kullanıcı ${msg.senderId}";
  }

  void _openNewChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(ctx).size.height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Yeni Sohbet",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Kullanıcı ara...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {},
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: Text(
                      "Kullanıcı listesi burada çıkacak",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0B0B0C),
                    Color(0xFF2A0A3D),
                    Color(0xFF000000),
                  ],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: _buildAppBar(context),
              ),
              Expanded(child: _buildMessageList(context)),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              left: false,
              right: true,
              bottom: true,
              child: SizedBox(
                width: 56,
                height: 56,
                child: FloatingActionButton(
                  onPressed: _openNewChatModal,
                  backgroundColor: const Color(0xFF7059AE),
                  child: const Icon(Icons.chat, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: null,
        title: searchMode
            ? Container(
                height: 48,
                width: 330,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Kullanıcı adı ara",
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: _closeSearch,
                    ),
                    hintStyle: const TextStyle(color: Colors.black45, fontSize: 16.5),
                  ),
                  style: const TextStyle(color: Colors.black87, fontSize: 18),
                  onChanged: _onSearchChanged,
                ),
              )
            : const Text(
                "Sohbetler",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
        centerTitle: true,
        actions: selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white, size: 25),
                  onPressed: selectedIds.isNotEmpty ? _confirmDeleteSelected : null,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white, size: 25),
                  onPressed: _openSearch,
                ),
                Builder(
                  builder: (ctx) => GestureDetector(
                    onTapDown: (details) =>
                        _showPopupMenu(ctx, details.globalPosition),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Icon(Icons.more_vert, color: Colors.white, size: 26.5),
                    ),
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildMessageList(BuildContext context) {
    if (_messagesFuture == null) return const SizedBox();
    return FutureBuilder<List<Message>>(
      future: _messagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (snapshot.hasError) {
          return const Center(
              child: Text("Mesajlar yüklenemedi", style: TextStyle(color: Colors.red)));
        }
        final messages = snapshot.data ?? [];
        if (messages.isEmpty) {
          return const Center(child: Text("Henüz mesaj yok", style: TextStyle(color: Colors.grey)));
        }

        final Map<int, Message> users = {};
        for (var m in messages) {
          final otherId = m.senderId == widget.currentUserId ? m.receiverId : m.senderId;
          if (!users.containsKey(otherId) ||
              m.createdAt.isAfter(users[otherId]!.createdAt)) {
            users[otherId] = m;
          }
        }

        final sortedEntries = users.entries.toList()
          ..sort((a, b) => b.value.createdAt.compareTo(a.value.createdAt));

        _allEntries = sortedEntries;
        _filteredEntries = searchMode
            ? (_filteredEntries.isEmpty && searchQuery.isEmpty ? sortedEntries : _filteredEntries)
            : sortedEntries;

        if (searchMode && searchQuery.isNotEmpty && _filteredEntries.isEmpty) {
          return const Center(
            child: Text(
              "Arama sonucu yok",
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 11),
          itemCount: _filteredEntries.length,
          separatorBuilder: (context, i) => const SizedBox(height: 4),
          itemBuilder: (context, i) {
            final entry = _filteredEntries[i];
            final msg = entry.value;
            final otherId = entry.key;
            final receiverName = _getReceiverName(msg, otherId);
            final isSelected = selectionMode && selectedIds.contains(otherId);

            return GestureDetector(
              onLongPress: () {
                if (!selectionMode) {
                  setState(() {
                    selectionMode = true;
                    selectedIds.add(otherId);
                  });
                } else {
                  _confirmDeleteSingle(otherId);
                }
              },
              onTap: () {
                if (selectionMode) {
                  setState(() {
                    if (selectedIds.contains(otherId)) {
                      selectedIds.remove(otherId);
                      if (selectedIds.isEmpty) selectionMode = false;
                    } else {
                      selectedIds.add(otherId);
                    }
                  });
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => MessagesScreen(
                        token: widget.token,
                        currentUserId: widget.currentUserId,
                        receiverId: otherId,
                        receiverName: receiverName,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 0),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFF2F2F5)
                      : Colors.white.withOpacity(0.42),
                  borderRadius: BorderRadius.circular(5),
                  border: isSelected
                      ? Border.all(color: Colors.grey.shade600, width: 1.05)
                      : null,
                ),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 13),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.deepPurple,
                      child: Icon(Icons.person, color: Colors.white, size: 25),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receiverName,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            msg.message,
                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    if (selectionMode)
                      Container(
                        margin: const EdgeInsets.only(left: 16),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: isSelected
                                  ? Color(0xFF7059AE)
                                  : Colors.grey.shade400,
                              width: 2.0),
                          color: isSelected
                              ? Color(0xFFE2DBF6)
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 17, color: Color(0xFF7059AE))
                            : null,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
