import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InkAIApp());
}

class InkAIApp extends StatelessWidget {
  const InkAIApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Color(0xFF0F0F0F)), home: HomeScreen());
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
  bool isProUser = false;
  Uint8List? _proImage;
  String? _freeImageUrl;
  final String stabilityApiKey = "sk-REPLACE_WITH_YOUR_KEY";
  final List<String> _styles = ["Tribal", "Minimalist", "Realistic", "Japanese", "Blackwork"];

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  bool _purchasePending = false;
  final String _kProId = "inkai_pro_monthly";

  @override
  void initState() {
    super.initState();
    _loadProStatus();
    _initStore();
  }

  Future<void> _loadProStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => isProUser = prefs.getBool('isPro')?? false);
  }

  Future<void> _setProStatus(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPro', v);
    setState(() => isProUser = v);
  }

  Future<void> _initStore() async {
    if (!await _inAppPurchase.isAvailable()) return;
    _subscription = _inAppPurchase.purchaseStream.listen((list) {
      for (var p in list) {
        if (p.status == PurchaseStatus.pending) setState(() => _purchasePending = true);
        else {
          if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) _setProStatus(true);
          setState(() => _purchasePending = false);
          if (p.pendingCompletePurchase) _inAppPurchase.completePurchase(p);
        }
      }
    });
    final res = await _inAppPurchase.queryProductDetails({_kProId});
    if (res.error == null) setState(() => _products = res.productDetails);
  }

  Future<void> _buyPro() async {
    if (_products.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload AAB to Play Console first!"))); return; }
    final param = PurchaseParam(productDetails: _products.first);
    await _inAppPurchase.buyNonConsumable(purchaseParam: param);
  }

  @override
  void dispose() { _subscription.cancel(); super.dispose(); }

  void _generateFree() async {
    setState(() => _isGenerating = true);
    final url = "https://image.pollinations.ai/prompt/${Uri.encodeComponent(_promptController.text)}?seed=${Random().nextInt(999999)}&width=1024&height=1024";
    await Future.delayed(Duration(milliseconds: 800));
    setState(() { _freeImageUrl = url; _proImage = null; _isGenerating = false; });
  }

  Future<void> _generatePro() async {
    setState(() => _isGenerating = true);
    try {
      final res = await http.post(Uri.parse("https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $stabilityApiKey"},
        body: jsonEncode({"text_prompts": [{"text": _promptController.text, "weight": 1}], "cfg_scale": 7, "height": 1024, "width": 1024, "samples": 1, "steps": 30}));
      if (res.statusCode == 200) { _proImage = base64Decode(jsonDecode(res.body)["artifacts"][0]["base64"]); _freeImageUrl = null; }
    } catch (e) {}
    setState(() => _isGenerating = false);
  }

  void _onGeneratePressed() { if (isProUser) _generatePro(); else _generateFree(); }

  void _showPaywall() {
    showModalBottomSheet(context: context, backgroundColor: Color(0xFF1E1E1E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Padding(padding: EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.workspace_premium, size: 60, color: Color(0xFF00FF88)),
        Text("Unlock PRO - \$15.99", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        if (_purchasePending) CircularProgressIndicator(color: Color(0xFF00FF88)) else SizedBox(width: double.infinity, height: 50,
          child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00FF88), foregroundColor: Colors.black),
            onPressed: _buyPro, child: Text(_products.isNotEmpty? "Buy PRO - ${_products.first.price}" : "Buy PRO - \$15.99 / month", style: TextStyle(fontWeight: FontWeight.bold)))),
      ])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Color(0xFF0F0F0F), title: Row(children: [
        Icon(isProUser? Icons.verified : Icons.brush, color: Color(0xFF00FF88)), SizedBox(width: 8),
        Text(isProUser? "InkAI PRO" : "InkAI Free"), Spacer(),
        GestureDetector(onTap: _showPaywall, child: Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: isProUser? Color(0xFF00FF88) : Colors.white24, borderRadius: BorderRadius.circular(20)), child: Text(isProUser? "PRO ✓" : "Go PRO \$15.99", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
      ])),
      body: SingleChildScrollView(padding: EdgeInsets.all(16), child: Column(children: [
        TextField(controller: _promptController, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "Tattoo Idea", filled: true, fillColor: Color(0xFF1E1E1E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        SizedBox(height: 12),
        Wrap(spacing: 8, children: _styles.map((s) => ChoiceChip(label: Text(s), selected: _selectedStyle == s, selectedColor: Color(0xFF00FF88), onSelected: (_) => setState(() => _selectedStyle = s))).toList()),
        SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isGenerating? null : _onGeneratePressed, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00FF88), foregroundColor: Colors.black), child: Text(isProUser? "Generate PRO" : "Generate Free"))),
        SizedBox(height: 20),
        if (_proImage!= null) Image.memory(_proImage!, height: 400) else if (_freeImageUrl!= null) Image.network(_freeImageUrl!, height: 400) else Container(height: 200, decoration: BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)), child: Center(child: Text("Design here"))),
      ])),
    );
  }
}
