import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
const String kBaseUrl = 'http://127.0.0.1:8000';

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

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      final response = await http.get(Uri.parse('$kBaseUrl/user-data/'));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      setState(() => userData = data.map((k, v) => MapEntry(k, v.toString())));
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(userData: userData, onUserDataChanged: loadUserData),
          ProgramsPage(userData: userData),
          CoachPage(onMessageSent: loadUserData),
          ProgressPage(userData: userData),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kSidebar, border: Border(top: BorderSide(color: kBorder))),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: kOrange,
          unselectedItemColor: Colors.white24,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Accueil"),
            BottomNavigationBarItem(icon: Icon(Icons.fitness_center_outlined), activeIcon: Icon(Icons.fitness_center), label: "Programmes"),
            BottomNavigationBarItem(icon: Icon(Icons.psychology_outlined), activeIcon: Icon(Icons.psychology), label: "Coach IA"),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: "Progression"),
          ],
        ),
      ),
    );
  }
}

// ===================== PAGE ACCUEIL =====================

class HomePage extends StatelessWidget {
  final Map<String, String> userData;
  final VoidCallback onUserDataChanged;
  const HomePage({super.key, required this.userData, required this.onUserDataChanged});

  Widget _statCard(String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 14, color: color)),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text("$label $unit", style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = userData['name'] ?? 'Athlete';
    final weight = userData['weight'] ?? '--';
    final sessions = userData['sessions_per_week'] ?? '--';
    final streak = userData['streak'] ?? '--';
    final calories = userData['calories'] ?? '--';
    final lastScore = userData['last_squat_score'] ?? '--';
    final lastReps = userData['last_squat_reps'] ?? '--';
    final lastDate = userData['last_squat_date'] ?? '';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Bonjour 👋", style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.4))),
              Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            ]),
            const Spacer(),
            Clickable(
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: kBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: SizedBox(width: 500, height: 600, child: ProfilePage(userData: userData)),
                  ),
                );
                onUserDataChanged();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
                child: const Icon(Icons.person_outline, color: Colors.white54, size: 20),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // Bannière IA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kOrange.withOpacity(0.8), kOrange.withOpacity(0.4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text("Coach IA", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              Text("Prêt pour ta prochaine séance, $name ?", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              if (lastDate.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text("Dernière analyse : Score $lastScore/100 · $lastReps reps · $lastDate", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kOrange, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                child: const Text("Parler au coach", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          const Text("MON PROFIL", style: TextStyle(fontSize: 11, color: Colors.white24, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
            children: [
              _statCard("Poids", weight, "kg", Icons.monitor_weight_outlined, Colors.blue),
              _statCard("Séances", sessions, "/ sem", Icons.bolt, kOrange),
              _statCard("Streak", streak, "jours", Icons.local_fire_department, Colors.amber),
              _statCard("Calories", calories, "kcal", Icons.local_fire_department, Colors.red),
            ],
          ),
          const SizedBox(height: 24),

          // Dernière analyse squat
          if (lastScore != '--') ...[
            const Text("DERNIÈRE ANALYSE SQUAT", style: TextStyle(fontSize: 11, color: Colors.white24, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kOrange.withOpacity(0.3))),
              child: Row(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: kOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text("$lastScore", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kOrange))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Score squat", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text("$lastReps reps · $lastDate", style: const TextStyle(fontSize: 12, color: Colors.white38)),
                ])),
                const Text("/100", style: TextStyle(fontSize: 13, color: Colors.white38)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

// ===================== PAGE PROGRAMMES =====================

class ProgramsPage extends StatelessWidget {
  final Map<String, String> userData;
  const ProgramsPage({super.key, required this.userData});

  final List<Map<String, dynamic>> programs = const [
    {"title": "Prise de masse", "desc": "Gagner du muscle efficacement", "icon": Icons.trending_up, "color": Color(0xFFFF6B2B), "sessions": "4x/semaine"},
    {"title": "Sèche", "desc": "Perdre du gras en gardant le muscle", "icon": Icons.local_fire_department, "color": Color(0xFFFF4444), "sessions": "5x/semaine"},
    {"title": "Force", "desc": "Augmenter tes charges maximales", "icon": Icons.bolt, "color": Color(0xFF4CAF50), "sessions": "3x/semaine"},
    {"title": "Endurance", "desc": "Améliorer ton cardio et ta résistance", "icon": Icons.directions_run, "color": Color(0xFF2196F3), "sessions": "4x/semaine"},
    {"title": "Débutant", "desc": "Commencer le sport progressivement", "icon": Icons.star_outline, "color": Color(0xFFFFBB33), "sessions": "3x/semaine"},
    {"title": "Maison", "desc": "S'entraîner sans équipement", "icon": Icons.home, "color": Color(0xFF9C27B0), "sessions": "4x/semaine"},
  ];

  @override
  Widget build(BuildContext context) {
    final squat = userData['squat_weight'] ?? '--';
    final bench = userData['bench_weight'] ?? '--';
    final deadlift = userData['deadlift_weight'] ?? '--';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Programmes", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text("Choisis ton programme d'entraînement", style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.35))),

          // Mes charges
          if (squat != '--' || bench != '--' || deadlift != '--') ...[
            const SizedBox(height: 24),
            const Text("MES CHARGES", style: TextStyle(fontSize: 11, color: Colors.white24, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Row(children: [
              if (squat != '--') Expanded(child: _chargeCard("Squat", squat, kOrange)),
              if (squat != '--') const SizedBox(width: 10),
              if (bench != '--') Expanded(child: _chargeCard("Développé couché", bench, const Color(0xFF4CAF50))),
              if (bench != '--') const SizedBox(width: 10),
              if (deadlift != '--') Expanded(child: _chargeCard("Soulevé de terre", deadlift, const Color(0xFF2196F3))),
            ]),
          ],

          const SizedBox(height: 24),
          const Text("OBJECTIFS", style: TextStyle(fontSize: 11, color: Colors.white24, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3),
            itemCount: programs.length,
            itemBuilder: (context, index) {
              final p = programs[index];
              return Clickable(
                onTap: () => showDialog(context: context, builder: (context) => ProgramDetailDialog(program: p)),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (p['color'] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(p['icon'] as IconData, color: p['color'] as Color, size: 20)),
                    const Spacer(),
                    Text(p['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(p['sessions'] as String, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35))),
                  ]),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text("NUTRITION", style: TextStyle(fontSize: 11, color: Colors.white24, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          ...[
            {"title": "Bowl protéiné", "kcal": "520 kcal", "protein": "42g protéines", "time": "15 min", "color": Color(0xFF4CAF50)},
            {"title": "Shake masse", "kcal": "680 kcal", "protein": "55g protéines", "time": "5 min", "color": Color(0xFF2196F3)},
            {"title": "Omelette sportive", "kcal": "380 kcal", "protein": "35g protéines", "time": "10 min", "color": kOrange},
          ].map((meal) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
            child: Row(children: [
              Container(width: 4, height: 40, decoration: BoxDecoration(color: meal['color'] as Color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(meal['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 2),
                Text("${meal['kcal']} · ${meal['protein']}", style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35))),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: (meal['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(meal['time'] as String, style: TextStyle(fontSize: 11, color: meal['color'] as Color, fontWeight: FontWeight.w600)),
              ),
            ]),
          )).toList(),
        ]),
      ),
    );
  }

  Widget _chargeCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w600)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (program['color'] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(program['icon'] as IconData, color: program['color'] as Color, size: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(program['title'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(program['desc'] as String, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
              ])),
              Clickable(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.white38, size: 20)),
            ]),
            const SizedBox(height: 20),
            const Text("PLANNING SEMAINE", style: TextStyle(fontSize: 11, color: Colors.white24, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 10),
            Row(children: ["L", "M", "M", "J", "V", "S", "D"].asMap().entries.map((e) {
              final active = [0, 2, 4].contains(e.key);
              return Expanded(child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: active ? kOrange : kCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: active ? kOrange : kBorder)),
                child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : Colors.white24)),
              ));
            }).toList()),
            const SizedBox(height: 20),
            const Text("EXERCICES", style: TextStyle(fontSize: 11, color: Colors.white24, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 10),
            ...exercises.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
              child: Row(children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(color: kOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Center(child: Text("${e.key + 1}", style: const TextStyle(fontSize: 12, color: kOrange, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 12),
                Expanded(child: Text(e.value, style: const TextStyle(fontSize: 14, color: Colors.white))),
                Text("4×8", style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.35))),
              ]),
            )).toList(),
          ]),
        ),
      ),
    );
  }
}

