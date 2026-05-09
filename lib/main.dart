import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

const kOrange = Color(0xFFFF6B2B);
const kBg = Color(0xFF0A0A0A);
const kCard = Color(0xFF151515);
const kCard2 = Color(0xFF1E1E1E);
const kBorder = Color(0xFF2A2A2A);
const kText = Colors.white;
const kTextDim = Color(0xFF888888);
const String kBaseUrl = 'https://gym-ia-n9tf.onrender.com';

// Génère un device_id unique par appareil
Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  String? deviceId = prefs.getString('device_id');
  if (deviceId == null) {
    deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
    await prefs.setString('device_id', deviceId);
  }
  return deviceId;
}

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
      theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: kBg, useMaterial3: true),
      home: const RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});
  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _currentIndex = 0;
  Map<String, String> userData = {};
  String deviceId = '';

  @override
  void initState() {
    super.initState();
    _initDeviceId();
  }

  Future<void> _initDeviceId() async {
    final id = await getDeviceId();
    setState(() => deviceId = id);
    loadUserData();
  }

  Future<void> loadUserData() async {
    if (deviceId.isEmpty) return;
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/user-data/'),
        headers: {'x-device-id': deviceId},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() => userData = data.map((k, v) => MapEntry(k, v.toString())));
      }
    } catch (e) {
      setState(() => userData = {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (deviceId.isEmpty) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator(color: kOrange)),
      );
    }
    return Scaffold(
      backgroundColor: kBg,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(userData: userData, onUserDataChanged: loadUserData, deviceId: deviceId),
          CoachPage(onMessageSent: loadUserData, deviceId: deviceId),
          TrainingPage(userData: userData),
          NutritionPage(userData: userData),
          ProgressPage(userData: userData),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    final items = [
      {"icon": Icons.home_rounded, "label": "Accueil"},
      {"icon": Icons.psychology_rounded, "label": "Coach IA"},
      {"icon": Icons.fitness_center_rounded, "label": "Training"},
      {"icon": Icons.restaurant_rounded, "label": "Nutrition"},
      {"icon": Icons.bar_chart_rounded, "label": "Progrès"},
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((e) {
            final isActive = _currentIndex == e.key;
            return Clickable(
              onTap: () => setState(() => _currentIndex = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: isActive ? kOrange.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(18)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(e.value['icon'] as IconData, color: isActive ? kOrange : kTextDim, size: 22),
                  const SizedBox(height: 3),
                  Text(e.value['label'] as String, style: TextStyle(fontSize: 10, color: isActive ? kOrange : kTextDim, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ===================== PAGE ACCUEIL =====================

class HomePage extends StatefulWidget {
  final Map<String, String> userData;
  final VoidCallback onUserDataChanged;
  final String deviceId;
  const HomePage({super.key, required this.userData, required this.onUserDataChanged, required this.deviceId});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final TextEditingController _chatController = TextEditingController();
  String _currentMessage = "";

  @override
  void initState() {
    super.initState();
    _loadAIMessage();
  }

  Future<void> _loadAIMessage() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uri = Uri.parse('$kBaseUrl/daily-message/?t=$timestamp');
      final response = await http.get(uri, headers: {'x-device-id': widget.deviceId});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final msg = data['message']?.toString() ?? '';
        if (msg.isNotEmpty && mounted) {
          setState(() => _currentMessage = msg);
        }
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  String _levelShort(String level) {
    if (level == 'debutant') return 'Déb.';
    if (level == 'intermediaire') return 'Inter.';
    if (level == 'avance') return 'Avancé';
    return level;
  }

  Widget _pill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: kOrange),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(bottom: false, child: _buildScrollContent());
  }

  Widget _buildScrollContent() {
    final name = widget.userData['name'] ?? '';
    final weight = widget.userData['weight'] ?? '--';
    final sessions = widget.userData['sessions_per_week'] ?? '--';
    final squat = widget.userData['squat_weight'] ?? '--';
    final streak = widget.userData['streak'] ?? '--';
    final lastScore = widget.userData['last_squat_score'] ?? '--';
    final lastReps = widget.userData['last_squat_reps'] ?? '--';
    final lastDate = widget.userData['last_squat_date'] ?? '';
    final age = widget.userData['age'] ?? '';
    final height = widget.userData['height'] ?? '';
    final level = widget.userData['level'] ?? '';

    List<Map<String, dynamic>> weightHistory = [];
    try {
      final raw = widget.userData['weight_history'] ?? '[]';
      weightHistory = (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {}

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Clickable(
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: kBg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: SizedBox(width: 500, height: 600, child: ProfilePage(userData: widget.userData, deviceId: widget.deviceId)),
                        ),
                      );
                      widget.onUserDataChanged();
                      _loadAIMessage();
                    },
                    child: Container(width: 36, height: 36, decoration: BoxDecoration(color: kCard2, shape: BoxShape.circle, border: Border.all(color: kBorder)), child: const Icon(Icons.person_rounded, color: kTextDim, size: 17)),
                  ),
                ]),
                const Spacer(),
                _currentMessage.isEmpty
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: kOrange, strokeWidth: 1.5))
                    : Text(_currentMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kText, height: 1.4, letterSpacing: -0.5)),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        style: const TextStyle(color: kText, fontSize: 15),
                        maxLines: 1,
                        decoration: InputDecoration(
                          hintText: "Pose une question...",
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        ),
                        onSubmitted: (val) { if (val.trim().isNotEmpty) _chatController.clear(); },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Clickable(
                        onTap: () => _chatController.clear(),
                        child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.send_rounded, color: Colors.white, size: 16)),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                  children: [
                    _pill("Analyser mon squat", Icons.videocam_rounded),
                    _pill("Améliorer ma technique", Icons.fitness_center_rounded),
                    _pill("Augmenter la charge ?", Icons.trending_up_rounded),
                    _pill("Programme sur mesure", Icons.bolt_rounded),
                  ],
                ),
                const Spacer(),
                Column(children: [
                  Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withOpacity(0.15), size: 22),
                  Text("Défiler pour voir tes stats", style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.15))),
                ]),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("MON PROFIL", style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                  const SizedBox(height: 14),
                  Row(children: [
                    _compactStat("Poids", "$weight kg", Icons.monitor_weight_outlined, Colors.blue),
                    Container(width: 1, height: 40, color: kBorder, margin: const EdgeInsets.symmetric(horizontal: 4)),
                    _compactStat("Taille", height.isNotEmpty ? "${height}cm" : '--', Icons.height_rounded, const Color(0xFF4CAF50)),
                    Container(width: 1, height: 40, color: kBorder, margin: const EdgeInsets.symmetric(horizontal: 4)),
                    _compactStat("Âge", age.isNotEmpty ? "$age ans" : '--', Icons.cake_rounded, Colors.purple),
                    Container(width: 1, height: 40, color: kBorder, margin: const EdgeInsets.symmetric(horizontal: 4)),
                    _compactStat("Niveau", level.isNotEmpty ? _levelShort(level) : '--', Icons.star_rounded, Colors.amber),
                  ]),
                  if (weightHistory.length >= 2) ...[
                    const SizedBox(height: 20),
                    const Text("ÉVOLUTION DU POIDS", style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    SizedBox(height: 80, width: double.infinity, child: CustomPaint(painter: WeightChartPainter(weightHistory))),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(weightHistory.first['date'] ?? '', style: const TextStyle(fontSize: 10, color: kTextDim)),
                      Text(weightHistory.last['date'] ?? '', style: const TextStyle(fontSize: 10, color: kTextDim)),
                    ]),
                  ],
                ]),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("MES PERFS", style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                  const SizedBox(height: 14),
                  Row(children: [
                    _compactStat("Séances", sessions, Icons.bolt_rounded, kOrange),
                    Container(width: 1, height: 40, color: kBorder, margin: const EdgeInsets.symmetric(horizontal: 4)),
                    _compactStat("Squat", "$squat kg", Icons.fitness_center_rounded, const Color(0xFF4CAF50)),
                    Container(width: 1, height: 40, color: kBorder, margin: const EdgeInsets.symmetric(horizontal: 4)),
                    _compactStat("Streak", "$streak j 🔥", Icons.local_fire_department_rounded, Colors.amber),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),
              _buildWeekWidget(),
              const SizedBox(height: 20),
              if (lastScore != '--') ...[
                _buildLastAnalysis(lastScore, lastReps, lastDate),
                const SizedBox(height: 20),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _compactStat(String label, String value, IconData icon, Color color) {
    return Expanded(child: Column(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kText), overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: kTextDim)),
    ]));
  }

  Widget _buildWeekWidget() {
    final days = ["L", "M", "M", "J", "V", "S", "D"];
    final done = [true, true, false, true, false, false, false];
    final today = DateTime.now().weekday - 1;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Cette semaine", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kText)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.asMap().entries.map((e) {
            final isToday = e.key == today;
            final isDone = done[e.key];
            return Column(children: [
              Text(e.value, style: TextStyle(fontSize: 11, color: isToday ? kOrange : kTextDim, fontWeight: isToday ? FontWeight.w700 : FontWeight.normal)),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: isDone ? kOrange : isToday ? kOrange.withOpacity(0.1) : kCard2,
                  shape: BoxShape.circle,
                  border: Border.all(color: isToday ? kOrange : kBorder, width: isToday ? 1.5 : 1),
                ),
                child: isDone ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
              ),
            ]);
          }).toList(),
        ),
      ]),
    );
  }

  Widget _buildLastAnalysis(String score, String reps, String date) {
    final scoreInt = int.tryParse(score) ?? 0;
    final color = scoreInt >= 80 ? const Color(0xFF4CAF50) : scoreInt >= 60 ? kOrange : Colors.red;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Container(width: 50, height: 50, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(score, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Dernière analyse squat", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kText)),
          const SizedBox(height: 2),
          Text("$reps reps · $date", style: const TextStyle(fontSize: 12, color: kTextDim)),
        ])),
        const Text("/100", style: TextStyle(fontSize: 12, color: kTextDim)),
      ]),
    );
  }
}

