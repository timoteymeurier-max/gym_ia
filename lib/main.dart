import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String videoName = "Aucune video selectionnee";
  String result = "";
  bool isLoading = false;
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
        result = "";
      });
    }
  }

  Future<void> uploadVideo() async {
    if (videoBytes == null) return;
    setState(() {
      isLoading = true;
      result = "";
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
      setState(() {
        result = body;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        result = "Erreur : $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gym AI Coach"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Analyse ton mouvement",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickVideo,
              child: const Text("Importer une video"),
            ),
            const SizedBox(height: 10),
            Text(
              videoName,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: videoBytes == null ? null : uploadVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text("Analyser"),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const CircularProgressIndicator(),
            if (result.isNotEmpty)
              Text(
                result,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}