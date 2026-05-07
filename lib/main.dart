import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:typed_data';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

const kOrange = Color(0xFFFF6B2B);
const kBg = Color(0xFF0D0D0D);
const kSidebar = Color(0xFF141414);
const kCard = Color(0xFF1C1C1C);
const kBorder = Color(0xFF2A2A2A);

class Clickable extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const Clickable({super.key, required this.child, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kOrange, brightness: Brightness.dark),
        useMaterial3: true,
        scaffoldBackgroundColor: kBg,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Map<String, dynamic>> conversations = [];
  int? activeConvId;
  bool sidebarOpen = true;

  @override
  void initState() {
    super.initState();
    loadConversations();
  }

  Future<void> loadConversations() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/conversations/'));
      final data = jsonDecode(response.body) as List;
      setState(() => conversations = data.map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (e) {}
  }

  Future<void> createNewConversation() async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://127.0.0.1:8000/conversations/'));
      request.fields['objectif'] = 'general';
      request.fields['title'] = 'Nouvelle conversation';
      var response = await request.send();
      var body = await response.stream.bytesToString();
      final data = jsonDecode(body);
      setState(() {
        conversations.insert(0, Map<String, dynamic>.from(data));
        activeConvId = data['id'];
      });
    } catch (e) {}
  }

  Future<void> deleteConversation(int id) async {
    try {
      await http.delete(Uri.parse('http://127.0.0.1:8000/conversations/$id'));
      setState(() {
        conversations.removeWhere((c) => c['id'] == id);
        if (activeConvId == id) activeConvId = null;
      });
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: sidebarOpen ? 260 : 0,
          child: sidebarOpen ? _buildSidebar() : const SizedBox(),
        ),
        Expanded(
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: kSidebar, border: Border(bottom: BorderSide(color: kBorder))),
              child: Row(children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                    onPressed: () => setState(() => sidebarOpen = !sidebarOpen),
                    icon: Icon(Icons.menu, color: Colors.white.withOpacity(0.5)),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: kOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.fitness_center, color: kOrange, size: 18),
                ),
                const SizedBox(width: 10),
                const Text("Gym AI Coach", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                    onPressed: createNewConversation,
                    icon: const Icon(Icons.edit_outlined, color: kOrange, size: 20),
                    tooltip: "Nouveau chat",
                  ),
                ),
              ]),
            ),
            Expanded(
              child: activeConvId == null
                  ? _buildWelcome()
                  : ChatView(
                      key: ValueKey(activeConvId),
                      convId: activeConvId!,
                      onTitleUpdate: (title) {
                        setState(() {
                          final idx = conversations.indexWhere((c) => c['id'] == activeConvId);
                          if (idx != -1) conversations[idx]['title'] = title;
                        });
                      },
                    ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSidebar() {
    return Container(
      decoration: const BoxDecoration(
        color: kSidebar,
        border: Border(right: BorderSide(color: kBorder)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: createNewConversation,
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Nouveau chat", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text("RÉCENT", style: TextStyle(fontSize: 10, color: Colors.white24, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ),
        ),
        Expanded(
          child: conversations.isEmpty
              ? Center(child: Text("Aucune conversation", style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    final isActive = conv['id'] == activeConvId;
                    return Clickable(
                      onTap: () => setState(() => activeConvId = conv['id']),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive ? kOrange.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isActive ? kOrange.withOpacity(0.3) : Colors.transparent),
                        ),
                        child: Row(children: [
                          Icon(Icons.chat_bubble_outline, size: 14, color: isActive ? kOrange : Colors.white38),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              conv['title'] ?? 'Conversation',
                              style: TextStyle(fontSize: 13, color: isActive ? Colors.white : Colors.white60, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(conv['updated_at'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.white24)),
                          ])),
                          Clickable(
                            onTap: () => deleteConversation(conv['id']),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(Icons.close, size: 13, color: Colors.white.withOpacity(0.2)),
                            ),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  Widget _buildWelcome() {
    final suggestions = [
      {"icon": Icons.videocam_outlined, "text": "Analyse mon squat"},
      {"icon": Icons.fitness_center, "text": "Donne-moi un programme pour gagner en force"},
      {"icon": Icons.compare_arrows, "text": "Comment améliorer ma profondeur de squat ?"},
      {"icon": Icons.monitor_heart_outlined, "text": "Comment savoir si je peux augmenter la charge ?"},
      {"icon": Icons.emoji_objects_outlined, "text": "Quels muscles travaille le squat ?"},
      {"icon": Icons.schedule, "text": "Combien de fois par semaine faire des squats ?"},
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: kOrange.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: kOrange.withOpacity(0.3))),
            child: const Icon(Icons.fitness_center, size: 44, color: kOrange),
          ),
          const SizedBox(height: 20),
          const Text("Gym AI Coach", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Text("Ton coach sportif IA personnel", style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.35))),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: suggestions.map((s) => Clickable(
              onTap: () => createNewConversation(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(s['icon'] as IconData, size: 15, color: kOrange),
                  const SizedBox(width: 8),
                  Text(s['text'] as String, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7))),
                ]),
              ),
            )).toList(),
          ),
        ]),
      ),
    );
  }
}

// ===================== CHAT VIEW =====================