// ===================== COURBE POIDS =====================

class WeightChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  WeightChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final weights = data.map((e) => (e['weight'] as num).toDouble()).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b) - 1;
    final maxW = weights.reduce((a, b) => a > b ? a : b) + 1;
    final range = maxW - minW == 0 ? 1.0 : maxW - minW;

    final paint = Paint()..color = kOrange..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [kOrange.withOpacity(0.25), kOrange.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((weights[i] - minW) / range * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) / (data.length - 1) * size.width;
        final prevY = size.height - ((weights[i - 1] - minW) / range * size.height);
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
        fillPath.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = kOrange..style = PaintingStyle.fill;
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((weights[i] - minW) / range * size.height);
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ===================== PAGE COACH IA =====================

class CoachPage extends StatefulWidget {
  final VoidCallback onMessageSent;
  final String deviceId;
  const CoachPage({super.key, required this.onMessageSent, required this.deviceId});
  @override
  State<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends State<CoachPage> {
  List<Map<String, dynamic>> conversations = [];
  int? activeConvId;
  bool sidebarOpen = true;
  String? _pendingSuggestion;

  @override
  void initState() {
    super.initState();
    loadConversations();
  }

  Map<String, String> get _headers => {'x-device-id': widget.deviceId};

  Future<void> loadConversations() async {
    try {
      final response = await http.get(Uri.parse('$kBaseUrl/conversations/'), headers: _headers);
      final data = jsonDecode(response.body) as List;
      setState(() => conversations = data.map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (e) {}
  }

  Future<void> createNewConversation({String? suggestion}) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$kBaseUrl/conversations/'));
      request.headers.addAll(_headers);
      request.fields['objectif'] = 'general';
      request.fields['title'] = suggestion ?? 'Nouvelle conversation';
      var response = await request.send();
      var body = await response.stream.bytesToString();
      final data = jsonDecode(body);
      setState(() {
        conversations.insert(0, Map<String, dynamic>.from(data));
        activeConvId = data['id'];
        _pendingSuggestion = suggestion;
      });
    } catch (e) {}
  }

  Future<void> deleteConversation(int id) async {
    try {
      await http.delete(Uri.parse('$kBaseUrl/conversations/$id'), headers: _headers);
      setState(() {
        conversations.removeWhere((c) => c['id'] == id);
        if (activeConvId == id) activeConvId = null;
      });
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: sidebarOpen ? 240 : 0,
          child: sidebarOpen ? _buildSidebar() : const SizedBox(),
        ),
        Expanded(
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFF111111), border: Border(bottom: BorderSide(color: kBorder))),
              child: Row(children: [
                MouseRegion(cursor: SystemMouseCursors.click, child: IconButton(onPressed: () => setState(() => sidebarOpen = !sidebarOpen), icon: Icon(Icons.menu_rounded, color: Colors.white.withOpacity(0.4), size: 20))),
                const SizedBox(width: 6),
                const Icon(Icons.psychology_rounded, color: kOrange, size: 18),
                const SizedBox(width: 8),
                const Text("Coach IA", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kText)),
                const Spacer(),
                MouseRegion(cursor: SystemMouseCursors.click, child: IconButton(onPressed: () => createNewConversation(), icon: const Icon(Icons.edit_outlined, color: kOrange, size: 18))),
              ]),
            ),
            Expanded(
              child: activeConvId == null
                  ? _buildWelcome()
                  : ChatView(
                      key: ValueKey(activeConvId),
                      convId: activeConvId!,
                      deviceId: widget.deviceId,
                      initialMessage: _pendingSuggestion,
                      onTitleUpdate: (title) {
                        setState(() {
                          _pendingSuggestion = null;
                          final idx = conversations.indexWhere((c) => c['id'] == activeConvId);
                          if (idx != -1) conversations[idx]['title'] = title;
                        });
                      },
                      onMessageSent: widget.onMessageSent,
                    ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF111111), border: Border(right: BorderSide(color: kBorder))),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => createNewConversation(),
              icon: const Icon(Icons.add_rounded, size: 15),
              label: const Text("Nouveau chat", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(alignment: Alignment.centerLeft, child: Text("RÉCENT", style: TextStyle(fontSize: 10, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2))),
        ),
        Expanded(
          child: conversations.isEmpty
              ? Center(child: Text("Aucune conversation", style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 12)))
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        decoration: BoxDecoration(color: isActive ? kOrange.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: isActive ? kOrange.withOpacity(0.3) : Colors.transparent)),
                        child: Row(children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 13, color: isActive ? kOrange : const Color(0xFF555555)),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(conv['title'] ?? 'Conversation', style: TextStyle(fontSize: 12, color: isActive ? Colors.white : const Color(0xFF888888), fontWeight: isActive ? FontWeight.w600 : FontWeight.normal), overflow: TextOverflow.ellipsis),
                            Text(conv['updated_at'] ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF444444))),
                          ])),
                          Clickable(onTap: () => deleteConversation(conv['id']), child: Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.close_rounded, size: 12, color: Colors.white.withOpacity(0.2)))),
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
      {"icon": Icons.videocam_rounded, "text": "Analyse mon squat"},
      {"icon": Icons.fitness_center_rounded, "text": "Programme pour gagner en force"},
      {"icon": Icons.compare_arrows_rounded, "text": "Améliorer ma profondeur de squat"},
      {"icon": Icons.monitor_heart_outlined, "text": "Puis-je augmenter la charge ?"},
      {"icon": Icons.lightbulb_outline_rounded, "text": "Quels muscles travaille le squat ?"},
      {"icon": Icons.schedule_rounded, "text": "Combien de séances par semaine ?"},
    ];
    return Column(children: [
      Expanded(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: kOrange.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: kOrange.withOpacity(0.2))), child: const Icon(Icons.psychology_rounded, size: 40, color: kOrange)),
              const SizedBox(height: 20),
              const Text("Coach IA", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kText)),
              const SizedBox(height: 6),
              Text("Ton coach sportif personnel", style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.3))),
              const SizedBox(height: 32),
              Wrap(
                spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                children: suggestions.map((s) => Clickable(
                  onTap: () => createNewConversation(suggestion: s['text'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(s['icon'] as IconData, size: 14, color: kOrange),
                      const SizedBox(width: 8),
                      Text(s['text'] as String, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65))),
                    ]),
                  ),
                )).toList(),
              ),
            ]),
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
        decoration: BoxDecoration(color: const Color(0xFF111111), border: Border(top: BorderSide(color: kBorder))),
        child: Row(children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: kText, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Pose une question à ton coach...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
                filled: true, fillColor: kCard2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kOrange, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (val) { if (val.trim().isNotEmpty) createNewConversation(suggestion: val.trim()); },
            ),
          ),
          const SizedBox(width: 8),
          Clickable(
            onTap: () => createNewConversation(),
            child: Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.send_rounded, color: Colors.white, size: 17)),
          ),
        ]),
      ),
    ]);
  }
}

