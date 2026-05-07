import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:typed_data';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF), brightness: Brightness.dark),
        useMaterial3: true,
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
  int _currentIndex = 0;
  String selectedObjectif = "force";

  final List<Map<String, String>> objectifs = [
    {"key": "force", "label": "Force", "emoji": "💪"},
    {"key": "fessiers", "label": "Fessiers", "emoji": "🍑"},
    {"key": "quadriceps", "label": "Quadriceps", "emoji": "🦵"},
    {"key": "endurance", "label": "Endurance", "emoji": "🏃"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: _currentIndex == 0
          ? AnalysePage(selectedObjectif: selectedObjectif, objectifs: objectifs, onObjectifChanged: (val) => setState(() => selectedObjectif = val))
          : ChatPage(selectedObjectif: selectedObjectif),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: const Color(0xFF1A1A2E), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF6C63FF),
          unselectedItemColor: Colors.white38,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.videocam_outlined), activeIcon: Icon(Icons.videocam), label: "Analyse"),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: "Coach IA"),
          ],
        ),
      ),
    );
  }
}

// ===================== PAGE ANALYSE =====================

class AnalysePage extends StatefulWidget {
  final String selectedObjectif;
  final List<Map<String, String>> objectifs;
  final Function(String) onObjectifChanged;
  const AnalysePage({super.key, required this.selectedObjectif, required this.objectifs, required this.onObjectifChanged});
  @override
  State<AnalysePage> createState() => _AnalysePageState();
}

class _AnalysePageState extends State<AnalysePage> {
  String videoName = "";
  bool isLoading = false;
  Uint8List? videoBytes;
  Map<String, dynamic>? analysisData;

  Future<void> pickVideo() async {
    FilePickerResult? picked = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
    if (picked != null) {
      setState(() { videoName = picked.files.single.name; videoBytes = picked.files.single.bytes; analysisData = null; });
    }
  }

