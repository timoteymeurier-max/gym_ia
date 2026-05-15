import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

// ===================== THEME =====================
const kOrange = Color(0xFFFF6B2B);
const kOrangeLight = Color(0xFFFF8C5A);
const kBg = Color(0xFF080808);
const kCard = Color(0xFF111111);
const kCard2 = Color(0xFF1A1A1A);
const kCard3 = Color(0xFF222222);
const kBorder = Color(0xFF2A2A2A);
const kBorderLight = Color(0xFF333333);
const kText = Colors.white;
const kTextDim = Color(0xFF777777);
const kTextMid = Color(0xFFAAAAAA);
const kGreen = Color(0xFF4ADE80);
const kBlue = Color(0xFF60A5FA);
const kPurple = Color(0xFFA78BFA);
const kYellow = Color(0xFFFBBF24);
const kRed = Color(0xFFF87171);
const String kBaseUrl = 'https://gym-ia-n9tf.onrender.com';

// ===================== MOCK DATA =====================
final mockExercises = [
  {'name': 'Squat', 'muscle': 'Quadriceps', 'type': 'Poids libre', 'difficulty': 'Intermédiaire', 'icon': '🦵', 'color': kOrange},
  {'name': 'Développé couché', 'muscle': 'Pectoraux', 'type': 'Poids libre', 'difficulty': 'Intermédiaire', 'icon': '💪', 'color': kBlue},
  {'name': 'Soulevé de terre', 'muscle': 'Ischio-jambiers', 'type': 'Poids libre', 'difficulty': 'Avancé', 'icon': '⚡', 'color': kPurple},
  {'name': 'Tractions', 'muscle': 'Dos', 'type': 'Poids du corps', 'difficulty': 'Intermédiaire', 'icon': '🔝', 'color': kGreen},
  {'name': 'Développé militaire', 'muscle': 'Épaules', 'type': 'Poids libre', 'difficulty': 'Intermédiaire', 'icon': '🏋️', 'color': kYellow},
  {'name': 'Curl biceps', 'muscle': 'Biceps', 'type': 'Poids libre', 'difficulty': 'Débutant', 'icon': '💪', 'color': kOrangeLight},
  {'name': 'Triceps poulie', 'muscle': 'Triceps', 'type': 'Machine', 'difficulty': 'Débutant', 'icon': '🔄', 'color': kRed},
  {'name': 'Leg press', 'muscle': 'Quadriceps', 'type': 'Machine', 'difficulty': 'Débutant', 'icon': '🦿', 'color': kBlue},
  {'name': 'Rowing barre', 'muscle': 'Dos', 'type': 'Poids libre', 'difficulty': 'Intermédiaire', 'icon': '🚣', 'color': kGreen},
  {'name': 'Hip thrust', 'muscle': 'Fessiers', 'type': 'Poids libre', 'difficulty': 'Débutant', 'icon': '🍑', 'color': kPurple},
  {'name': 'Fentes', 'muscle': 'Quadriceps', 'type': 'Poids libre', 'difficulty': 'Débutant', 'icon': '🚶', 'color': kOrange},
  {'name': 'Tirage vertical', 'muscle': 'Dos', 'type': 'Machine', 'difficulty': 'Débutant', 'icon': '⬇️', 'color': kYellow},
];

final mockPrograms = [
  {'name': 'Push Pull Legs', 'difficulty': 'Intermédiaire', 'duration': '6 semaines', 'goal': 'Masse musculaire', 'sessions': '6x/semaine', 'color': kOrange},
  {'name': 'Full Body', 'difficulty': 'Débutant', 'duration': '8 semaines', 'goal': 'Force générale', 'sessions': '3x/semaine', 'color': kBlue},
  {'name': 'Force 5x5', 'difficulty': 'Avancé', 'duration': '12 semaines', 'goal': 'Force maximale', 'sessions': '3x/semaine', 'color': kPurple},
  {'name': 'Hypertrophie', 'difficulty': 'Intermédiaire', 'duration': '8 semaines', 'goal': 'Prise de masse', 'sessions': '5x/semaine', 'color': kGreen},
  {'name': 'Sèche', 'difficulty': 'Intermédiaire', 'duration': '10 semaines', 'goal': 'Perte de gras', 'sessions': '5x/semaine', 'color': kYellow},
];

final mockRecipes = [
  {'name': 'Omelette protéinée', 'meal': 'Petit déjeuner', 'calories': 420, 'protein': 38, 'time': '10 min', 'icon': '🍳', 'color': kYellow},
  {'name': 'Riz poulet légumes', 'meal': 'Déjeuner', 'calories': 650, 'protein': 55, 'time': '25 min', 'icon': '🍗', 'color': kGreen},
  {'name': 'Shake protéiné', 'meal': 'Snack', 'calories': 280, 'protein': 30, 'time': '2 min', 'icon': '🥤', 'color': kBlue},
  {'name': 'Saumon patate douce', 'meal': 'Dîner', 'calories': 580, 'protein': 48, 'time': '30 min', 'icon': '🐟', 'color': kOrange},
  {'name': 'Porridge avoine', 'meal': 'Petit déjeuner', 'calories': 350, 'protein': 15, 'time': '5 min', 'icon': '🥣', 'color': kPurple},
  {'name': 'Salade thon quinoa', 'meal': 'Déjeuner', 'calories': 490, 'protein': 42, 'time': '15 min', 'icon': '🥗', 'color': kGreen},
];

// ===================== UTILS =====================
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
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(onTap: onTap, child: child),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: kBg, useMaterial3: true),
    home: const RootPage(),
  );
}

// ===================== ROOT PAGE =====================
class RootPage extends StatefulWidget {
  const RootPage({super.key});
  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _currentIndex = 0;
  Map<String, String> userData = {};
  String deviceId = '';
  String dailyMessage = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final id = await getDeviceId();
    if (!mounted) return;
    setState(() => deviceId = id);
    await loadUserData();
    await _loadDailyMessage();
  }

  Future<void> loadUserData() async {
    if (deviceId.isEmpty) return;
    try {
      final response = await http.get(Uri.parse('$kBaseUrl/user-data/'), headers: {'x-device-id': deviceId}).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() => userData = data.map((k, v) => MapEntry(k, v.toString())));
      }
    } catch (e) {
      if (mounted) setState(() => userData = {});
    }
  }

  Future<void> _loadDailyMessage() async {
    if (deviceId.isEmpty) return;
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(Uri.parse('$kBaseUrl/daily-message/?t=$ts'), headers: {'x-device-id': deviceId}).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final msg = data['message']?.toString() ?? '';
        if (msg.isNotEmpty) setState(() => dailyMessage = msg);
      }
    } catch (e) {}
  }

  Future<void> refreshUserData() async {
    await loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    if (deviceId.isEmpty) {
      return const Scaffold(backgroundColor: kBg, body: Center(child: CircularProgressIndicator(color: kOrange)));
    }
    final pages = [
      HomePageV2(userData: userData, onUserDataChanged: refreshUserData, deviceId: deviceId, dailyMessage: dailyMessage),
      CoachPageV2(deviceId: deviceId, onMessageSent: refreshUserData),
      TrainingPageV2(userData: userData, deviceId: deviceId),
      NutritionPageV2(userData: userData, deviceId: deviceId),
      ProgressPageV2(userData: userData),
    ];
    return Scaffold(
      backgroundColor: kBg,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Accueil'},
      {'icon': Icons.psychology_rounded, 'label': 'Coach IA'},
      {'icon': Icons.fitness_center_rounded, 'label': 'Training'},
      {'icon': Icons.restaurant_rounded, 'label': 'Nutrition'},
      {'icon': Icons.bar_chart_rounded, 'label': 'Progrès'},
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 24, offset: const Offset(0, 8))],
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
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? kOrange.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
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

// ===================== HOME PAGE V2 =====================
// ignore_for_file: unused_field
class HomePageV2 extends StatefulWidget {
  final Map<String, String> userData;
  final VoidCallback onUserDataChanged;
  final String deviceId;
  final String dailyMessage;
  const HomePageV2({super.key, required this.userData, required this.onUserDataChanged, required this.deviceId, required this.dailyMessage});
  @override
  State<HomePageV2> createState() => _HomePageV2State();
}

