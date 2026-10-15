import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(const InkAIApp());

class InkAIApp extends StatelessWidget {
  const InkAIApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: const Color(0xFF00FF88),
      ),
      home: const HomeScreen(),
    );
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
  String? _imageUrl;
  final List<String> _styles = ["Tribal", "Minimalist", "Realistic", "Japanese", "Blackwork", "Watercolor"];

  void _generate() async {
    if (_promptController.text.isEmpty) return;
    setState(() {
      _isGenerating = true;
    });

    // FREE API - Pollinations (No API Key Needed)
    final prompt = "${_promptController.text}, ${_selectedStyle} tattoo style, black and white, high detail, tattoo design, white background";
    final encodedPrompt = Uri.encodeComponent(prompt);
    final seed = Random().nextInt(999999);
    // This API needs no key!
    final url = "https://image.pollinations.ai/prompt/$encodedPrompt?seed=$seed&width=1024&height=1024&nologo=true&enhance=true";

    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _imageUrl = url;
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Row(
          children: [
            Icon(Icons.brush, color: Color(0xFF00FF88)),
            SizedBox(width: 8),
            Text("InkAI Pro", style: TextStyle(fontWeight: FontWeight.bold)),
            Spacer(),
            Text("API: Connected", style: TextStyle(fontSize: 10, color: Color(0xFF00FF88)))
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Tattoo Idea", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _promptController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Ex: lion with crown, snake, etc",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text("Style", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _styles.map((style) {
                      final isSelected = _selectedStyle == style;
                      return ChoiceChip(
                        label: Text(style),
                        selected: isSelected,
                        selectedColor: const Color(0xFF00FF88),
                        onSelected: (v) => setState(() => _selectedStyle = style),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isGenerating ? null : _generate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF88),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isGenerating
                          ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 10), Text("Generating with AI...")])
                          : const Text("Generate Tattoo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_imageUrl != null)
              Container(
                height: 400,
                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Center(child: Image.network(_imageUrl!, fit: BoxFit.contain, loadingBuilder: (c, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(color: Color(0xFF00FF88))), errorBuilder: (c, e, s) => const Center(child: Icon(Icons.error, color: Colors.white54)))),
                    Positioned(bottom: 10, right: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)), child: const Text("InkAI Pro - API", style: TextStyle(fontSize: 10, color: Colors.white)))),
                  ],
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
                child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.auto_awesome, size: 40, color: Colors.white24), SizedBox(height: 10), Text("Your tattoo design will appear here", style: TextStyle(color: Colors.white38))])),
              ),
          ],
        ),
      ),
    );
  }
}