// ===================== PAGE COACH IA =====================

class CoachPage extends StatefulWidget {
  final VoidCallback onMessageSent;
  const CoachPage({super.key, required this.onMessageSent});
  @override
  State<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends State<CoachPage> {
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
      final response = await http.get(Uri.parse('$kBaseUrl/conversations/'));
      final data = jsonDecode(response.body) as List;
      setState(() => conversations = data.map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (e) {}
  }

  Future<void> createNewConversation() async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$kBaseUrl/conversations/'));
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
      await http.delete(Uri.parse('$kBaseUrl/conversations/$id'));
      setState(() {
        conversations.removeWhere((c) => c['id'] == id);
        if (activeConvId == id) activeConvId = null;
      });
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
              decoration: BoxDecoration(color: kSidebar, border: Border(bottom: BorderSide(color: kBorder))),
              child: Row(children: [
                MouseRegion(cursor: SystemMouseCursors.click, child: IconButton(onPressed: () => setState(() => sidebarOpen = !sidebarOpen), icon: Icon(Icons.menu, color: Colors.white.withOpacity(0.4), size: 20))),
                const SizedBox(width: 6),
                const Icon(Icons.psychology, color: kOrange, size: 18),
                const SizedBox(width: 8),
                const Text("Coach IA", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                MouseRegion(cursor: SystemMouseCursors.click, child: IconButton(onPressed: createNewConversation, icon: const Icon(Icons.edit_outlined, color: kOrange, size: 18), tooltip: "Nouveau chat")),
              ]),
            ),
            Expanded(
              child: activeConvId == null ? _buildWelcome() : ChatView(
                key: ValueKey(activeConvId),
                convId: activeConvId!,
                onTitleUpdate: (title) {
                  setState(() {
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
      decoration: const BoxDecoration(color: kSidebar, border: Border(right: BorderSide(color: kBorder))),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: createNewConversation,
              icon: const Icon(Icons.add, size: 15),
              label: const Text("Nouveau chat", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(alignment: Alignment.centerLeft, child: Text("RÉCENT", style: TextStyle(fontSize: 10, color: Colors.white24, fontWeight: FontWeight.w600, letterSpacing: 1.2))),
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
                        decoration: BoxDecoration(color: isActive ? kOrange.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: isActive ? kOrange.withOpacity(0.3) : Colors.transparent)),
                        child: Row(children: [
                          Icon(Icons.chat_bubble_outline, size: 13, color: isActive ? kOrange : Colors.white38),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(conv['title'] ?? 'Conversation', style: TextStyle(fontSize: 12, color: isActive ? Colors.white : Colors.white60, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal), overflow: TextOverflow.ellipsis),
                            Text(conv['updated_at'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.white24)),
                          ])),
                          Clickable(onTap: () => deleteConversation(conv['id']), child: Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.close, size: 12, color: Colors.white.withOpacity(0.2)))),
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
      {"icon": Icons.fitness_center, "text": "Programme pour gagner en force"},
      {"icon": Icons.compare_arrows, "text": "Améliorer ma profondeur de squat"},
      {"icon": Icons.monitor_heart_outlined, "text": "Puis-je augmenter la charge ?"},
      {"icon": Icons.emoji_objects_outlined, "text": "Quels muscles travaille le squat ?"},
      {"icon": Icons.schedule, "text": "Combien de séances par semaine ?"},
    ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: kOrange.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: kOrange.withOpacity(0.3))), child: const Icon(Icons.psychology, size: 40, color: kOrange)),
          const SizedBox(height: 16),
          const Text("Coach IA", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text("Ton coach sportif personnel", style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.3))),
          const SizedBox(height: 28),
          Wrap(
            spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
            children: suggestions.map((s) => Clickable(
              onTap: () => createNewConversation(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(s['icon'] as IconData, size: 14, color: kOrange),
                  const SizedBox(width: 7),
                  Text(s['text'] as String, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65))),
                ]),
              ),
            )).toList(),
          ),
        ]),
      ),
    );
  }
}