class _HomePageV2State extends State<HomePageV2> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _chatController = TextEditingController();
  double _scrollOffset = 0;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _scrollController.addListener(() => setState(() => _scrollOffset = _scrollController.offset));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String _levelShort(String level) {
    if (level == 'debutant') return 'Débutant';
    if (level == 'intermediaire') return 'Intermédiaire';
    if (level == 'avance') return 'Avancé';
    return level;
  }

  String _getTimeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Prêt pour la séance du matin ?';
    if (h < 17) return 'Belle journée pour s\'entraîner';
    return 'Séance du soir, on y va !';
  }

  void _openProfile() async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: kBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(width: 500, height: 600, child: ProfilePageV2(userData: widget.userData, deviceId: widget.deviceId)),
      ),
    );
    widget.onUserDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final name = widget.userData['name'] ?? '';
    final weight = widget.userData['weight'] ?? '--';
    final squat = widget.userData['squat_weight'] ?? '--';
    final streak = widget.userData['streak'] ?? '--';
    final lastScore = widget.userData['last_squat_score'] ?? '--';
    final lastReps = widget.userData['last_squat_reps'] ?? '--';
    final lastDate = widget.userData['last_squat_date'] ?? '';
    final level = widget.userData['level'] ?? '';
    final height = widget.userData['height'] ?? '';
    final age = widget.userData['age'] ?? '';

    // Transitions basées sur le scroll
    final heroProgress = (_scrollOffset / (screenHeight * 0.45)).clamp(0.0, 1.0);
    final heroOpacity = (1.0 - heroProgress * 1.4).clamp(0.0, 1.0);
    final statsOpacity = ((heroProgress - 0.35) / 0.65).clamp(0.0, 1.0);

    List<Map<String, dynamic>> weightHistory = [];
    try {
      final raw = widget.userData['weight_history'] ?? '[]';
      weightHistory = (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {}

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          // ── LAYER 1 : Scroll content (stats) ──────────────────
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Espace plein écran pour le hero
              SliverToBoxAdapter(child: SizedBox(height: screenHeight - 80)),
              // Stats qui apparaissent après le scroll
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Opacity(
                      opacity: statsOpacity,
                      child: Column(children: [
                        _buildProfileCard(name, weight, height, age, level),
                        const SizedBox(height: 14),
                        _buildPerfsRow(squat, streak, lastScore),
                        const SizedBox(height: 14),
                        _buildWeekCard(),
                        const SizedBox(height: 14),
                        if (weightHistory.length >= 2) ...[_buildWeightChart(weightHistory), const SizedBox(height: 14)],
                        if (lastScore != '--') ...[_buildLastAnalysis(lastScore, lastReps, lastDate), const SizedBox(height: 14)],
                        _buildQuickActions(),
                      ]),
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // ── LAYER 2 : Hero plein écran ChatGPT-style ──────────
          Positioned.fill(
            child: IgnorePointer(
              ignoring: heroOpacity < 0.05,
              child: Opacity(
                opacity: heroOpacity,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 0, 26, 100),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row : greeting + profil
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              name.isNotEmpty ? 'Bonjour, $name 👋' : 'Bonjour 👋',
                              style: const TextStyle(fontSize: 14, color: kTextDim, fontWeight: FontWeight.w500),
                            ),
                            Text(_getTimeGreeting(), style: const TextStyle(fontSize: 11, color: Color(0xFF444444))),
                          ]),
                          Clickable(
                            onTap: _openProfile,
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: kCard2, shape: BoxShape.circle,
                                border: Border.all(color: name.isNotEmpty ? kOrange.withOpacity(0.5) : kBorder),
                              ),
                              child: name.isNotEmpty
                                  ? Center(child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kOrange)))
                                  : const Icon(Icons.person_rounded, color: kTextDim, size: 18),
                            ),
                          ),
                        ]),

                        const Spacer(),

                        // ── Phrase IA — grande, style ChatGPT ──
                        widget.dailyMessage.isEmpty
                            ? const SizedBox(height: 44, child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: kOrange, strokeWidth: 1.5))))
                            : Text(
                                widget.dailyMessage,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: kText,
                                  height: 1.3,
                                  letterSpacing: -0.8,
                                ),
                              ),

                        const SizedBox(height: 28),

                        // ── Barre d'écriture style ChatGPT ──
                        Container(
                          decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: kBorderLight),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          child: Row(children: [
                            Expanded(
                              child: TextField(
                                controller: _chatController,
                                style: const TextStyle(color: kText, fontSize: 15),
                                maxLines: 1,
                                decoration: InputDecoration(
                                  hintText: 'Pose une question à ton coach...',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.17), fontSize: 15),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                ),
                                onSubmitted: (_) => _chatController.clear(),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Clickable(
                                onTap: () => _chatController.clear(),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 17),
                                ),
                              ),
                            ),
                          ]),
                        ),

                        const SizedBox(height: 14),

                        // ── Pills de suggestions ──
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          _pill('Analyser mon squat', Icons.videocam_rounded),
                          _pill('Programme IA', Icons.auto_awesome_rounded),
                          _pill('Augmenter la charge ?', Icons.trending_up_rounded),
                          _pill('Recette protéinée', Icons.restaurant_rounded),
                        ]),

                        const Spacer(),

                        // ── Indicateur scroll ──
                        Center(child: Column(children: [
                          Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withOpacity(0.1), size: 22),
                          Text('Voir mes stats', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.1))),
                        ])),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── LAYER 3 : Compact header après scroll ─────────────
          AnimatedOpacity(
            opacity: (1.0 - heroOpacity * 2).clamp(0.0, 1.0),
            duration: const Duration(milliseconds: 150),
            child: IgnorePointer(
              ignoring: heroOpacity > 0.3,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                decoration: BoxDecoration(
                  color: kBg.withOpacity(0.96),
                  border: Border(bottom: BorderSide(color: kBorder.withOpacity(0.4))),
                ),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      widget.dailyMessage,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Clickable(
                    onTap: _openProfile,
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(color: kCard2, shape: BoxShape.circle, border: Border.all(color: kBorder)),
                      child: name.isNotEmpty
                          ? Center(child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kOrange)))
                          : const Icon(Icons.person_rounded, color: kTextDim, size: 15),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: kOrange),
      const SizedBox(width: 6),
      Text(text, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55))),
    ]),
  );

  Widget _buildProfileCard(String name, String weight, String height, String age, String level) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('MON PROFIL', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const Spacer(),
          if (level.isNotEmpty) Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: kOrange.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: kOrange.withOpacity(0.3))),
            child: Text(_levelShort(level), style: const TextStyle(fontSize: 11, color: kOrange, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _miniStat('Poids', weight.isNotEmpty ? '$weight kg' : '--', Icons.monitor_weight_outlined, kBlue),
          _divider(),
          _miniStat('Taille', height.isNotEmpty ? '${height}cm' : '--', Icons.height_rounded, kGreen),
          _divider(),
          _miniStat('Âge', age.isNotEmpty ? '$age ans' : '--', Icons.cake_rounded, kPurple),
        ]),
      ]),
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: kBorder, margin: const EdgeInsets.symmetric(horizontal: 4));

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Expanded(child: Column(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 5),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kText), overflow: TextOverflow.ellipsis),
      Text(label, style: const TextStyle(fontSize: 10, color: kTextDim)),
    ]));
  }

  Widget _buildPerfsRow(String squat, String streak, String score) {
    return Row(children: [
      Expanded(child: _perfCard('Squat', squat != '--' ? '$squat kg' : '--', Icons.fitness_center_rounded, kOrange)),
      const SizedBox(width: 10),
      Expanded(child: _perfCard('Streak', streak != '--' ? '$streak j 🔥' : '--', Icons.local_fire_department_rounded, kYellow)),
      const SizedBox(width: 10),
      Expanded(child: _perfCard('Score', score != '--' ? '$score/100' : '--', Icons.analytics_rounded, kGreen)),
    ]);
  }

  Widget _perfCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kText), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: kTextDim)),
      ]),
    );
  }

  Widget _buildWeekCard() {
    final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final done = [true, true, false, true, false, false, false];
    final today = DateTime.now().weekday - 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('CETTE SEMAINE', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const Spacer(),
          Text('${done.where((d) => d).length}/7', style: const TextStyle(fontSize: 12, color: kOrange, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
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
                width: 32, height: 32,
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

  Widget _buildWeightChart(List<Map<String, dynamic>> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ÉVOLUTION DU POIDS', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        SizedBox(height: 80, child: CustomPaint(painter: _WeightChartPainter(data), size: Size.infinite)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(data.first['date'] ?? '', style: const TextStyle(fontSize: 10, color: kTextDim)),
          Text(data.last['date'] ?? '', style: const TextStyle(fontSize: 10, color: kTextDim)),
        ]),
      ]),
    );
  }

  Widget _buildLastAnalysis(String score, String reps, String date) {
    final scoreInt = int.tryParse(score) ?? 0;
    final color = scoreInt >= 80 ? kGreen : scoreInt >= 60 ? kOrange : kRed;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(score, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Dernière analyse squat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kText)),
          const SizedBox(height: 2),
          Text('$reps reps · $date', style: const TextStyle(fontSize: 12, color: kTextDim)),
        ])),
        const Text('/100', style: TextStyle(fontSize: 11, color: kTextDim)),
      ]),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'label': 'Analyser squat', 'icon': Icons.videocam_rounded, 'color': kOrange},
      {'label': 'Programme IA', 'icon': Icons.auto_awesome_rounded, 'color': kPurple},
      {'label': 'Bilan semaine', 'icon': Icons.bar_chart_rounded, 'color': kBlue},
      {'label': 'Recette rapide', 'icon': Icons.restaurant_rounded, 'color': kGreen},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ACTIONS RAPIDES', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.5,
        children: actions.map((a) => Clickable(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: (a['color'] as Color).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: (a['color'] as Color).withOpacity(0.2)),
            ),
            child: Row(children: [
              Icon(a['icon'] as IconData, color: a['color'] as Color, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(a['label'] as String, style: const TextStyle(fontSize: 12, color: kText, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
            ]),
          ),
        )).toList(),
      ),
    ]);
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _WeightChartPainter(this.data);
  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final weights = data.map((e) => (e['weight'] as num).toDouble()).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b) - 1;
    final maxW = weights.reduce((a, b) => a > b ? a : b) + 1;
    final range = maxW - minW == 0 ? 1.0 : maxW - minW;
    final paint = Paint()..color = kOrange..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [kOrange.withOpacity(0.2), kOrange.withOpacity(0.0)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    final path = Path(), fillPath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((weights[i] - minW) / range * size.height);
      if (i == 0) { path.moveTo(x, y); fillPath.moveTo(x, size.height); fillPath.lineTo(x, y); }
      else {
        final px = (i - 1) / (data.length - 1) * size.width;
        final py = size.height - ((weights[i - 1] - minW) / range * size.height);
        final cpX = (px + x) / 2;
        path.cubicTo(cpX, py, cpX, y, x, y);
        fillPath.cubicTo(cpX, py, cpX, y, x, y);
      }
    }
    fillPath.lineTo(size.width, size.height); fillPath.close();
    canvas.drawPath(fillPath, fillPaint); canvas.drawPath(path, paint);
    final dotPaint = Paint()..color = kOrange..style = PaintingStyle.fill;
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((weights[i] - minW) / range * size.height);
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter _) => true;
}