// ===================== PAGE TRAINING =====================

class TrainingPage extends StatelessWidget {
  final Map<String, String> userData;
  const TrainingPage({super.key, required this.userData});

  final List<Map<String, dynamic>> programs = const [
    {"title": "Prise de masse", "desc": "Gagner du muscle efficacement", "icon": Icons.trending_up_rounded, "color": Color(0xFFFF6B2B), "sessions": "4x/semaine", "duration": "60 min"},
    {"title": "Sèche", "desc": "Perdre du gras en gardant le muscle", "icon": Icons.local_fire_department_rounded, "color": Color(0xFFFF4444), "sessions": "5x/semaine", "duration": "45 min"},
    {"title": "Force", "desc": "Augmenter tes charges maximales", "icon": Icons.bolt_rounded, "color": Color(0xFF4CAF50), "sessions": "3x/semaine", "duration": "75 min"},
    {"title": "Endurance", "desc": "Améliorer ton cardio", "icon": Icons.directions_run_rounded, "color": Color(0xFF2196F3), "sessions": "4x/semaine", "duration": "50 min"},
    {"title": "Débutant", "desc": "Commencer progressivement", "icon": Icons.star_outline_rounded, "color": Color(0xFFFFBB33), "sessions": "3x/semaine", "duration": "40 min"},
    {"title": "Maison", "desc": "Sans équipement", "icon": Icons.home_rounded, "color": Color(0xFF9C27B0), "sessions": "4x/semaine", "duration": "35 min"},
  ];

