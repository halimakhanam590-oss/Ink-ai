import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TattooApp(),
  ));
}

class TattooApp extends StatefulWidget {
  @override
  State<TattooApp> createState() => _TattooAppState();
}

class _TattooAppState extends State<TattooApp> {
  TextEditingController prompt = TextEditingController(text: "cyberpunk samurai");
  String imageUrl = "";
  bool loading = false;

  void generate() async {
    if(prompt.text.isEmpty) return;
    setState(() { loading = true; });
    await Future.delayed(Duration(seconds: 1));
    int seed = Random().nextInt(999999);
    String p = Uri.encodeComponent(prompt.text + ", blackwork tattoo, white background, ultra detailed, vector");
    setState(() {
      imageUrl = "https://image.pollinations.ai/prompt/$p?width=1024&height=1024&seed=$seed";
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("INKAI PRO - \$22", style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: prompt,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Tattoo idea likhen",
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFACC15), minimumSize: Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: generate,
              child: Text("GENERATE TATTOO - \$FREE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
            ),
            SizedBox(height: 10),
            Text("• 2 free generations left • No signup", style: TextStyle(color: Colors.white54, fontSize: 12)),
            SizedBox(height: 20),
            if (loading) CircularProgressIndicator(color: Color(0xFFFACC15)),
            if (imageUrl.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(imageUrl)),
            if (imageUrl.isEmpty && !loading) Container(
              height: 300,
              decoration: BoxDecoration(color: Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20)),
              child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.auto_awesome, size: 50, color: Colors.white24), SizedBox(height: 10), Text("No ink yet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("Type a prompt above", style: TextStyle(color: Colors.white54))]))
            )
          ],
        ),
      ),
    );
  }
}