class ChatView extends StatefulWidget {
  final int convId;
  final Function(String) onTitleUpdate;
  const ChatView({super.key, required this.convId, required this.onTitleUpdate});
  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  bool isLoading = false;
  Uint8List? pendingVideoBytes;
  String? pendingVideoName;

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  Future<void> loadMessages() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/conversations/${widget.convId}/messages'));
      final data = jsonDecode(response.body) as List;
      setState(() => messages = data.map((e) => Map<String, dynamic>.from(e)).toList());
      _scrollToBottom();
    } catch (e) {}
  }

  Future<void> pickVideo() async {
    FilePickerResult? picked = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
    if (picked != null) {
      setState(() {
        pendingVideoBytes = picked.files.single.bytes;
        pendingVideoName = picked.files.single.name;
      });
    }
  }

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && pendingVideoBytes == null) return;
    final displayText = text.isNotEmpty ? text : "Analyse cette vidéo";
    setState(() {
      messages.add({"role": "user", "content": displayText, "video_filename": pendingVideoName});
      isLoading = true;
    });
    _controller.clear();
    final videoBytes = pendingVideoBytes;
    final videoName = pendingVideoName;
    pendingVideoBytes = null;
    pendingVideoName = null;
    _scrollToBottom();

    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://127.0.0.1:8000/conversations/${widget.convId}/chat'));
      request.fields['message'] = text.isNotEmpty ? text : "Analyse cette vidéo et donne-moi des conseils détaillés";
      if (videoBytes != null && videoName != null) {
        request.files.add(http.MultipartFile.fromBytes('file', videoBytes, filename: videoName));
      }
      var response = await request.send();
      var body = await response.stream.bytesToString();
      final json = jsonDecode(body);

      String assistantContent = json['response'] ?? '';
      if (json['video_data'] != null) {
        final v = json['video_data'];
        assistantContent = "📊 **Données bioméchaniques**\n\n"
            "| Métrique | Gauche | Droite |\n"
            "|----------|--------|--------|\n"
            "| Genou min | ${v['knee_min_left']}° | ${v['knee_min_right']}° |\n"
            "| Hanche moy | ${v['hip_avg_left']}° | ${v['hip_avg_right']}° |\n"
            "| Dos moy | ${v['back_avg']}° | - |\n"
            "| Symétrie | ${v['symmetry']}° | - |\n"
            "| Reps | ${v['reps']} | - |\n\n"
            + assistantContent;
      }

      setState(() {
        messages.add({"role": "assistant", "content": assistantContent, "video_filename": null});
        isLoading = false;
      });

      if (messages.length == 2) {
        widget.onTitleUpdate(displayText.length > 40 ? displayText.substring(0, 40) + '...' : displayText);
      }
      _scrollToBottom();
    } catch (e) {
      setState(() {
        messages.add({"role": "assistant", "content": "Erreur de connexion au serveur.", "video_filename": null});
        isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: messages.isEmpty && !isLoading
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.chat_bubble_outline, size: 36, color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 12),
                Text("Pose une question ou envoie une vidéo", style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14)),
              ]))
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                itemCount: messages.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: kOrange.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.psychology, size: 14, color: kOrange)),
                        const SizedBox(width: 10),
                        Text("Coach en train de réfléchir...", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
                        const SizedBox(width: 10),
                        const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: kOrange)),
                      ]),
                    );
                  }
                  final msg = messages[index];
                  final isUser = msg['role'] == 'user';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: kOrange.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.psychology, size: 14, color: kOrange)),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isUser ? kOrange : kCard,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isUser ? 16 : 4),
                                bottomRight: Radius.circular(isUser ? 4 : 16),
                              ),
                              border: isUser ? null : Border.all(color: kBorder),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (msg['video_filename'] != null && (msg['video_filename'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(children: [
                                    const Icon(Icons.videocam, size: 13, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Flexible(child: Text(msg['video_filename'] as String, style: const TextStyle(fontSize: 11, color: Colors.white70))),
                                  ]),
                                ),
                              isUser
                                  ? SelectableText(msg['content'] as String, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5))
                                  : SelectionArea(child: MarkdownBody(
                                      data: msg['content'] as String,
                                      styleSheet: MarkdownStyleSheet(
                                        p: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85), height: 1.5),
                                        strong: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                                        listBullet: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85)),
                                        tableHead: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        tableBody: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                                        tableBorder: TableBorder.all(color: Colors.white12),
                                        tableColumnWidth: const FlexColumnWidth(),
                                      ),
                                    )),
                            ]),
                          ),
                        ),
                        if (isUser) const SizedBox(width: 10),
                      ],
                    ),
                  );
                },
              ),
      ),

      // Zone saisie
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: kSidebar, border: Border(top: BorderSide(color: kBorder))),
        child: Column(children: [
          if (pendingVideoName != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: kOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: kOrange.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.videocam, size: 15, color: kOrange),
                const SizedBox(width: 8),
                Expanded(child: Text(pendingVideoName!, style: const TextStyle(fontSize: 12, color: Colors.white70))),
                Clickable(
                  onTap: () => setState(() { pendingVideoBytes = null; pendingVideoName = null; }),
                  child: Icon(Icons.close, size: 15, color: Colors.white.withOpacity(0.3)),
                ),
              ]),
            ),
          Row(children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: IconButton(onPressed: pickVideo, icon: const Icon(Icons.videocam_outlined, color: kOrange, size: 22), tooltip: "Envoyer une vidéo"),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 5,
                minLines: 1,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: "Pose une question à ton coach...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
                  filled: true,
                  fillColor: kBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kOrange, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Clickable(
              onTap: () => sendMessage(),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: isLoading ? kOrange.withOpacity(0.3) : kOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ]),
        ]),
      ),
    ]);
  }
}