// ===================== COACH PAGE V2 =====================
class CoachPageV2 extends StatefulWidget {
  final String deviceId;
  final VoidCallback onMessageSent;
  const CoachPageV2({super.key, required this.deviceId, required this.onMessageSent});
  @override
  State<CoachPageV2> createState() => _CoachPageV2State();
}

class _CoachPageV2State extends State<CoachPageV2> {
  List<Map<String, dynamic>> conversations = [];
  int? activeConvId;
  bool sidebarOpen = true;
  String? _pendingSuggestion;

  Map<String, String> get _headers => {'x-device-id': widget.deviceId};

  @override
  void initState() { super.initState(); loadConversations(); }

  Future<void> loadConversations() async {
    try {
      final r = await http.get(Uri.parse('$kBaseUrl/conversations/'), headers: _headers);
      final data = jsonDecode(r.body) as List;
      setState(() => conversations = data.map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (_) {}
  }

  Future<void> createNewConversation({String? suggestion}) async {
    try {
      var req = http.MultipartRequest('POST', Uri.parse('$kBaseUrl/conversations/'));
      req.headers.addAll(_headers);
      req.fields['objectif'] = 'general';
      req.fields['title'] = suggestion ?? 'Nouvelle conversation';
      var res = await req.send();
      var body = await res.stream.bytesToString();
      final data = jsonDecode(body);
      setState(() { conversations.insert(0, Map<String, dynamic>.from(data)); activeConvId = data['id']; _pendingSuggestion = suggestion; });
    } catch (_) {}
  }

  Future<void> deleteConversation(int id) async {
    try {
      await http.delete(Uri.parse('$kBaseUrl/conversations/$id'), headers: _headers);
      setState(() { conversations.removeWhere((c) => c['id'] == id); if (activeConvId == id) activeConvId = null; });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(bottom: false, child: Row(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: sidebarOpen ? 240 : 0,
        child: sidebarOpen ? _buildSidebar() : const SizedBox(),
      ),
      Expanded(child: Column(children: [
        _buildHeader(),
        Expanded(child: activeConvId == null ? _buildWelcome() : ChatViewV2(
          key: ValueKey(activeConvId),
          convId: activeConvId!,
          deviceId: widget.deviceId,
          initialMessage: _pendingSuggestion,
          onTitleUpdate: (title) => setState(() { _pendingSuggestion = null; final idx = conversations.indexWhere((c) => c['id'] == activeConvId); if (idx != -1) conversations[idx]['title'] = title; }),
          onMessageSent: widget.onMessageSent,
        )),
      ])),
    ]));
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: const Color(0xFF0D0D0D), border: Border(bottom: BorderSide(color: kBorder))),
    child: Row(children: [
      MouseRegion(cursor: SystemMouseCursors.click, child: IconButton(onPressed: () => setState(() => sidebarOpen = !sidebarOpen), icon: Icon(Icons.menu_rounded, color: Colors.white.withOpacity(0.4), size: 20))),
      const SizedBox(width: 6),
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: kOrange.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.psychology_rounded, size: 14, color: kOrange)),
      const SizedBox(width: 8),
      const Text('Coach IA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kText)),
      const Spacer(),
      MouseRegion(cursor: SystemMouseCursors.click, child: IconButton(onPressed: () => createNewConversation(), icon: const Icon(Icons.edit_outlined, color: kOrange, size: 18))),
    ]),
  );

  Widget _buildSidebar() => Container(
    decoration: BoxDecoration(color: const Color(0xFF0D0D0D), border: Border(right: BorderSide(color: kBorder))),
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () => createNewConversation(),
          icon: const Icon(Icons.add_rounded, size: 15),
          label: const Text('Nouveau chat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
        )),
      ),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Align(alignment: Alignment.centerLeft, child: Text('RÉCENT', style: TextStyle(fontSize: 10, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)))),
      Expanded(child: conversations.isEmpty
        ? Center(child: Text('Aucune conversation', style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 12)))
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: conversations.length,
            itemBuilder: (context, i) {
              final conv = conversations[i];
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
          )),
    ]),
  );

  Widget _buildWelcome() {
    final suggestions = [
      {'icon': Icons.videocam_rounded, 'text': 'Analyse mon squat', 'color': kOrange},
      {'icon': Icons.fitness_center_rounded, 'text': 'Programme pour prendre de la masse', 'color': kBlue},
      {'icon': Icons.compare_arrows_rounded, 'text': 'Comment améliorer mon deadlift ?', 'color': kPurple},
      {'icon': Icons.monitor_heart_outlined, 'text': 'Puis-je augmenter ma charge ?', 'color': kGreen},
      {'icon': Icons.restaurant_rounded, 'text': 'Que manger avant une séance ?', 'color': kYellow},
      {'icon': Icons.schedule_rounded, 'text': 'Combien de séances par semaine ?', 'color': kOrangeLight},
    ];
    return Column(children: [
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [kOrange.withOpacity(0.15), Colors.transparent], radius: 1),
              shape: BoxShape.circle,
              border: Border.all(color: kOrange.withOpacity(0.2)),
            ),
            child: const Icon(Icons.psychology_rounded, size: 44, color: kOrange),
          ),
          const SizedBox(height: 20),
          const Text('Coach IA', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kText)),
          const SizedBox(height: 6),
          Text('Ton coach sportif IA personnel', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.3))),
          const SizedBox(height: 32),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: suggestions.map((s) => Clickable(
            onTap: () => createNewConversation(suggestion: s['text'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: (s['color'] as Color).withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: (s['color'] as Color).withOpacity(0.2))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(s['icon'] as IconData, size: 14, color: s['color'] as Color),
                const SizedBox(width: 8),
                Text(s['text'] as String, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
              ]),
            ),
          )).toList()),
        ]),
      )),
      _buildInputBar(),
    ]);
  }

  Widget _buildInputBar() => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
    decoration: BoxDecoration(color: const Color(0xFF0D0D0D), border: Border(top: BorderSide(color: kBorder))),
    child: Row(children: [
      Expanded(child: TextField(
        style: const TextStyle(color: kText, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Pose une question à ton coach...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
          filled: true, fillColor: kCard2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kOrange, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onSubmitted: (val) { if (val.trim().isNotEmpty) createNewConversation(suggestion: val.trim()); },
      )),
      const SizedBox(width: 8),
      Clickable(onTap: () => createNewConversation(), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.send_rounded, color: Colors.white, size: 17))),
    ]),
  );
}

// ===================== CHAT VIEW V2 =====================
class ChatViewV2 extends StatefulWidget {
  final int convId;
  final Function(String) onTitleUpdate;
  final VoidCallback onMessageSent;
  final String? initialMessage;
  final String deviceId;
  const ChatViewV2({super.key, required this.convId, required this.onTitleUpdate, required this.onMessageSent, this.initialMessage, required this.deviceId});
  @override
  State<ChatViewV2> createState() => _ChatViewV2State();
}