  @override
  Widget build(BuildContext context) {
    final squat = userData['squat_weight'] ?? '--';
    final bench = userData['bench_weight'] ?? '--';
    final deadlift = userData['deadlift_weight'] ?? '--';

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Entraînements", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kText)),
          const SizedBox(height: 4),
          Text("Choisis ton programme", style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.35))),
          if (squat != '--' || bench != '--' || deadlift != '--') ...[
            const SizedBox(height: 24),
            const Text("MES CHARGES", style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Row(children: [
              if (squat != '--') Expanded(child: _chargeCard("Squat", squat, kOrange)),
              if (squat != '--' && bench != '--') const SizedBox(width: 10),
              if (bench != '--') Expanded(child: _chargeCard("Bench", bench, const Color(0xFF4CAF50))),
              if (bench != '--' && deadlift != '--') const SizedBox(width: 10),
              if (deadlift != '--') Expanded(child: _chargeCard("Deadlift", deadlift, const Color(0xFF2196F3))),
            ]),
          ],
          const SizedBox(height: 24),
          const Text("PROGRAMMES", style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.2),
            itemCount: programs.length,
            itemBuilder: (context, index) {
              final p = programs[index];
              return Clickable(
                onTap: () => showDialog(context: context, builder: (context) => ProgramDetailDialog(program: p)),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (p['color'] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(p['icon'] as IconData, color: p['color'] as Color, size: 20)),
                    const Spacer(),
                    Text(p['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kText)),
                    const SizedBox(height: 2),
                    Text("${p['sessions']} · ${p['duration']}", style: const TextStyle(fontSize: 11, color: kTextDim)),
                  ]),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }

  Widget _chargeCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 11, color: kTextDim, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text("$value kg", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}

class ProgramDetailDialog extends StatelessWidget {
  final Map<String, dynamic> program;
  const ProgramDetailDialog({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    final exercises = ["Squat", "Presse à cuisses", "Fentes", "Leg curl", "Mollets debout"];
    return Dialog(
      backgroundColor: kBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (program['color'] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(14)), child: Icon(program['icon'] as IconData, color: program['color'] as Color, size: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(program['title'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kText)),
                Text(program['desc'] as String, style: const TextStyle(fontSize: 12, color: kTextDim)),
              ])),
              Clickable(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: Color(0xFF555555), size: 20)),
            ]),
            const SizedBox(height: 20),
            const Text("PLANNING", style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 10),
            Row(children: ["L", "M", "M", "J", "V", "S", "D"].asMap().entries.map((e) {
              final active = [0, 2, 4].contains(e.key);
              return Expanded(child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: active ? kOrange : kCard2, borderRadius: BorderRadius.circular(8), border: Border.all(color: active ? kOrange : kBorder)),
                child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : const Color(0xFF555555))),
              ));
            }).toList()),
            const SizedBox(height: 20),
            const Text("EXERCICES", style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 10),
            ...exercises.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
              child: Row(children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(color: kOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Center(child: Text("${e.key + 1}", style: const TextStyle(fontSize: 12, color: kOrange, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 12),
                Expanded(child: Text(e.value, style: const TextStyle(fontSize: 14, color: kText))),
                const Text("4×8", style: TextStyle(fontSize: 12, color: kTextDim)),
              ]),
            )).toList(),
          ]),
        ),
      ),
    );
  }
}