  Future<void> uploadVideo() async {
    if (videoBytes == null) return;
    setState(() { isLoading = true; analysisData = null; });
    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://127.0.0.1:8000/upload/?objectif=${widget.selectedObjectif}'));
      request.files.add(http.MultipartFile.fromBytes('file', videoBytes!, filename: videoName));
      var response = await request.send();
      var body = await response.stream.bytesToString();
      setState(() { analysisData = jsonDecode(body); isLoading = false; });
    } catch (e) {
      setState(() { analysisData = {"error": "Erreur de connexion."}; isLoading = false; });
    }
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6), Expanded(child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)))]),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      ]),
    );
  }

  Widget _buildResults() {
    if (analysisData == null) return const SizedBox();
    if (analysisData!.containsKey('error')) {
      return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF2E1A1A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.withOpacity(0.4))), child: Text(analysisData!['error'], style: const TextStyle(color: Colors.white)));
    }
    final d = analysisData!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9C8FFF)]), borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          const Icon(Icons.analytics, color: Colors.white, size: 28), const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Analyse complète", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(videoName, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      _statCard("RÉPÉTITIONS", "${d['reps']} reps", Icons.repeat, const Color(0xFF6C63FF)),
      const SizedBox(height: 12),
      const Text("ANGLES GENOU", style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: _statCard("GAUCHE MIN", "${d['knee_min_left']}°", Icons.rotate_left, const Color(0xFF4CAF50))), const SizedBox(width: 10), Expanded(child: _statCard("DROIT MIN", "${d['knee_min_right']}°", Icons.rotate_right, const Color(0xFF4CAF50)))]),
      const SizedBox(height: 12),
      const Text("ANGLES HANCHE", style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: _statCard("GAUCHE MOY", "${d['hip_avg_left']}°", Icons.rotate_left, const Color(0xFFFF9800))), const SizedBox(width: 10), Expanded(child: _statCard("DROIT MOY", "${d['hip_avg_right']}°", Icons.rotate_right, const Color(0xFFFF9800)))]),
      const SizedBox(height: 12),
      const Text("POSTURE", style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: _statCard("ANGLE DOS", "${d['back_avg']}°", Icons.accessibility_new, const Color(0xFF2196F3))), const SizedBox(width: 10), Expanded(child: _statCard("SYMÉTRIE", "${d['symmetry']}°", Icons.compare_arrows, const Color(0xFF2196F3)))]),
      const SizedBox(height: 12),
      const Text("STABILITÉ GENOUX", style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: _statCard("GAUCHE", "${d['knee_stability_left']}", Icons.show_chart, const Color(0xFFE91E63))), const SizedBox(width: 10), Expanded(child: _statCard("DROIT", "${d['knee_stability_right']}", Icons.show_chart, const Color(0xFFE91E63)))]),
      const SizedBox(height: 24),
      if (d['coaching'] != null)
        Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.4))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.psychology, color: Color(0xFF6C63FF), size: 20)),
              const SizedBox(width: 12),
              const Text("Coaching IA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ]),
            const SizedBox(height: 16),
            SelectionArea(
              child: MarkdownBody(
                data: d['coaching'],
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85), height: 1.6),
                  strong: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                  listBullet: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85)),
                ),
              ),
            ),
          ]),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.fitness_center, size: 48, color: Color(0xFF6C63FF))),
          const SizedBox(height: 16),
          const Text("Gym AI Coach", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text("Analyse ta posture en quelques secondes", style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
          const SizedBox(height: 30),
          const Align(alignment: Alignment.centerLeft, child: Text("TON OBJECTIF", style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w600, letterSpacing: 1))),
          const SizedBox(height: 10),
          Row(children: widget.objectifs.map((o) {
            final isSelected = widget.selectedObjectif == o['key'];
            return Expanded(child: GestureDetector(
              onTap: () => widget.onObjectifChanged(o['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? const Color(0xFF6C63FF) : Colors.white.withOpacity(0.1))),
                child: Column(children: [
                  Text(o['emoji']!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(o['label']!, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.white54, fontWeight: FontWeight.w600)),
                ]),
              ),
            ));
          }).toList()),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: pickVideo,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(color: videoBytes != null ? const Color(0xFF6C63FF).withOpacity(0.15) : const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(20), border: Border.all(color: videoBytes != null ? const Color(0xFF6C63FF) : Colors.white.withOpacity(0.1), width: 1.5)),
              child: Column(children: [
                Icon(videoBytes != null ? Icons.check_circle_outline : Icons.video_library_outlined, size: 40, color: videoBytes != null ? const Color(0xFF6C63FF) : Colors.white.withOpacity(0.4)),
                const SizedBox(height: 12),
                Text(videoBytes != null ? videoName : "Appuie pour importer une vidéo", style: TextStyle(fontSize: 14, color: videoBytes != null ? Colors.white : Colors.white.withOpacity(0.4), fontWeight: videoBytes != null ? FontWeight.w600 : FontWeight.normal), textAlign: TextAlign.center),
                if (videoBytes != null) ...[const SizedBox(height: 6), Text("Appuie pour changer", style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)))],
                const SizedBox(height: 8),
                Text("💡 Pour une analyse optimale, filme-toi de profil", style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3)), textAlign: TextAlign.center),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton(
              onPressed: videoBytes == null || isLoading ? null : uploadVideo,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), disabledBackgroundColor: const Color(0xFF6C63FF).withOpacity(0.3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: isLoading
                  ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)), SizedBox(width: 12), Text("Analyse en cours...", style: TextStyle(color: Colors.white, fontSize: 16))])
                  : const Text("Analyser", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 32),
          _buildResults(),
        ]),
      ),
    );
  }
}

// ===================== PAGE CHAT =====================

class ChatPage extends StatefulWidget {
  final String selectedObjectif;
  const ChatPage({super.key, required this.selectedObjectif});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  bool isLoading = false;
  Uint8List? pendingVideoBytes;
  String? pendingVideoName;