class _ChatViewV2State extends State<ChatViewV2> {
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
      final r = await http.get(Uri.parse('$kBaseUrl/conversations/${widget.convId}/messages'), headers: _headers);
      final data = jsonDecode(r.body) as List;
      setState(() => messages = data.map((e) => Map<String, dynamic>.from(e)).toList());
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> pickVideo() async {
    FilePickerResult? picked = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
    if (picked != null) setState(() { pendingVideoBytes = picked.files.single.bytes; pendingVideoName = picked.files.single.name; });
  }

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && pendingVideoBytes == null) return;
    final displayText = text.isNotEmpty ? text : 'Analyse cette vidéo';
    setState(() { messages.add({'role': 'user', 'content': displayText, 'video_filename': pendingVideoName}); isLoading = true; });
    _controller.clear();
    final vb = pendingVideoBytes; final vn = pendingVideoName;
    pendingVideoBytes = null; pendingVideoName = null;
    _scrollToBottom();
    try {
      var req = http.MultipartRequest('POST', Uri.parse('$kBaseUrl/conversations/${widget.convId}/chat'));
      req.headers.addAll(_headers);
      req.fields['message'] = text.isNotEmpty ? text : 'Analyse cette vidéo et donne-moi des conseils détaillés';
      final prefs = await SharedPreferences.getInstance();
      req.fields['user_profile'] = jsonEncode({'name': prefs.getString('name') ?? '', 'age': prefs.getString('age') ?? '', 'weight': prefs.getString('weight') ?? '', 'height': prefs.getString('height') ?? '', 'level': prefs.getString('level') ?? '', 'goal': prefs.getString('goal') ?? ''});
      if (vb != null && vn != null) req.files.add(http.MultipartFile.fromBytes('file', vb, filename: vn));
      var res = await req.send();
      var body = await res.stream.bytesToString();
      final j = jsonDecode(body);
      setState(() { messages.add({'role': 'assistant', 'content': j['response'] ?? '', 'video_filename': null}); isLoading = false; });
      if (messages.length == 2) widget.onTitleUpdate(displayText.length > 40 ? '${displayText.substring(0, 40)}...' : displayText);
      widget.onMessageSent();
      _scrollToBottom();
    } catch (_) {
      setState(() { messages.add({'role': 'assistant', 'content': 'Erreur de connexion.', 'video_filename': null}); isLoading = false; });
    }
  }

  void _scrollToBottom() => Future.delayed(const Duration(milliseconds: 100), () { if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: messages.isEmpty && !isLoading
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 36, color: Colors.white.withOpacity(0.06)),
            const SizedBox(height: 12),
            Text('Pose une question ou envoie une vidéo', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14)),
          ]))
        : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: messages.length + (isLoading ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == messages.length) return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: kOrange.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.psychology_rounded, size: 13, color: kOrange)),
                  const SizedBox(width: 8),
                  Text('Coach en train de réfléchir...', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
                  const SizedBox(width: 8),
                  const SizedBox(height: 13, width: 13, child: CircularProgressIndicator(strokeWidth: 1.5, color: kOrange)),
                ]),
              );
              final msg = messages[i];
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
                    Flexible(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUser ? kOrange : kCard,
                        borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isUser ? 16 : 4), bottomRight: Radius.circular(isUser ? 4 : 16)),
                        border: isUser ? null : Border.all(color: kBorder),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (msg['video_filename'] != null && (msg['video_filename'] as String).isNotEmpty)
                          Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(children: [
                            const Icon(Icons.videocam_rounded, size: 12, color: Colors.white70),
                            const SizedBox(width: 4),
                            Flexible(child: Text(msg['video_filename'] as String, style: const TextStyle(fontSize: 11, color: Colors.white70))),
                          ])),
                        isUser
                          ? SelectableText(msg['content'] as String, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5))
                          : SelectionArea(child: MarkdownBody(data: msg['content'] as String, styleSheet: MarkdownStyleSheet(
                              p: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85), height: 1.5),
                              strong: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                              tableHead: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              tableBody: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                              tableBorder: TableBorder.all(color: Colors.white12),
                            ))),
                      ]),
                    )),
                    if (isUser) const SizedBox(width: 8),
                  ],
                ),
              );
            },
          )),
      Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
        decoration: BoxDecoration(color: const Color(0xFF0D0D0D), border: Border(top: BorderSide(color: kBorder))),
        child: Column(children: [
          if (pendingVideoName != null) Container(
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
            Expanded(child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 5, minLines: 1,
              decoration: InputDecoration(
                hintText: 'Pose une question...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
                filled: true, fillColor: kCard2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kOrange, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => sendMessage(),
            )),
            const SizedBox(width: 8),
            Clickable(onTap: sendMessage, child: Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: isLoading ? kOrange.withOpacity(0.3) : kOrange, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.send_rounded, color: Colors.white, size: 17))),
          ]),
        ]),
      ),
    ]);
  }
}

// ===================== TRAINING PAGE V2 =====================
class TrainingPageV2 extends StatelessWidget {
  final Map<String, String> userData;
  final String deviceId;
  const TrainingPageV2({super.key, required this.userData, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(bottom: false, child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Training', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kText)),
        const SizedBox(height: 4),
        Text('Ton hub d\'entraînement', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.35))),
        const SizedBox(height: 28),
        // 3 grands widgets hub
        _hubCard(
          context,
          icon: Icons.grid_view_rounded,
          color: kOrange,
          title: 'Programmes prédéfinis',
          description: 'PPL, Full Body, Force, Hypertrophie...',
          tag: '5 programmes',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgramsPage())),
        ),
        const SizedBox(height: 14),
        _hubCard(
          context,
          icon: Icons.menu_book_rounded,
          color: kBlue,
          title: 'Bibliothèque d\'exercices',
          description: 'Tous les exercices de la salle avec fiches complètes',
          tag: '${mockExercises.length} exercices',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseLibraryPage())),
        ),
        const SizedBox(height: 14),
        _hubCard(
          context,
          icon: Icons.auto_awesome_rounded,
          color: kPurple,
          title: 'Programmes IA',
          description: 'Programmes générés par ton coach IA',
          tag: 'Personnalisé',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AIProgramsPage(deviceId: deviceId))),
        ),
      ]),
    ));
  }

  Widget _hubCard(BuildContext context, {required IconData icon, required Color color, required String title, required String description, required String tag, required VoidCallback onTap}) {
    return Clickable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.2)),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(0.06), Colors.transparent]),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kText)),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(fontSize: 12, color: kTextDim, height: 1.4)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(tag, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.5), size: 16),
        ]),
      ),
    );
  }
}

// ===================== PROGRAMS PAGE =====================
class ProgramsPage extends StatelessWidget {
  const ProgramsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, title: const Text('Programmes prédéfinis', style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.bold)), iconTheme: const IconThemeData(color: kText), elevation: 0),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: mockPrograms.length,
        itemBuilder: (context, i) {
          final p = mockPrograms[i];
          return Clickable(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProgramDetailPage(program: p))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: (p['color'] as Color).withOpacity(0.2))),
              child: Row(children: [
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(color: (p['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Icon(Icons.fitness_center_rounded, color: p['color'] as Color, size: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kText)),
                  const SizedBox(height: 4),
                  Text('${p['goal']} · ${p['duration']}', style: const TextStyle(fontSize: 12, color: kTextDim)),
                  const SizedBox(height: 6),
                  Row(children: [
                    _tag(p['difficulty'] as String, p['color'] as Color),
                    const SizedBox(width: 6),
                    _tag(p['sessions'] as String, kCard3),
                  ]),
                ])),
                Icon(Icons.arrow_forward_ios_rounded, color: (p['color'] as Color).withOpacity(0.5), size: 14),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(fontSize: 10, color: color == kCard3 ? kTextMid : color, fontWeight: FontWeight.w600)),
  );
}

// ===================== PROGRAM DETAIL PAGE =====================
class ProgramDetailPage extends StatelessWidget {
  final Map<String, dynamic> program;
  const ProgramDetailPage({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    final color = program['color'] as Color;
    final sessions = [
      {'name': 'Séance A — Push', 'exercises': ['Développé couché', 'Développé militaire', 'Triceps poulie']},
      {'name': 'Séance B — Pull', 'exercises': ['Tractions', 'Rowing barre', 'Curl biceps']},
      {'name': 'Séance C — Legs', 'exercises': ['Squat', 'Leg press', 'Hip thrust']},
    ];
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, title: Text(program['name'] as String, style: const TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.bold)), iconTheme: const IconThemeData(color: kText), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(0.2))),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${program['goal']} · ${program['duration']} · ${program['sessions']}', style: const TextStyle(fontSize: 13, color: kTextMid)),
                Text('Difficulté : ${program['difficulty']}', style: TextStyle(fontSize: 12, color: color)),
              ])),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('SÉANCES', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          ...sessions.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kText)),
              const SizedBox(height: 10),
              ...(s['exercises'] as List<String>).map((e) => Clickable(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseDetailPage(exercise: mockExercises.firstWhere((ex) => ex['name'] == e, orElse: () => {'name': e, 'muscle': '--', 'type': '--', 'difficulty': '--', 'icon': '💪', 'color': kOrange})))),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: kCard2, borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.fitness_center_rounded, size: 14, color: kOrange),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e, style: const TextStyle(fontSize: 13, color: kText))),
                    const Text('4×8', style: TextStyle(fontSize: 11, color: kTextDim)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: kTextDim),
                  ]),
                ),
              )).toList(),
            ]),
          )).toList(),
        ]),
      ),
    );
  }
}

// ===================== EXERCISE LIBRARY PAGE =====================
class ExerciseLibraryPage extends StatefulWidget {
  const ExerciseLibraryPage({super.key});
  @override
  State<ExerciseLibraryPage> createState() => _ExerciseLibraryPageState();
}

class _ExerciseLibraryPageState extends State<ExerciseLibraryPage> {
  String _search = '';
  String _filterMuscle = 'Tous';
  String _filterType = 'Tous';