// ===================== PAGE NUTRITION =====================

class NutritionPage extends StatelessWidget {
  final Map<String, String> userData;
  const NutritionPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final calories = userData['calories'] ?? '2400';
    final meals = [
      {"title": "Petit déjeuner", "time": "7h00", "kcal": "520", "protein": "32g", "icon": Icons.wb_sunny_rounded, "color": const Color(0xFFFFBB33), "done": true},
      {"title": "Déjeuner", "time": "12h30", "kcal": "680", "protein": "55g", "icon": Icons.restaurant_rounded, "color": const Color(0xFF4CAF50), "done": true},
      {"title": "Snack", "time": "16h00", "kcal": "220", "protein": "18g", "icon": Icons.apple_rounded, "color": kOrange, "done": false},
      {"title": "Dîner", "time": "19h30", "kcal": "580", "protein": "48g", "icon": Icons.nightlight_rounded, "color": const Color(0xFF6C63FF), "done": false},
    ];
    final totalKcal = 520 + 680;
    final targetKcal = int.tryParse(calories) ?? 2400;
    final progress = totalKcal / targetKcal;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Nutrition", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kText)),
          const SizedBox(height: 4),
          Text("Suis ton alimentation", style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.35))),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
            child: Column(children: [
              Row(children: [
                const Text("Calories aujourd'hui", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kText)),
                const Spacer(),
                Text("$totalKcal / $targetKcal kcal", style: const TextStyle(fontSize: 13, color: kTextDim)),
              ]),
              const SizedBox(height: 14),
              ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), backgroundColor: kBorder, valueColor: const AlwaysStoppedAnimation(kOrange), minHeight: 8)),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _macroChip("Protéines", "87g", const Color(0xFF4CAF50)),
                _macroChip("Glucides", "180g", Colors.blue),
                _macroChip("Lipides", "45g", Colors.amber),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
          const Text("REPAS DU JOUR", style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          ...meals.map((meal) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: (meal['done'] as bool) ? (meal['color'] as Color).withOpacity(0.2) : kBorder)),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (meal['color'] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(meal['icon'] as IconData, color: meal['color'] as Color, size: 20)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(meal['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kText)),
                const SizedBox(height: 2),
                Text("${meal['kcal']} kcal · ${meal['protein']} protéines · ${meal['time']}", style: const TextStyle(fontSize: 12, color: kTextDim)),
              ])),
              if (meal['done'] as bool)
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Color(0xFF4CAF50), size: 14))
              else
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: kCard2, shape: BoxShape.circle, border: Border.all(color: kBorder)), child: const Icon(Icons.add_rounded, color: kTextDim, size: 14)),
            ]),
          )).toList(),
        ]),
      ),
    );
  }

  Widget _macroChip(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: kTextDim)),
    ]);
  }
}

