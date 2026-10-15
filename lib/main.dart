import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const InkAIApp());

class InkAIApp extends StatelessWidget {
  const InkAIApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF0F0F0F)), home: const HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _promptController = TextEditingController(text: "dragon tribal tattoo");
  String _selectedStyle = "Tribal";
  bool _isGenerating = false;
  bool isProUser = false; // EITA MAIN SWITCH
  Uint8List? _proImage;
  String? _freeImageUrl;

  final List<String> _styles = ["Tribal", "Minimalist", "Realistic", "Japanese", "Blackwork"];
  final String stabilityApiKey = "sk-REPLACE_WITH_YOUR_KEY"; // PRO KEY

  @override
  void initState() {
    super.initState();
    _loadProStatus();
  }

  Future<void> _loadProStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => isProUser = prefs.getBool('isPro') ?? false);
  }

  Future<void> _setProStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPro', value);
    setState(() => isProUser = value);
  }

  // LOGIC 1: FREE API
  void _generateFree() async {
    setState(() => _isGenerating = true);
    final prompt = "${_promptController.text}, ${_selectedStyle} tattoo style, high detail";
    final url = "https://image.pollinations.ai/prompt/${Uri.encodeComponent(prompt)}?seed=${Random().nextInt(999999)}&width=1024&height=1024&nologo=true";
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _freeImageUrl = url;
      _proImage = null;
      _isGenerating = false;
    });
  }

  // LOGIC 2: PRO API - STABILITY
  Future<void> _generatePro() async {
    if (stabilityApiKey.contains("REPLACE")) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("API Key bosan nai!"), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final res = await http.post(
        Uri.parse("https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $stabilityApiKey"},
        body: jsonEncode({"text_prompts": [{"text": "${_promptController.text}, ${_selectedStyle} tattoo, professional stencil", "weight": 1}], "cfg_scale": 7, "height": 1024, "width": 1024, "samples": 1, "steps": 30, "style_preset": "line-art"}),
      );
      if (res.statusCode == 200) {
        final base64Str = jsonDecode(res.body)["artifacts"][0]["base64"];
        setState(() {
          _proImage = base64Decode(base64Str);
          _freeImageUrl = null;
        });
      }
    } catch (e) {
      print(e);
    }
    setState(() => _isGenerating = false);
  }

  // MAIN GENERATE BUTTON LOGIC
  void _onGeneratePressed() {
    if (isProUser) {
      _generatePro(); // PRO USER -> STABILITY
    } else {
      _generateFree(); // NORMAL USER -> FREE
    }
  }

  void _showPaywall() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.workspace_premium, size: 50, color: Color(0xFF00FF88)),
          const SizedBox(height: 10),
          const Text("Go PRO 👑", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("• Unlimited Generation\n• Stability AI XL (4K Quality)\n• No Ads\n• Fast Generation", textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF88), foregroundColor: Colors.black),
              onPressed: () {
                _setProStatus(true); // PAYMENT SUCCESS HOLE EITA TRUE HOBE
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PRO Activated!")) );
              },
              child: const Text("TEST PRO UNLOCK - \$2.99"),
            ),
          ),
          const SizedBox(height: 10),
          const Text("Ekhane Google Play Billing / bKash add korben", style: TextStyle(fontSize: 10, color: Colors.white54))
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: Row(children: [Icon(isProUser ? Icons.verified : Icons.brush, color: const Color(0xFF00FF88)), const SizedBox(width: 8), Text(isProUser ? "InkAI PRO" : "InkAI Free"), const Spacer(), GestureDetector(onTap: _showPaywall, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: isProUser ? const Color(0xFF00FF88) : Colors.white24, borderRadius: BorderRadius.circular(20)), child: Text(isProUser ? "PRO ✓" : "Go PRO", style: TextStyle(color: isProUser ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold))))]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _promptController, style: const TextStyle(color: Colors.white), maxLines: 2, decoration: InputDecoration(labelText: "Tattoo Idea", filled: true, fillColor: const Color(0xFF1E1E1E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: _styles.map((s) => ChoiceChip(label: Text(s), selected: _selectedStyle == s, selectedColor: const Color(0xFF00FF88), onSelected: (_) => setState(() => _selectedStyle = s))).toList()),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isGenerating ? null : _onGeneratePressed, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF88), foregroundColor: Colors.black), child: _isGenerating ? const CircularProgressIndicator() : Text(isProUser ? "Generate PRO Tattoo (Stability)" : "Generate Free Tattoo"))),
          const SizedBox(height: 20),
          if (_isGenerating) const CircularProgressIndicator(color: Color(0xFF00FF88)) else if (_proImage != null) ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(_proImage!, height: 400)) else if (_freeImageUrl != null) ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(_freeImageUrl!, height: 400)) else Container(height: 200, decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)), child: const Center(child: Text("Design will appear here", style: TextStyle(color: Colors.white38)))),
        ]),
      ),
    );
  }
}