  List<Map<String, dynamic>> get filtered {
    return mockExercises.where((e) {
      final matchSearch = _search.isEmpty || (e['name'] as String).toLowerCase().contains(_search.toLowerCase());
      final matchMuscle = _filterMuscle == 'Tous' || e['muscle'] == _filterMuscle;
      final matchType = _filterType == 'Tous' || e['type'] == _filterType;
      return matchSearch && matchMuscle && matchType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final muscles = ['Tous', ...mockExercises.map((e) => e['muscle'] as String).toSet().toList()];
    final types = ['Tous', 'Poids libre', 'Machine', 'Poids du corps'];
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, title: const Text('Bibliothèque d\'exercices', style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.bold)), iconTheme: const IconThemeData(color: kText), elevation: 0),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(children: [
            TextField(
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: kText, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher un exercice...', hintStyle: const TextStyle(color: kTextDim, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: kTextDim, size: 20),
                filled: true, fillColor: kCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              ...muscles.map((m) => Clickable(
                onTap: () => setState(() => _filterMuscle = m),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _filterMuscle == m ? kOrange : kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: _filterMuscle == m ? kOrange : kBorder)),
                  child: Text(m, style: TextStyle(fontSize: 12, color: _filterMuscle == m ? Colors.white : kTextMid, fontWeight: _filterMuscle == m ? FontWeight.w600 : FontWeight.normal)),
                ),
              )).toList(),
            ])),
            const SizedBox(height: 8),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              ...types.map((t) => Clickable(
                onTap: () => setState(() => _filterType = t),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _filterType == t ? kBlue : kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: _filterType == t ? kBlue : kBorder)),
                  child: Text(t, style: TextStyle(fontSize: 12, color: _filterType == t ? Colors.white : kTextMid, fontWeight: _filterType == t ? FontWeight.w600 : FontWeight.normal)),
                ),
              )).toList(),
            ])),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final ex = filtered[i];
            return Clickable(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseDetailPage(exercise: ex))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: (ex['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(ex['icon'] as String, style: const TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ex['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kText)),
                    const SizedBox(height: 3),
                    Text('${ex['muscle']} · ${ex['type']}', style: const TextStyle(fontSize: 12, color: kTextDim)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: (ex['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(ex['difficulty'] as String, style: TextStyle(fontSize: 10, color: ex['color'] as Color, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: kTextDim),
                ]),
              ),
            );
          },
        )),
      ]),
    );
  }
}

// ===================== EXERCISE DETAIL PAGE =====================
class ExerciseDetailPage extends StatelessWidget {
  final Map<String, dynamic> exercise;
  const ExerciseDetailPage({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final color = exercise['color'] as Color? ?? kOrange;
    final steps = [
      'Mets-toi en position de départ, pieds écartés à la largeur des épaules.',
      'Engage le gainage abdominal et garde le dos droit.',
      'Effectue le mouvement de manière contrôlée en inspirant.',
      'Atteins la position basse optimale.',
      'Remonte de manière explosive en expirant.',
      'Répète le mouvement pour le nombre de répétitions prescrit.',
    ];
    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          backgroundColor: kBg,
          expandedHeight: 180,
          pinned: true,
          iconTheme: const IconThemeData(color: kText),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(0.2), kBg])),
              child: Center(child: Text(exercise['icon'] as String? ?? '💪', style: const TextStyle(fontSize: 80))),
            ),
          ),
          title: Text(exercise['name'] as String, style: const TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverList(delegate: SliverChildListDelegate([
            // Tags
            Row(children: [
              _tag(exercise['muscle'] as String, color),
              const SizedBox(width: 8),
              _tag(exercise['type'] as String, kCard3),
              const SizedBox(width: 8),
              _tag(exercise['difficulty'] as String, kCard3),
            ]),
            const SizedBox(height: 24),
            // Description
            const Text('DESCRIPTION', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Text('Le ${exercise['name']} est un exercice fondamental ciblant principalement les ${exercise['muscle']}. C\'est un mouvement polyarticulaire qui engage plusieurs groupes musculaires simultanément pour des gains optimaux.', style: const TextStyle(fontSize: 14, color: kTextMid, height: 1.6)),
            const SizedBox(height: 24),
            // Étapes
            const Text('ÉTAPES D\'EXÉCUTION', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            ...steps.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                  child: Center(child: Text('${e.key + 1}', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, color: kTextMid, height: 1.5))),
              ]),
            )).toList(),
            const SizedBox(height: 24),
            // Vidéo placeholder
            const Text('VIDÉO DÉMO', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Container(
              height: 160,
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.play_circle_outline_rounded, size: 48, color: color.withOpacity(0.5)),
                const SizedBox(height: 8),
                Text('Vidéo disponible prochainement', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3))),
              ]),
            ),
            const SizedBox(height: 24),
            // Analyse IA
            const Text('ANALYSE IA', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kOrange.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kOrange.withOpacity(0.2)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.psychology_rounded, color: kOrange, size: 18),
                  const SizedBox(width: 8),
                  const Text('Analyse ton mouvement en temps réel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kText)),
                ]),
                const SizedBox(height: 8),
                const Text('Filme-toi pendant l\'exercice et reçois un feedback IA instantané sur ta technique.', style: TextStyle(fontSize: 12, color: kTextDim, height: 1.5)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.videocam_rounded, size: 16),
                    label: const Text('Analyser mon mouvement', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.lightbulb_outline_rounded, color: kYellow, size: 16),
                  SizedBox(width: 8),
                  Text('Conseils IA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kText)),
                ]),
                const SizedBox(height: 8),
                Text('Concentre-toi sur la qualité d\'exécution plutôt que la charge. Assure-toi de bien contrôler la phase excentrique pour maximiser les gains musculaires.', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6), height: 1.5)),
              ]),
            ),
          ])),
        ),
      ]),
    );
  }

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color == kCard3 ? kCard3 : color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(fontSize: 11, color: color == kCard3 ? kTextMid : color, fontWeight: FontWeight.w600)),
  );
}

// ===================== AI PROGRAMS PAGE =====================
class AIProgramsPage extends StatefulWidget {
  final String deviceId;
  const AIProgramsPage({super.key, required this.deviceId});
  @override
  State<AIProgramsPage> createState() => _AIProgramsPageState();
}

class _AIProgramsPageState extends State<AIProgramsPage> {
  List<Map<String, dynamic>> programs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPrograms();
  }

  Future<void> loadPrograms() async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/ai-programs/'),
        headers: {'x-device-id': widget.deviceId},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() { programs = data.map((e) => Map<String, dynamic>.from(e)).toList(); loading = false; });
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> deleteProgram(int id) async {
    await http.delete(Uri.parse('$kBaseUrl/ai-programs/$id'), headers: {'x-device-id': widget.deviceId});
    loadPrograms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        title: const Text('Programmes IA', style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: kText),
        elevation: 0,
        actions: [IconButton(onPressed: loadPrograms, icon: const Icon(Icons.refresh_rounded, color: kTextDim, size: 20))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(children: [
          // Bouton générer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: kPurple.withOpacity(0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: kPurple.withOpacity(0.2))),
            child: Column(children: [
              const Icon(Icons.auto_awesome_rounded, color: kPurple, size: 32),
              const SizedBox(height: 12),
              const Text('Génère ton programme IA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kText)),
              const SizedBox(height: 6),
              Text('Dis à ton coach IA tes objectifs et il créera un programme sur mesure.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5), height: 1.5)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.psychology_rounded, size: 16),
                label: const Text('Demander au Coach IA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(backgroundColor: kPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          const Align(alignment: Alignment.centerLeft, child: Text('MES PROGRAMMES', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2))),
          const SizedBox(height: 12),
          if (loading)
            const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: kOrange, strokeWidth: 2))
          else if (programs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Aucun programme généré pour l\'instant.\nDemande à ton coach IA de créer le tien !', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.2), height: 1.6)),
            )
          else
            ...programs.map((p) => Clickable(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AIProgramDetailPage(program: p))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kPurple.withOpacity(0.2))),
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: kPurple.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Icon(Icons.auto_awesome_rounded, color: kPurple, size: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['title'] ?? 'Programme IA', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kText)),
                    const SizedBox(height: 3),
                    Text('${p['objective']} · ${p['created_at']}', style: const TextStyle(fontSize: 12, color: kTextDim)),
                  ])),
                  Clickable(
                    onTap: () => deleteProgram(p['id']),
                    child: Padding(padding: const EdgeInsets.only(left: 8), child: Icon(Icons.close_rounded, size: 16, color: Colors.white.withOpacity(0.2))),
                  ),
                ]),
              ),
            )).toList(),
        ]),
      ),
    );
  }
}