// ===================== PAGE PROGRESSION =====================

class ProgressPage extends StatelessWidget {
  final Map<String, String> userData;
  const ProgressPage({super.key, required this.userData});

  Widget _statCard(String label, String value, String change, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: kTextDim, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kText)),
        const SizedBox(height: 4),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: Text(change, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _exerciseBar(String name, String value, double progress, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(name, style: const TextStyle(fontSize: 13, color: kText, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, color: kTextDim)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), backgroundColor: kBorder, valueColor: AlwaysStoppedAnimation(color), minHeight: 6)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final squat = userData['squat_weight'] ?? '--';
    final bench = userData['bench_weight'] ?? '--';
    final deadlift = userData['deadlift_weight'] ?? '--';
    final weight = userData['weight'] ?? '--';
    final sessions = userData['sessions_per_week'] ?? '--';
    final streak = userData['streak'] ?? '--';
    final lastScore = userData['last_squat_score'] ?? '--';
    final goal = userData['goal'] ?? '';
    double squatProgress = squat != '--' ? (double.tryParse(squat) ?? 0) / 200 : 0.3;
    double benchProgress = bench != '--' ? (double.tryParse(bench) ?? 0) / 150 : 0.3;
    double deadliftProgress = deadlift != '--' ? (double.tryParse(deadlift) ?? 0) / 250 : 0.3;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Progression", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kText)),
          const SizedBox(height: 4),
          Text("Suis tes performances", style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.35))),
          const SizedBox(height: 24),
          const Text("CE MOIS", style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
            children: [
              _statCard("Poids", "$weight kg", "Mis à jour", Colors.blue),
              _statCard("Séances", "$sessions /sem", "Cette semaine", kOrange),
              _statCard("Streak", "$streak jours", "🔥 Continue !", Colors.amber),
              _statCard("Score squat", "$lastScore/100", "Dernière analyse", const Color(0xFF4CAF50)),
            ],
          ),
          const SizedBox(height: 24),
          const Text("MES CHARGES", style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
            child: Column(children: [
              _exerciseBar("Squat", squat != '--' ? "$squat kg" : "Non renseigné", squatProgress, kOrange),
              _exerciseBar("Développé couché", bench != '--' ? "$bench kg" : "Non renseigné", benchProgress, const Color(0xFF4CAF50)),
              _exerciseBar("Soulevé de terre", deadlift != '--' ? "$deadlift kg" : "Non renseigné", deadliftProgress, const Color(0xFF2196F3)),
            ]),
          ),
          const SizedBox(height: 24),
          const Text("RÉSUMÉ IA", style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kOrange.withOpacity(0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: kOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.auto_awesome_rounded, color: kOrange, size: 16)),
                const SizedBox(width: 10),
                const Text("Analyse IA", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kText)),
              ]),
              const SizedBox(height: 12),
              Text(goal.isNotEmpty ? "Objectif : $goal. Continue à travailler et parle à ton coach pour un bilan complet !" : "Parle à ton coach IA pour obtenir un résumé personnalisé de ta semaine.", style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6), height: 1.5)),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.psychology_rounded, size: 15),
                label: const Text("Demander un bilan", style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              ),
            ]),
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
  final VoidCallback onMessageSent;
  final String? initialMessage;
  final String deviceId;
  const ChatView({super.key, required this.convId, required this.onTitleUpdate, required this.onMessageSent, this.initialMessage, required this.deviceId});
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

  Map<String, String> get _headers => {'x-device-id': widget.deviceId};

  @override
  void initState() {
    super.initState();
    loadMessages().then((_) {
      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        _controller.text = widget.initialMessage!;
        sendMessage();
      }
    });
  }

  Future<void> loadMessages() async {
    try {
      final response = await http.get(Uri.parse('$kBaseUrl/conversations/${widget.convId}/messages'), headers: _headers);
      final data = jsonDecode(response.body) as List;
      setState(() => messages = data.map((e) => Map<String, dynamic>.from(e)).toList());
      _scrollToBottom();
    } catch (e) {}
  }

  Future<void> pickVideo() async {
    FilePickerResult? picked = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
    if (picked != null) {
      setState(() { pendingVideoBytes = picked.files.single.bytes; pendingVideoName = picked.files.single.name; });
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
      var request = http.MultipartRequest('POST', Uri.parse('$kBaseUrl/conversations/${widget.convId}/chat'));
      request.headers.addAll(_headers);
      request.fields['message'] = text.isNotEmpty ? text : "Analyse cette vidéo et donne-moi des conseils détaillés";
      final prefs = await SharedPreferences.getInstance();
      final profile = {
        'name': prefs.getString('name') ?? '',
        'age': prefs.getString('age') ?? '',
        'weight': prefs.getString('weight') ?? '',
        'height': prefs.getString('height') ?? '',
        'level': prefs.getString('level') ?? '',
        'goal': prefs.getString('goal') ?? '',
      };
      request.fields['user_profile'] = jsonEncode(profile);
      if (videoBytes != null && videoName != null) {
        request.files.add(http.MultipartFile.fromBytes('file', videoBytes, filename: videoName));
      }
      var response = await request.send();
      var body = await response.stream.bytesToString();
      final json = jsonDecode(body);
      final String assistantContent = json['response'] ?? '';
      setState(() {
        messages.add({"role": "assistant", "content": assistantContent, "video_filename": null});
        isLoading = false;
      });
      if (messages.length == 2) {
        widget.onTitleUpdate(displayText.length > 40 ? displayText.substring(0, 40) + '...' : displayText);
      }
      widget.onMessageSent();
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
                Icon(Icons.chat_bubble_outline_rounded, size: 36, color: Colors.white.withOpacity(0.06)),
                const SizedBox(height: 12),
                Text("Pose une question ou envoie une vidéo", style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14)),
              ]))
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                itemCount: messages.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: kOrange.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.psychology_rounded, size: 13, color: kOrange)),
                        const SizedBox(width: 8),
                        Text("Coach en train de réfléchir...", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
                        const SizedBox(width: 8),
                        const SizedBox(height: 13, width: 13, child: CircularProgressIndicator(strokeWidth: 1.5, color: kOrange)),
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
                          Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: kOrange.withOpacity(0.12), shape: BoxShape.circle), child: const Icon(Icons.psychology_rounded, size: 13, color: kOrange)),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Row(children: [
                                    const Icon(Icons.videocam_rounded, size: 12, color: Colors.white70),
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
                        if (isUser) const SizedBox(width: 8),
                      ],
                    ),
                  );
                },
              ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
        decoration: BoxDecoration(color: const Color(0xFF111111), border: Border(top: BorderSide(color: kBorder))),
        child: Column(children: [
          if (pendingVideoName != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: kOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: kOrange.withOpacity(0.2))),
              child: Row(children: [
                const Icon(Icons.videocam_rounded, size: 14, color: kOrange),
                const SizedBox(width: 8),
                Expanded(child: Text(pendingVideoName!, style: const TextStyle(fontSize: 12, color: Colors.white70))),
                Clickable(onTap: () => setState(() { pendingVideoBytes = null; pendingVideoName = null; }), child: Icon(Icons.close_rounded, size: 14, color: Colors.white.withOpacity(0.3))),
              ]),
            ),
          Row(children: [
            MouseRegion(cursor: SystemMouseCursors.click, child: IconButton(onPressed: pickVideo, icon: const Icon(Icons.videocam_rounded, color: kOrange, size: 20))),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 5, minLines: 1,
                decoration: InputDecoration(
                  hintText: "Pose une question à ton coach...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
                  filled: true, fillColor: kCard2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kOrange, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Clickable(
              onTap: () => sendMessage(),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(color: isLoading ? kOrange.withOpacity(0.3) : kOrange, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 17),
              ),
            ),
          ]),
        ]),
      ),
    ]);
  }
}

