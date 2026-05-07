import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String videoName = "";
  String analysis = "";
  bool isLoading = false;
  bool isSuccess = false;
  Uint8List? videoBytes;

  Future<void> pickVideo() async {
    FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );
    if (picked != null) {
      setState(() {
        videoName = picked.files.single.name;
        videoBytes = picked.files.single.bytes;
        analysis = "";
        isSuccess = false;
      });
    }
  }

  Future<void> uploadVideo() async {
    if (videoBytes == null) return;
    setState(() {
      isLoading = true;
      analysis = "";
      isSuccess = false;
    });
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/upload/'),
      );
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        videoBytes!,
        filename: videoName,
      ));
      var response = await request.send();
      var body = await response.stream.bytesToString();
      final json = jsonDecode(body);
      String msg = json['analysis'] ?? "Aucun résultat";
      if (json['reps'] != null) {
        msg += "\n\nRepetitions detectees : ${json['reps']}";
      }
      if (json['knee_min'] != null) {
        msg += "\nAngle genou minimum : ${json['knee_min']}°";
      }
      if (json['hip_avg'] != null) {
        msg += "\nAngle hanche moyen : ${json['hip_avg']}°";
      }
      setState(() {
        analysis = msg;
        isLoading = false;
        isSuccess = true;
      });
    } catch (e) {
      setState(() {
        analysis = "Erreur de connexion au serveur.";
        isLoading = false;
        isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 48,
                  color: Color(0xFF6C63FF),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Gym AI Coach",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Analyse ta posture en quelques secondes",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),

              // Zone import vidéo
              GestureDetector(
                onTap: pickVideo,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  decoration: BoxDecoration(
                    color: videoBytes != null
                        ? const Color(0xFF6C63FF).withOpacity(0.15)
                        : const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: videoBytes != null
                          ? const Color(0xFF6C63FF)
                          : Colors.white.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        videoBytes != null
                            ? Icons.check_circle_outline
                            : Icons.video_library_outlined,
                        size: 40,
                        color: videoBytes != null
                            ? const Color(0xFF6C63FF)
                            : Colors.white.withOpacity(0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        videoBytes != null
                            ? videoName
                            : "Appuie pour importer une vidéo",
                        style: TextStyle(
                          fontSize: 14,
                          color: videoBytes != null
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          fontWeight: videoBytes != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (videoBytes != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          "Appuie pour changer",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bouton Analyser
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: videoBytes == null || isLoading ? null : uploadVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    disabledBackgroundColor: const Color(0xFF6C63FF).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Analyser",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Résultat
              if (analysis.isNotEmpty)
                AnimatedOpacity(
                  opacity: analysis.isNotEmpty ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? const Color(0xFF1A2E1A)
                          : const Color(0xFF2E1A1A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSuccess
                            ? const Color(0xFF4CAF50).withOpacity(0.4)
                            : const Color(0xFFFF5252).withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isSuccess
                                  ? Icons.analytics_outlined
                                  : Icons.error_outline,
                              color: isSuccess
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF5252),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isSuccess ? "Résultat de l'analyse" : "Erreur",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSuccess
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFFF5252),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          analysis,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}