Map<String, dynamic> _parseTrainingProgram(String text) {
  final days = <Map<String, dynamic>>[];
  final dayNames = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche', 'jour 1', 'jour 2', 'jour 3', 'jour 4', 'jour 5', 'jour 6', 'jour 7', 'day 1', 'day 2', 'day 3', 'day 4', 'day 5', 'day 6', 'day 7'];
  
  final lines = text.split('\n');
  Map<String, dynamic>? currentDay;
  List<Map<String, dynamic>> currentExercises = [];

  for (final line in lines) {
    final lower = line.toLowerCase().trim();
    
    // Détecter un nouveau jour
    final dayMatch = dayNames.firstWhere(
      (d) => lower.contains(d),
      orElse: () => '',
    );
    
    if (dayMatch.isNotEmpty && (lower.startsWith(dayMatch) || lower.contains('**$dayMatch') || lower.contains('## $dayMatch') || lower.contains('# $dayMatch') || RegExp(r'^[*#\s]*' + dayMatch).hasMatch(lower))) {
      if (currentDay != null) {
        currentDay['exercises'] = List.from(currentExercises);
        days.add(currentDay);
      }
      // Extraire le label (ex: Push, Pull, Legs)
      String label = '';
      final labelMatch = RegExp(r'[-–:]\s*(.+)$').firstMatch(line);
      if (labelMatch != null) label = labelMatch.group(1)?.trim() ?? '';
      
      currentDay = {'day': _capitalizeDay(dayMatch), 'label': label};
      currentExercises = [];
      continue;
    }

    // Détecter un exercice
    if (currentDay != null) {
      final exMatch = RegExp(r'[-•*]\s*(.+?)(?:\s*[:\-]\s*|\s+)(\d+)\s*[xX×]\s*(\d+[-–]?\d*)', caseSensitive: false).firstMatch(line);
      if (exMatch != null) {
        currentExercises.add({
          'name': exMatch.group(1)?.trim() ?? line.trim(),
          'sets': exMatch.group(2) ?? '3',
          'reps': exMatch.group(3) ?? '8-12',
          'rest': '60-90s',
        });
      } else if (line.trim().isNotEmpty && (line.trim().startsWith('-') || line.trim().startsWith('•') || line.trim().startsWith('*'))) {
        final name = line.trim().replaceAll(RegExp(r'^[-•*]\s*'), '');
        if (name.isNotEmpty && name.length > 3) {
          currentExercises.add({'name': name, 'sets': '3', 'reps': '8-12', 'rest': '60s'});
        }
      }
    }
  }

  if (currentDay != null) {
    currentDay['exercises'] = List.from(currentExercises);
    days.add(currentDay);
  }

  return {'days': days, 'tips': []};
}

String _capitalizeDay(String day) {
  if (day.isEmpty) return day;
  return day[0].toUpperCase() + day.substring(1);
}


// ===================== AI PROGRAM DETAIL PAGE =====================
class AIProgramDetailPage extends StatelessWidget {
  final Map<String, dynamic> program;
  const AIProgramDetailPage({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
  Map<String, dynamic> structured = {};
    String rawText = '';
    try {
      final decoded = jsonDecode(program['content'] ?? '{}');
      if (decoded['raw'] != null) {
        rawText = decoded['raw'] as String;
        structured = _parseTrainingProgram(rawText);
      } else {
        structured = decoded;
      }
    } catch (_) {}

    final days = (structured['days'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    final tips = (structured['tips'] as List? ?? []).map((e) => e.toString()).toList();

    final dayColors = [kOrange, kBlue, kPurple, kGreen, kYellow, kOrangeLight, kRed];
    final dayIcons = ['💪', '🔝', '🦵', '💪', '🔝', '🦵', '🧘'];

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        title: Text(program['title'] ?? 'Programme IA', style: const TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: kText),
        elevation: 0,
      ),
      body: days.isEmpty
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: MarkdownBody(data: program['content'] ?? '', styleSheet: MarkdownStyleSheet(p: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), height: 1.6))),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Header objectif
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: kPurple.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text('${program['objective']} · ${program['created_at']}', style: const TextStyle(fontSize: 12, color: kPurple, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),

                // Jours
                const Text('PROGRAMME', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                ...days.asMap().entries.map((entry) {
                  final i = entry.key;
                  final day = entry.value;
                  final color = dayColors[i % dayColors.length];
                  final icon = dayIcons[i % dayIcons.length];
                  final exercises = (day['exercises'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(0.25))),
                    child: Column(children: [
                      // Header du jour
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                        ),
                        child: Row(children: [
                          Text(icon, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(day['day'] ?? 'Jour ${i + 1}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
                            if (day['label'] != null) Text(day['label'] as String, style: const TextStyle(fontSize: 12, color: kTextDim)),
                          ]),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                            child: Text('${exercises.length} exos', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                          ),
                        ]),
                      ),
                      // Exercices
                      ...exercises.asMap().entries.map((exEntry) {
                        final ex = exEntry.value;
                        return Clickable(
                          onTap: () {
                            final found = mockExercises.firstWhere(
                              (e) => (e['name'] as String).toLowerCase().contains((ex['name'] as String? ?? '').toLowerCase().split(' ').first),
                              orElse: () => {'name': ex['name'] ?? '', 'muscle': '--', 'type': '--', 'difficulty': '--', 'icon': '💪', 'color': kOrange},
                            );
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseDetailPage(exercise: found)));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder.withOpacity(0.5)))),
                            child: Row(children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Center(child: Text('${exEntry.key + 1}', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(ex['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kText)),
                                if (ex['sets'] != null || ex['reps'] != null)
                                  Text('${ex['sets'] ?? '?'} séries × ${ex['reps'] ?? '?'} reps${ex['rest'] != null ? ' · Repos ${ex['rest']}' : ''}', style: const TextStyle(fontSize: 11, color: kTextDim)),
                              ])),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: kTextDim),
                            ]),
                          ),
                        );
                      }).toList(),
                    ]),
                  );
                }).toList(),

                // Conseils
                if (tips.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('CONSEILS', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kOrange.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: kOrange.withOpacity(0.15))),
                    child: Column(children: tips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('💡 ', style: TextStyle(fontSize: 13)),
                        Expanded(child: Text(tip, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7), height: 1.5))),
                      ]),
                    )).toList()),
                  ),
                ],
              ]),
            ),
    );
  }
}

// ===================== NUTRITION PAGE V2 =====================
class NutritionPageV2 extends StatelessWidget {
  final Map<String, String> userData;
  final String deviceId;
  const NutritionPageV2({super.key, required this.userData, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(bottom: false, child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Nutrition', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kText)),
        const SizedBox(height: 4),
        Text('Alimentation & Recettes', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.35))),
        const SizedBox(height: 24),
        // Calories du jour
        _buildCaloriesCard(),
        const SizedBox(height: 20),
        // 2 grands widgets
        _hubCard(context, icon: Icons.restaurant_rounded, color: kGreen, title: 'Recettes prédéfinies', description: 'Repas équilibrés adaptés à tes objectifs', tag: '${mockRecipes.length} recettes', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipesPage()))),
        const SizedBox(height: 14),
        _hubCard(context, icon: Icons.auto_awesome_rounded, color: kOrange, title: 'Plans nutrition IA', description: 'Plans alimentaires générés par ton coach IA', tag: 'Personnalisé', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AINutritionPage(deviceId: deviceId)))),
      ]),
    ));
  }

  Widget _buildCaloriesCard() {
    const target = 2400;
    const consumed = 1200;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
      child: Column(children: [
        Row(children: [
          const Text("AUJOURD'HUI", style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const Spacer(),
          const Text('$consumed / $target kcal', style: TextStyle(fontSize: 13, color: kTextMid)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: consumed / target, backgroundColor: kBorder, valueColor: const AlwaysStoppedAnimation(kGreen), minHeight: 8)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _macro('Protéines', '87g', kGreen),
          _macro('Glucides', '120g', kBlue),
          _macro('Lipides', '42g', kYellow),
        ]),
      ]),
    );
  }

  Widget _macro(String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 11, color: kTextDim)),
  ]);

  Widget _hubCard(BuildContext context, {required IconData icon, required Color color, required String title, required String description, required String tag, required VoidCallback onTap}) {
    return Clickable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2)), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(0.05), Colors.transparent])),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kText)),
            const SizedBox(height: 3),
            Text(description, style: const TextStyle(fontSize: 12, color: kTextDim)),
            const SizedBox(height: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(tag, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600))),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.5), size: 14),
        ]),
      ),
    );
  }
}

// ===================== RECIPES PAGE =====================
class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final meals = ['Petit déjeuner', 'Déjeuner', 'Snack', 'Dîner'];
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, title: const Text('Recettes', style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.bold)), iconTheme: const IconThemeData(color: kText), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: meals.map((meal) {
          final recipes = mockRecipes.where((r) => r['meal'] == meal).toList();
          if (recipes.isEmpty) return const SizedBox();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(meal.toUpperCase(), style: const TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2))),
            ...recipes.map((r) => Clickable(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: r))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
                child: Row(children: [
                  Container(width: 48, height: 48, decoration: BoxDecoration(color: (r['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(r['icon'] as String, style: const TextStyle(fontSize: 24)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kText)),
                    const SizedBox(height: 3),
                    Text('${r['calories']} kcal · ${r['protein']}g protéines · ${r['time']}', style: const TextStyle(fontSize: 12, color: kTextDim)),
                  ])),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: kTextDim),
                ]),
              ),
            )).toList(),
          ]);
        }).toList(),
      ),
    );
  }
}