// ===================== PAGE PROFIL =====================

class ProfilePage extends StatefulWidget {
  final Map<String, String> userData;
  final String deviceId;
  const ProfilePage({super.key, required this.userData, required this.deviceId});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _goalController = TextEditingController();
  String selectedLevel = "debutant";
  bool saved = false;

  final levels = [
    {"key": "debutant", "label": "Débutant"},
    {"key": "intermediaire", "label": "Intermédiaire"},
    {"key": "avance", "label": "Avancé"},
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userData['name'] ?? '';
    _ageController.text = widget.userData['age'] ?? '';
    _weightController.text = widget.userData['weight'] ?? '';
    _heightController.text = widget.userData['height'] ?? '';
    _goalController.text = widget.userData['goal'] ?? '';
    selectedLevel = widget.userData['level']?.isNotEmpty == true ? widget.userData['level']! : 'debutant';
  }

  Future<void> saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _nameController.text);
    await prefs.setString('age', _ageController.text);
    await prefs.setString('weight', _weightController.text);
    await prefs.setString('height', _heightController.text);
    await prefs.setString('goal', _goalController.text);
    await prefs.setString('level', selectedLevel);

    final data = {
      'name': _nameController.text,
      'age': _ageController.text,
      'weight': _weightController.text,
      'height': _heightController.text,
      'goal': _goalController.text,
      'level': selectedLevel,
    };
    var request = http.MultipartRequest('PUT', Uri.parse('$kBaseUrl/user-data/'));
    request.headers['x-device-id'] = widget.deviceId;
    request.fields['data'] = jsonEncode(data);
    await request.send();
    setState(() => saved = true);
    Future.delayed(const Duration(seconds: 1), () { if (mounted) Navigator.pop(context); });
  }

  Widget _field(String label, TextEditingController controller, {String? hint, TextInputType? type}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF666666), fontWeight: FontWeight.w600, letterSpacing: 0.8)),
      const SizedBox(height: 6),
      TextField(
        controller: controller, keyboardType: type,
        style: const TextStyle(color: kText, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: Color(0xFF444444), fontSize: 14),
          filled: true, fillColor: kCard2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kOrange, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      const SizedBox(height: 16),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.person_rounded, color: kOrange, size: 20)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Mon profil", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kText)),
            Text("Le coach adapte ses conseils à ton profil", style: TextStyle(fontSize: 12, color: kTextDim)),
          ])),
          Clickable(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: Color(0xFF555555), size: 20)),
        ]),
        const SizedBox(height: 24),
        _field("PRÉNOM", _nameController, hint: "Ex: Thomas"),
        Row(children: [
          Expanded(child: _field("ÂGE", _ageController, hint: "25", type: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: _field("POIDS (kg)", _weightController, hint: "80", type: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: _field("TAILLE (cm)", _heightController, hint: "180", type: TextInputType.number)),
        ]),
        const Text("NIVEAU", style: TextStyle(fontSize: 11, color: Color(0xFF666666), fontWeight: FontWeight.w600, letterSpacing: 0.8)),
        const SizedBox(height: 8),
        Row(children: levels.map((l) {
          final isSelected = selectedLevel == l['key'];
          return Expanded(child: Clickable(
            onTap: () => setState(() => selectedLevel = l['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: isSelected ? kOrange : kCard2, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected ? kOrange : kBorder)),
              child: Text(l['label']!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : const Color(0xFF666666), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
            ),
          ));
        }).toList()),
        const SizedBox(height: 16),
        _field("OBJECTIF PRINCIPAL", _goalController, hint: "Ex: Prendre de la masse, perdre du poids..."),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: saveProfile,
            style: ElevatedButton.styleFrom(backgroundColor: saved ? const Color(0xFF4CAF50) : kOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
            child: Text(saved ? "✓ Sauvegardé !" : "Sauvegarder", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}