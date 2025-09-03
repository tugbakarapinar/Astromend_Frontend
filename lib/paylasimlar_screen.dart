import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_service.dart';

class PaylasimlarScreen extends StatefulWidget {
  final int userId;
  final String username;
  const PaylasimlarScreen({super.key, required this.userId, required this.username});

  @override
  State<PaylasimlarScreen> createState() => _PaylasimlarScreenState();
}

class _PaylasimlarScreenState extends State<PaylasimlarScreen> {
  final TextEditingController _postController = TextEditingController();
  File? _selectedImage;
  List<Map<String, dynamic>> _posts = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _fetchPosts() async {
    setState(() => _loading = true);
    try {
      final posts = await ApiService.fetchPosts();
      setState(() => _posts = List<Map<String, dynamic>>.from(posts));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gönderiler yüklenemedi")),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _addPost() async {
    final text = _postController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final baseUrl = dotenv.env['API_URL'] ?? 'https://api.astromend.com';
      final uri = Uri.parse('$baseUrl/api/posts');
      http.Response response;

      if (_selectedImage != null) {
        // ✅ Multipart request için userId ekledik
        final request = http.MultipartRequest('POST', uri);
        if (token.isNotEmpty) request.headers['Authorization'] = 'Bearer $token';
        request.fields['userId'] = widget.userId.toString();
        if (text.isNotEmpty) request.fields['text'] = text;
        request.files.add(
          await http.MultipartFile.fromPath('image', _selectedImage!.path),
        );
        response = await http.Response.fromStream(await request.send());
      } else {
        // ✅ JSON body’ye userId ekledik
        response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'userId': widget.userId,
            if (text.isNotEmpty) 'text': text,
          }),
        );
      }

      if (response.statusCode == 201) {
        _postController.clear();
        setState(() => _selectedImage = null);
        await _fetchPosts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paylaşım başarısız oldu.')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paylaşım sırasında bir hata oluştu.')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
    try {
      if (post['likedByMe'] == true) {
        await ApiService.unlikePost(post['id'], widget.userId);
      } else {
        await ApiService.likePost(post['id'], widget.userId);
      }
      _fetchPosts();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Beğeni işlemi başarısız")),
      );
    }
  }

  void _showCommentsModal(int postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white.withOpacity(0.96),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => CommentsModal(postId: postId, userId: widget.userId),
    );
  }

  void _showLikesModal(int postId) async {
    final likes = await ApiService.fetchLikes(postId);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white.withOpacity(0.97),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (_) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        children: [
          const Center(child: Text("Beğenenler", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          ...likes.map((e) => ListTile(
                leading: CircleAvatar(child: Text(e['username'][0].toUpperCase())),
                title: Text(e['username']),
              ))
        ],
      ),
    );
  }

  Widget _buildPostInputCard() {
    return Card(
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF44216A),
              child: Text(widget.username[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _postController,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(hintText: "Bir şeyler paylaş...", border: InputBorder.none),
              ),
            ),
            IconButton(icon: const Icon(Icons.image), onPressed: _pickImage),
          ]),
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Stack(alignment: Alignment.topRight, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(_selectedImage!, height: 120, width: double.infinity, fit: BoxFit.cover),
                ),
                IconButton(icon: const Icon(Icons.cancel), onPressed: () => setState(() => _selectedImage = null)),
              ]),
            ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _addPost,
              child: const Text("Paylaş", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ]),
        ]),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return "şimdi";
    if (diff.inMinutes < 60) return "${diff.inMinutes} dk önce";
    if (diff.inHours < 24) return "${diff.inHours} saat önce";
    return "${date.day}.${date.month}.${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 44),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 5, bottom: 3),
                          child: Text(
                            "Akış",
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                              letterSpacing: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                  _buildPostInputCard(),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _posts.isEmpty
                            ? const Center(
                                child: Text("Henüz paylaşım yok.", style: TextStyle(color: Colors.grey, fontSize: 17)),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 30),
                                itemCount: _posts.length,
                                itemBuilder: (ctx, idx) => _buildPostCard(_posts[idx]),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      color: Colors.white.withOpacity(0.98),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF44216A),
              child: Text((post['username'] ?? 'U')[0].toUpperCase()),
            ),
            const SizedBox(width: 8),
            Text(post['username'] ?? 'Kullanıcı',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            Text(
              _formatDate(post['created_at'] ?? ""),
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ]),
          if (post['text'] != null && post['text'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(post['text'],
                  style: const TextStyle(fontSize: 15, color: Colors.black87)),
            ),
          if (post['image_path'] != null && post['image_path'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  '${dotenv.env['API_URL']}${post['image_path']}',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 6),
          Row(children: [
            IconButton(
              icon: Icon(post['likedByMe'] == true
                  ? Icons.favorite
                  : Icons.favorite_border),
              onPressed: () => _toggleLike(post),
            ),
            GestureDetector(
              onTap: () => _showLikesModal(post['id']),
              child: Text('${post['likesCount'] ?? 0}'),
            ),
            const SizedBox(width: 18),
            IconButton(
              icon: const Icon(Icons.comment_outlined),
              onPressed: () => _showCommentsModal(post['id']),
            ),
            Text('${post['commentsCount'] ?? 0}'),
          ]),
        ]),
      ),
    );
  }
}

class CommentsModal extends StatefulWidget {
  final int postId;
  final int userId;
  const CommentsModal({super.key, required this.postId, required this.userId});

  @override
  State<CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<CommentsModal> {
  List<Map<String, dynamic>> comments = [];
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    setState(() => _loading = true);
    try {
      comments = await ApiService.fetchComments(widget.postId);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yorumlar yüklenemedi")),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _addComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      final success = await ApiService.addComment(
          postId: widget.postId, userId: widget.userId, text: text);
      if (success) {
        _controller.clear();
        _fetchComments();
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yorum eklenemedi")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(children: [
          const SizedBox(height: 8),
          Container(
            height: 6,
            width: 40,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3)),
          ),
          const Text("Yorumlar",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : comments.isEmpty
                    ? const Center(child: Text("Henüz yorum yok."))
                    : ListView(
                        children: comments
                            .map((c) => ListTile(
                                  leading: CircleAvatar(
                                      child: Text(
                                          c['username'][0].toUpperCase())),
                                  title: Text(c['username']),
                                  subtitle: Text(c['text']),
                                  trailing: Text(
                                    c['created_at'] != null
                                        ? c['created_at']
                                            .toString()
                                            .substring(0, 16)
                                            .replaceAll('T', ' ')
                                        : "",
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ))
                            .toList(),
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "Yorum ekle...",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _addComment)
            ]),
          ),
        ]),
      ),
    );
  }
}