// ===================== RECIPE DETAIL PAGE =====================
class RecipeDetailPage extends StatelessWidget {
  final Map<String, dynamic> recipe;
  const RecipeDetailPage({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final color = recipe['color'] as Color;
    final ingredients = ['200g de blanc de poulet', '150g de riz', '2 œufs', '1 poignée d\'épinards', 'Sel, poivre, épices'];
    final steps = ['Préparer tous les ingrédients.', 'Cuire le riz selon les instructions.', 'Faire revenir le poulet avec les épices.', 'Mélanger et servir chaud.'];
    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          backgroundColor: kBg,
          expandedHeight: 160,
          pinned: true,
          iconTheme: const IconThemeData(color: kText),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withOpacity(0.2), kBg])),
              child: Center(child: Text(recipe['icon'] as String, style: const TextStyle(fontSize: 72))),
            ),
          ),
          title: Text(recipe['name'] as String, style: const TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverList(delegate: SliverChildListDelegate([
            // Macros
            Row(children: [
              _macro('Calories', '${recipe['calories']} kcal', color),
              const SizedBox(width: 10),
              _macro('Protéines', '${recipe['protein']}g', kGreen),
              const SizedBox(width: 10),
              _macro('Temps', recipe['time'] as String, kBlue),
            ]),
            const SizedBox(height: 24),
            // Pourquoi adaptée
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Icons.auto_awesome_rounded, color: color, size: 16), const SizedBox(width: 8), const Text('Pourquoi cette recette ?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kText))]),
                const SizedBox(height: 8),
                Text('Cette recette est adaptée à ton objectif car elle apporte un ratio optimal de protéines et de glucides pour la récupération musculaire après l\'entraînement.', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6), height: 1.5)),
              ]),
            ),
            const SizedBox(height: 20),
            const Text('INGRÉDIENTS', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            ...ingredients.map((ing) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Text(ing, style: const TextStyle(fontSize: 13, color: kTextMid)),
              ]),
            )).toList(),
            const SizedBox(height: 20),
            const Text('PRÉPARATION', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            ...steps.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Container(width: 24, height: 24, decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Center(child: Text('${e.key + 1}', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, color: kTextMid))),
              ]),
            )).toList(),
            const SizedBox(height: 16),
            Container(height: 140, decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.play_circle_outline_rounded, size: 40, color: color.withOpacity(0.5)),
              const SizedBox(height: 6),
              Text('Vidéo disponible prochainement', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3))),
            ])),
          ])),
        ),
      ]),
    );
  }

  Widget _macro(String label, String value, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: kTextDim)),
    ]),
  ));
}

// ===================== AI NUTRITION PAGE =====================
class AINutritionPage extends StatefulWidget {
  final String deviceId;
  const AINutritionPage({super.key, required this.deviceId});
  @override
  State<AINutritionPage> createState() => _AINutritionPageState();
}

class _AINutritionPageState extends State<AINutritionPage> {
  List<Map<String, dynamic>> plans = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPlans();
  }

  Future<void> loadPlans() async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/ai-nutrition-plans/'),
        headers: {'x-device-id': widget.deviceId},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() { plans = data.map((e) => Map<String, dynamic>.from(e)).toList(); loading = false; });
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> deletePlan(int id) async {
    await http.delete(Uri.parse('$kBaseUrl/ai-nutrition-plans/$id'), headers: {'x-device-id': widget.deviceId});
    loadPlans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        title: const Text('Plans nutrition IA', style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: kText),
        elevation: 0,
        actions: [IconButton(onPressed: loadPlans, icon: const Icon(Icons.refresh_rounded, color: kTextDim, size: 20))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: kOrange.withOpacity(0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: kOrange.withOpacity(0.2))),
            child: Column(children: [
              const Icon(Icons.restaurant_rounded, color: kOrange, size: 32),
              const SizedBox(height: 12),
              const Text('Plan nutritionnel IA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kText)),
              const SizedBox(height: 6),
              Text('Ton coach IA crée un plan alimentaire sur mesure.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5), height: 1.5)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Demander au Coach IA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          const Align(alignment: Alignment.centerLeft, child: Text('MES PLANS', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2))),
          const SizedBox(height: 12),
          if (loading)
            const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: kOrange, strokeWidth: 2))
          else if (plans.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Aucun plan généré pour l\'instant.\nDemande à ton coach IA de créer le tien !', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.2), height: 1.6)),
            )
          else
            ...plans.map((p) => Clickable(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AINutritionDetailPage(plan: p))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kOrange.withOpacity(0.2))),
                child: Row(children: [
                  Container(width: 48, height: 48, decoration: BoxDecoration(color: kOrange.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: const Center(child: Icon(Icons.restaurant_rounded, color: kOrange, size: 22))),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['title'] ?? 'Plan nutrition IA', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kText)),
                    const SizedBox(height: 3),
                    Text('${p['objective']} · ${p['created_at']}', style: const TextStyle(fontSize: 12, color: kTextDim)),
                  ])),
                  Clickable(onTap: () => deletePlan(p['id']), child: Padding(padding: const EdgeInsets.only(left: 8), child: Icon(Icons.close_rounded, size: 16, color: Colors.white.withOpacity(0.2)))),
                ]),
              ),
            )).toList(),
        ]),
      ),
    );
  }
}


Map<String, dynamic> _parseNutritionPlan(String text) {
  final days = <Map<String, dynamic>>[];
  final dayNames = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche', 'jour 1', 'jour 2', 'jour 3', 'jour 4', 'jour 5', 'jour 6', 'jour 7'];
  final mealNames = ['petit déjeuner', 'déjeuner', 'dîner', 'collation', 'snack', 'goûter'];

  final lines = text.split('\n');
  Map<String, dynamic>? currentDay;
  Map<String, dynamic>? currentMeal;
  List<Map<String, dynamic>> currentMeals = [];
  List<String> currentFoods = [];

  void saveMeal() {
    if (currentMeal != null) {
      currentMeal!['foods'] = List.from(currentFoods);
      currentMeals.add(currentMeal!);
      currentMeal = null;
      currentFoods = [];
    }
  }

  void saveDay() {
    saveMeal();
    if (currentDay != null) {
      currentDay!['meals'] = List.from(currentMeals);
      days.add(currentDay!);
      currentDay = null;
      currentMeals = [];
    }
  }

  for (final line in lines) {
    final lower = line.toLowerCase().trim();

    // Détecter un nouveau jour
    final dayMatch = dayNames.firstWhere((d) => lower.contains(d), orElse: () => '');
    if (dayMatch.isNotEmpty && (lower.startsWith(dayMatch) || RegExp(r'^[*#\s]*' + dayMatch).hasMatch(lower))) {
      saveDay();
      currentDay = {'day': dayMatch[0].toUpperCase() + dayMatch.substring(1), 'total_calories': 0, 'total_protein': 0};
      continue;
    }

    // Détecter un repas
    final mealMatch = mealNames.firstWhere((m) => lower.contains(m), orElse: () => '');
    if (mealMatch.isNotEmpty && currentDay != null) {
      saveMeal();
      // Extraire calories et protéines
      int cal = 0; int prot = 0;
      final calMatch = RegExp(r'(\d+)\s*cal').firstMatch(lower);
      final protMatch = RegExp(r'(\d+)g?\s*(?:de\s*)?prot').firstMatch(lower);
      if (calMatch != null) cal = int.tryParse(calMatch.group(1) ?? '0') ?? 0;
      if (protMatch != null) prot = int.tryParse(protMatch.group(1) ?? '0') ?? 0;
      currentMeal = {'name': mealMatch[0].toUpperCase() + mealMatch.substring(1), 'calories': cal, 'protein': prot};
      continue;
    }

    // Ajouter un aliment
    if (currentMeal != null && line.trim().isNotEmpty) {
      final food = line.trim().replaceAll(RegExp(r'^[-•*]\s*'), '');
      if (food.isNotEmpty && food.length > 2) currentFoods.add(food);
    }
  }
  saveDay();

  return {'days': days, 'tips': []};
}



// ===================== AI NUTRITION DETAIL PAGE =====================
class AINutritionDetailPage extends StatelessWidget {
  final Map<String, dynamic> plan;
  const AINutritionDetailPage({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> structured = {};
    try {
      structured = jsonDecode(plan['content'] ?? '{}');
    } catch (_) {}

    final days = (structured['days'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    final tips = (structured['tips'] as List? ?? []).map((e) => e.toString()).toList();
    final mealIcons = {'petit déjeuner': '🌅', 'déjeuner': '☀️', 'dîner': '🌙', 'snack': '🍎', 'collation': '🍎'};

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        title: Text(plan['title'] ?? 'Plan nutrition IA', style: const TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: kText),
        elevation: 0,
      ),
      body: days.isEmpty
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: MarkdownBody(data: plan['content'] ?? '', styleSheet: MarkdownStyleSheet(p: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), height: 1.6))),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: kOrange.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text('${plan['objective']} · ${plan['created_at']}', style: const TextStyle(fontSize: 12, color: kOrange, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),
                const Text('PLAN ALIMENTAIRE', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                ...days.map((day) {
                  final meals = (day['meals'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kGreen.withOpacity(0.2))),
                    child: Column(children: [
                      // Header jour
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: kGreen.withOpacity(0.07), borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18))),
                        child: Row(children: [
                          const Text('🥗', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Text(day['day'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kGreen)),
                          const Spacer(),
                          if (day['total_calories'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: kGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                              child: Text('${day['total_calories']} kcal', style: const TextStyle(fontSize: 11, color: kGreen, fontWeight: FontWeight.w600)),
                            ),
                        ]),
                      ),
                      // Repas
                      ...meals.map((meal) {
                        final mealName = (meal['name'] as String? ?? '').toLowerCase();
                        final icon = mealIcons.entries.firstWhere((e) => mealName.contains(e.key), orElse: () => const MapEntry('', '🍽️')).value;
                        final foods = (meal['foods'] as List? ?? []).map((e) => e.toString()).toList();
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder.withOpacity(0.4)))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(icon, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(meal['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kText)),
                              const Spacer(),
                              if (meal['calories'] != null || meal['protein'] != null)
                                Text('${meal['calories'] ?? '?'} kcal · ${meal['protein'] ?? '?'}g prot', style: const TextStyle(fontSize: 11, color: kTextDim)),
                            ]),
                            if (foods.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ...foods.map((food) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(children: [
                                  Container(width: 5, height: 5, margin: const EdgeInsets.only(right: 8, top: 2), decoration: BoxDecoration(color: kGreen.withOpacity(0.5), shape: BoxShape.circle)),
                                  Expanded(child: Text(food, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)))),
                                ]),
                              )).toList(),
                            ],
                          ]),
                        );
                      }).toList(),
                    ]),
                  );
                }).toList(),

                if (tips.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('CONSEILS', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kOrange.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: kOrange.withOpacity(0.15))),
                    child: Column(children: tips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('💡 ', style: TextStyle(fontSize: 13)),
                        Expanded(child: Text(tip, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7), height: 1.5))),
                      ]),
                    )).toList()),
                  ),
                ],
              ]),
            ),
    );
  }
}