// ===================== PAGE PROGRESSION =====================

class ProgressPage extends StatelessWidget {
  final Map<String, String> userData;
  const ProgressPage({super.key, required this.userData});

  Widget _statCard(String label, String value, String change, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35), fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
          child: Text(change, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _exerciseBar(String name, String value, double progress, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(name, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress, backgroundColor: kBorder, valueColor: AlwaysStoppedAnimation(color), minHeight: 6),
        ),
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

    double squatProgress = squat != '--' ? (double.tryParse(squat) ?? 0) / 200 : 0.5;
    double benchProgress = bench != '--' ? (double.tryParse(bench) ?? 0) / 150 : 0.5;
    double deadliftProgress = deadlift != '--' ? (double.tryParse(deadlift) ?? 0) / 250 : 0.5;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Progression", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text("Suis tes performances", style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.35))),
          const SizedBox(height: 24),
          const Text("MON PROFIL", style: TextStyle(fontSize: 11, color: Colors.white24, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
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
          const Text("MES CHARGES", style: TextStyle(fontSize: 11, color: Colors.white24, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
            child: Column(children: [
              _exerciseBar("Squat", squat != '--' ? "$squat kg" : "Non renseigné", squatProgress.clamp(0.0, 1.0), kOrange),
              _exerciseBar("Développé couché", bench != '--' ? "$bench kg" : "Non renseigné", benchProgress.clamp(0.0, 1.0), const Color(0xFF4CAF50)),
              _exerciseBar("Soulevé de terre", deadlift != '--' ? "$deadlift kg" : "Non renseigné", deadliftProgress.clamp(0.0, 1.0), const Color(0xFF2196F3)),
            ]),
          ),
          const SizedBox(height: 24),
          const Text("RÉSUMÉ IA", style: TextStyle(fontSize: 11, color: Colors.white24, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kOrange.withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: kOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.auto_awesome, color: kOrange, size: 16)),
                const SizedBox(width: 8),
                const Text("Analyse de la semaine", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ]),
              const SizedBox(height: 12),
              Text(
                userData['goal'] != null && userData['goal']!.isNotEmpty
                    ? "Objectif : ${userData['goal']}. Continue à travailler et parle à ton coach pour un bilan complet !"
                    : "Parle à ton coach IA pour obtenir un résumé personnalisé de ta semaine.",
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7), height: 1.5),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.psychology, size: 15),
                label: const Text("Demander un bilan complet", style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
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
  const ChatView({super.key, required this.convId, required this.onTitleUpdate, required this.onMessageSent});
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
      final response = await http.get(Uri.parse('$kBaseUrl/conversations/${widget.convId}/messages'));
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
      var request = http.MultipartRequest('POST', Uri.parse('$kBaseUrl/conversations/${widget.convId}/chat'));
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
                Icon(Icons.chat_bubble_outline, size: 36, color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 12),
                Text("Pose une question ou envoie une vidéo", style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14)),
              ]))
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: messages.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: kOrange.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.psychology, size: 13, color: kOrange)),
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
                          Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: kOrange.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.psychology, size: 13, color: kOrange)),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isUser ? kOrange : kCard,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(14), topRight: const Radius.circular(14),
                                bottomLeft: Radius.circular(isUser ? 14 : 4),
                                bottomRight: Radius.circular(isUser ? 4 : 14),
                              ),
                              border: isUser ? null : Border.all(color: kBorder),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (msg['video_filename'] != null && (msg['video_filename'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Row(children: [
                                    const Icon(Icons.videocam, size: 12, color: Colors.white70),
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
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(color: kSidebar, border: Border(top: BorderSide(color: kBorder))),
        child: Column(children: [
          if (pendingVideoName != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: kOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: kOrange.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.videocam, size: 14, color: kOrange),
                const SizedBox(width: 8),
                Expanded(child: Text(pendingVideoName!, style: const TextStyle(fontSize: 12, color: Colors.white70))),
                Clickable(onTap: () => setState(() { pendingVideoBytes = null; pendingVideoName = null; }), child: Icon(Icons.close, size: 14, color: Colors.white.withOpacity(0.3))),
              ]),
            ),
          Row(children: [
            MouseRegion(cursor: SystemMouseCursors.click, child: IconButton(onPressed: pickVideo, icon: const Icon(Icons.videocam_outlined, color: kOrange, size: 20), tooltip: "Envoyer une vidéo")),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 5, minLines: 1,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: "Pose une question à ton coach...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
                  filled: true, fillColor: kBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kOrange, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (_) => sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Clickable(
              onTap: () => sendMessage(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: isLoading ? kOrange.withOpacity(0.3) : kOrange, borderRadius: BorderRadius.circular(10)),
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
  const ProfilePage({super.key, required this.userData});
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
    selectedLevel = widget.userData['level'] ?? 'debutant';
  }

  Future<void> saveProfile() async {
    // Sauvegarder localement
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _nameController.text);
    await prefs.setString('age', _ageController.text);
    await prefs.setString('weight', _weightController.text);
    await prefs.setString('height', _heightController.text);
    await prefs.setString('goal', _goalController.text);
    await prefs.setString('level', selectedLevel);

    // Sauvegarder dans la base de données backend
    final data = {
      'name': _nameController.text,
      'age': _ageController.text,
      'weight': _weightController.text,
      'height': _heightController.text,
      'goal': _goalController.text,
      'level': selectedLevel,
    };
    var request = http.MultipartRequest('PUT', Uri.parse('$kBaseUrl/user-data/'));
    request.fields['data'] = jsonEncode(data);
    await request.send();

    setState(() => saved = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.pop(context);
    });
  }

  Widget _field(String label, TextEditingController controller, {String? hint, TextInputType? type}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
          filled: true, fillColor: kCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kOrange, width: 1.5)),
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
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.person, color: kOrange, size: 20)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Mon profil", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("Le coach adapte ses conseils à ton profil", style: TextStyle(fontSize: 12, color: Colors.white38)),
          ])),
          Clickable(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.white38, size: 20)),
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
        const Text("NIVEAU", style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
        const SizedBox(height: 8),
        Row(children: levels.map((l) {
          final isSelected = selectedLevel == l['key'];
          return Expanded(child: Clickable(
            onTap: () => setState(() => selectedLevel = l['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: isSelected ? kOrange : kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected ? kOrange : kBorder)),
              child: Text(l['label']!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : Colors.white54, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
            ),
          ));
        }).toList()),
        const SizedBox(height: 16),
        _field("OBJECTIF PRINCIPAL", _goalController, hint: "Ex: Prendre de la masse, perdre du poids..."),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: saved ? Colors.green : kOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(saved ? "✓ Sauvegardé !" : "Sauvegarder", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}