  Future<void> pickVideo() async {
    FilePickerResult? picked = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
    if (picked != null) {
      setState(() { pendingVideoBytes = picked.files.single.bytes; pendingVideoName = picked.files.single.name; });
    }
  }

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && pendingVideoBytes == null) return;
    setState(() {
      messages.add({"role": "user", "text": text.isNotEmpty ? text : "Analyse cette vidéo", "video": pendingVideoName});
      isLoading = true;
    });
    _controller.clear();
    final videoBytes = pendingVideoBytes;
    final videoName = pendingVideoName;
    pendingVideoBytes = null;
    pendingVideoName = null;
    _scrollToBottom();
    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://127.0.0.1:8000/chat/'));
      request.fields['message'] = text.isNotEmpty ? text : "Analyse cette vidéo et donne-moi des conseils";
      request.fields['objectif'] = widget.selectedObjectif;
      if (videoBytes != null && videoName != null) {
        request.files.add(http.MultipartFile.fromBytes('file', videoBytes, filename: videoName));
      }
      var response = await request.send();
      var body = await response.stream.bytesToString();
      final json = jsonDecode(body);
      setState(() { messages.add({"role": "assistant", "text": json['response']}); isLoading = false; });
      _scrollToBottom();
    } catch (e) {
      setState(() { messages.add({"role": "assistant", "text": "Erreur de connexion au serveur."}); isLoading = false; });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> resetChat() async {
    await http.delete(Uri.parse('http://127.0.0.1:8000/chat/reset'));
    setState(() => messages.clear());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(color: const Color(0xFF1A1A2E), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.psychology, color: Color(0xFF6C63FF), size: 20)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Coach IA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("Spécialiste musculation & biomécanique", style: TextStyle(fontSize: 11, color: Colors.white38)),
            ])),
            IconButton(onPressed: resetChat, icon: const Icon(Icons.refresh, color: Colors.white38), tooltip: "Réinitialiser"),
          ]),
        ),

        // Messages
        Expanded(
          child: messages.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 12),
                  Text("Pose une question à ton coach IA\nou envoie une vidéo à analyser", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14), textAlign: TextAlign.center),
                ]))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          SizedBox(width: 12),
                          SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF))),
                          SizedBox(width: 12),
                          Text("Coach en train de réfléchir...", style: TextStyle(color: Colors.white38, fontSize: 13)),
                        ]),
                      );
                    }
                    final msg = messages[index];
                    final isUser = msg['role'] == 'user';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser) ...[
                            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.psychology, size: 16, color: Color(0xFF6C63FF))),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isUser ? const Color(0xFF6C63FF) : const Color(0xFF1A1A2E),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                                  bottomRight: Radius.circular(isUser ? 4 : 18),
                                ),
                                border: isUser ? null : Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                if (msg['video'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(children: [
                                      const Icon(Icons.videocam, size: 14, color: Colors.white70),
                                      const SizedBox(width: 4),
                                      Flexible(child: Text(msg['video'], style: const TextStyle(fontSize: 11, color: Colors.white70))),
                                    ]),
                                  ),
                                isUser
                                    ? SelectableText(msg['text'], style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5))
                                    : SelectionArea(
                                        child: MarkdownBody(
                                          data: msg['text'],
                                          styleSheet: MarkdownStyleSheet(
                                            p: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85), height: 1.5),
                                            strong: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                                            listBullet: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85)),
                                          ),
                                        ),
                                      ),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Zone saisie
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF1A1A2E), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
          child: Column(children: [
            if (pendingVideoName != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3))),
                child: Row(children: [
                  const Icon(Icons.videocam, size: 16, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(pendingVideoName!, style: const TextStyle(fontSize: 12, color: Colors.white70))),
                  GestureDetector(onTap: () => setState(() { pendingVideoBytes = null; pendingVideoName = null; }), child: const Icon(Icons.close, size: 16, color: Colors.white38)),
                ]),
              ),
            Row(children: [
              IconButton(onPressed: pickVideo, icon: const Icon(Icons.videocam_outlined, color: Color(0xFF6C63FF)), tooltip: "Envoyer une vidéo"),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 5,
                  minLines: 1,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: "Pose une question à ton coach...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFF0F0F1A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isLoading ? null : sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: isLoading ? const Color(0xFF6C63FF).withOpacity(0.3) : const Color(0xFF6C63FF), shape: BoxShape.circle),
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}