// ===================== PROGRESS PAGE V2 =====================
class ProgressPageV2 extends StatelessWidget {
  final Map<String, String> userData;
  const ProgressPageV2({super.key, required this.userData});

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

    final analyses = [
      {'exercise': 'Squat', 'score': 85, 'date': '12/05', 'icon': '🦵', 'color': kOrange},
      {'exercise': 'Développé couché', 'score': 72, 'date': '10/05', 'icon': '💪', 'color': kBlue},
      {'exercise': 'Deadlift', 'score': 90, 'date': '08/05', 'icon': '⚡', 'color': kPurple},
    ];

    return SafeArea(bottom: false, child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Progression', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kText)),
        const SizedBox(height: 4),
        Text('Tes performances', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.35))),
        const SizedBox(height: 24),

        // Stats rapides
        const Text('STATS RAPIDES', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6,
          children: [
            _statCard('Poids', '$weight kg', Icons.monitor_weight_outlined, Colors.blue),
            _statCard('Séances', '$sessions/sem', Icons.bolt_rounded, kOrange),
            _statCard('Streak', '$streak jours 🔥', Icons.local_fire_department_rounded, kYellow),
            _statCard('Score', '$lastScore/100', Icons.analytics_rounded, kGreen),
          ],
        ),
        const SizedBox(height: 24),

        // Charges
        const Text('MES CHARGES', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
          child: Column(children: [
            _exerciseBar('Squat', squat != '--' ? '$squat kg' : 'Non renseigné', squat != '--' ? (double.tryParse(squat) ?? 0) / 200 : 0.3, kOrange),
            _exerciseBar('Développé couché', bench != '--' ? '$bench kg' : 'Non renseigné', bench != '--' ? (double.tryParse(bench) ?? 0) / 150 : 0.3, kBlue),
            _exerciseBar('Soulevé de terre', deadlift != '--' ? '$deadlift kg' : 'Non renseigné', deadlift != '--' ? (double.tryParse(deadlift) ?? 0) / 250 : 0.3, kPurple),
          ]),
        ),
        const SizedBox(height: 24),

        // Streak calendar
        const Text('CALENDRIER STREAK', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildStreakCalendar(),
        const SizedBox(height: 24),

        // Historique analyses IA
        const Text('HISTORIQUE ANALYSES IA', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ...analyses.map((a) {
          final score = a['score'] as int;
          final color = score >= 80 ? kGreen : score >= 60 ? kOrange : kRed;
          return Clickable(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.15))),
              child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: (a['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(a['icon'] as String, style: const TextStyle(fontSize: 20)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a['exercise'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kText)),
                  Text(a['date'] as String, style: const TextStyle(fontSize: 12, color: kTextDim)),
                ])),
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Center(child: Text('$score', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color))),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: kTextDim),
              ]),
            ),
          );
        }).toList(),
        const SizedBox(height: 24),

        // Bilan IA global
        const Text('BILAN IA GLOBAL', style: TextStyle(fontSize: 11, color: Color(0xFF555555), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kOrange.withOpacity(0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.auto_awesome_rounded, color: kOrange, size: 18)),
              const SizedBox(width: 10),
              const Text('Analyse IA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kText)),
            ]),
            const SizedBox(height: 12),
            Text(goal.isNotEmpty ? 'Objectif : $goal. Continue à travailler et parle à ton coach pour un bilan complet !' : 'Génère un bilan IA complet de tes performances de la semaine.', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.55), height: 1.6)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.psychology_rounded, size: 16),
                label: const Text('Générer mon bilan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              ),
            ),
          ]),
        ),
      ]),
    ));
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kText), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: kTextDim)),
      ]),
    );
  }

  Widget _exerciseBar(String name, String value, double progress, Color color) {
    return Container(margin: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(name, style: const TextStyle(fontSize: 13, color: kText, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, color: kTextDim)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), backgroundColor: kBorder, valueColor: AlwaysStoppedAnimation(color), minHeight: 6)),
    ]));
  }

  Widget _buildStreakCalendar() {
    final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final weeks = [
      [true, true, false, true, true, false, false],
      [true, false, true, true, false, true, false],
      [false, true, true, false, true, true, true],
      [true, true, false, true, false, false, false],
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: days.map((d) => SizedBox(width: 28, child: Text(d, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: kTextDim, fontWeight: FontWeight.w600)))).toList()),
        const SizedBox(height: 8),
        ...weeks.map((week) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: week.map((done) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: done ? kOrange : kCard2,
              borderRadius: BorderRadius.circular(6),
            ),
            child: done ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
          )).toList()),
        )).toList(),
      ]),
    );
  }
}

// ===================== PROFILE PAGE V2 =====================
class ProfilePageV2 extends StatefulWidget {
  final Map<String, String> userData;
  final String deviceId;
  const ProfilePageV2({super.key, required this.userData, required this.deviceId});
  @override
  State<ProfilePageV2> createState() => _ProfilePageV2State();
}

class _ProfilePageV2State extends State<ProfilePageV2> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  String selectedLevel = 'debutant';
  bool saved = false;

  final levels = [
    {'key': 'debutant', 'label': 'Débutant'},
    {'key': 'intermediaire', 'label': 'Inter.'},
    {'key': 'avance', 'label': 'Avancé'},
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.userData['name'] ?? '';
    _ageCtrl.text = widget.userData['age'] ?? '';
    _weightCtrl.text = widget.userData['weight'] ?? '';
    _heightCtrl.text = widget.userData['height'] ?? '';
    _goalCtrl.text = widget.userData['goal'] ?? '';
    selectedLevel = widget.userData['level']?.isNotEmpty == true ? widget.userData['level']! : 'debutant';
  }

  Future<void> saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _nameCtrl.text);
    await prefs.setString('age', _ageCtrl.text);
    await prefs.setString('weight', _weightCtrl.text);
    await prefs.setString('height', _heightCtrl.text);
    await prefs.setString('goal', _goalCtrl.text);
    await prefs.setString('level', selectedLevel);
    final data = {'name': _nameCtrl.text, 'age': _ageCtrl.text, 'weight': _weightCtrl.text, 'height': _heightCtrl.text, 'goal': _goalCtrl.text, 'level': selectedLevel};
    var request = http.MultipartRequest('PUT', Uri.parse('$kBaseUrl/user-data/'));
    request.headers['x-device-id'] = widget.deviceId;
    request.fields['data'] = jsonEncode(data);
    await request.send();
    setState(() => saved = true);
    Future.delayed(const Duration(seconds: 1), () { if (mounted) Navigator.pop(context); });
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint, TextInputType? type}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF666666), fontWeight: FontWeight.w600, letterSpacing: 0.8)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl, keyboardType: type,
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
      const SizedBox(height: 14),
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
            Text('Mon profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kText)),
            Text('Le coach adapte ses conseils à ton profil', style: TextStyle(fontSize: 12, color: kTextDim)),
          ])),
          Clickable(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: Color(0xFF555555), size: 20)),
        ]),
        const SizedBox(height: 24),
        _field('PRÉNOM', _nameCtrl, hint: 'Ex: Thomas'),
        Row(children: [
          Expanded(child: _field('ÂGE', _ageCtrl, hint: '25', type: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: _field('POIDS (kg)', _weightCtrl, hint: '80', type: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: _field('TAILLE (cm)', _heightCtrl, hint: '180', type: TextInputType.number)),
        ]),
        const Text('NIVEAU', style: TextStyle(fontSize: 11, color: Color(0xFF666666), fontWeight: FontWeight.w600, letterSpacing: 0.8)),
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
              child: Text(l['label']!, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : const Color(0xFF666666), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
            ),
          ));
        }).toList()),
        const SizedBox(height: 14),
        _field('OBJECTIF PRINCIPAL', _goalCtrl, hint: 'Ex: Prendre de la masse, perdre du poids...'),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: saveProfile,
            style: ElevatedButton.styleFrom(backgroundColor: saved ? kGreen : kOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
            child: Text(saved ? '✓ Sauvegardé !' : 'Sauvegarder', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}
