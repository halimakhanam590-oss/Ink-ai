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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF0F0F0F)),
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
  bool isProUser = false;
  Uint8List? _proImage;
  String? _freeImageUrl;

  // 🔑 STABILITY KEY EKHANE BOSA
  final String stabilityApiKey = "sk-REPLACE_WITH_YOUR_KEY";
  final List<String> _styles = ["Tribal", "Minimalist", "Realistic", "Japanese", "Blackwork", "Watercolor"];

  // REAL PAYMENT
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
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
    setState(() => isProUser = prefs.getBool('isPro') ?? false);
  }

  Future<void> _setProStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPro', value);
    setState(() => isProUser = value);
  }

  Future<void> _initStore() async {
    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) return;
    _subscription = _inAppPurchase.purchaseStream.listen((purchases) {
      _listenToPurchaseUpdated(purchases);
    }, onDone: () => _subscription.cancel(), onError: (e) => print(e));
    const Set<String> _kIds = {"inkai_pro_monthly"};
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_kIds);
    if (response.error == null) {
      setState(() => _products = response.productDetails);
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> list) {
    for (var purchase in list) {
      if (purchase.status == PurchaseStatus.pending) {
        setState(() => _purchasePending = true);
      } else {
        if (purchase.status == PurchaseStatus.error) {
          setState(() => _purchasePending = false);
        } else if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
          _setProStatus(true);
          setState(() => _purchasePending = false);
        }
        if (purchase.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _buyPro() async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product not found. Upload AAB to Play Console first!")));
      return;
    }
    final product = _products.firstWhere((p) => p.id == _kProId, orElse: () => _products.first);
    final param = PurchaseParam(productDetails: product);
    await _inAppPurchase.buyNonConsumable(purchaseParam: param);
  }

  Future<void> _restore() async {
    await _inAppPurchase.restorePurchases();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _promptController.dispose();
    super.dispose();
  }

  void _generateFree() async {
    setState(() => _isGenerating = true);
    final prompt = "${_promptController.text}, ${_selectedStyle} tattoo style, high detail";
    final url = "https://image.pollinations.ai/prompt/${Uri.encodeComponent(prompt)}?seed=${Random().nextInt(999999)}&width=1024&height=1024&nologo=true";
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _freeImageUrl = url;
      _proImage = null;
      _isGenerating = false;
    });
  }

  Future<void> _generatePro() async {
    if (stabilityApiKey.contains("REPLACE")) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("API Key bosao!"), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final res = await http.post(
        Uri.parse("https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $stabilityApiKey"},
        body: jsonEncode({
          "text_prompts": [{"text": "${_promptController.text}, ${_selectedStyle} tattoo, professional stencil", "weight": 1}],
          "cfg_scale": 7, "height": 1024, "width": 1024, "samples": 1, "steps": 30, "style_preset": "line-art"
        }),
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

  void _onGeneratePressed() {
    if (isProUser) _generatePro(); else _generateFree();
  }

  void _showPaywall() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.workspace_premium, size: 60, color: Color(0xFF00FF88)),
          const Text("Unlock PRO", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (_purchasePending) const CircularProgressIndicator(color: Color(0xFF00FF88)) else SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF88), foregroundColor: Colors.black),
              onPressed: _buyPro,
              child: Text(_products.isNotEmpty ? "Buy PRO - ${_products.first.price}" : "Buy PRO - \$2.99"),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: _restore, child: const Text("Restore Purchase")),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: Row(children: [
          Icon(isProUser ? Icons.verified : Icons.brush, color: const Color(0xFF00FF88)),
          const SizedBox(width: 8),
          Text(isProUser ? "InkAI PRO" : "InkAI Free"),
          const Spacer(),
          GestureDetector(onTap: _showPaywall, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: isProUser ? const Color(0xFF00FF88) : Colors.white24, borderRadius: BorderRadius.circular(20)), child: Text(isProUser ? "PRO ✓" : "Go PRO", style: TextStyle(color: isProUser ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _promptController, style: const TextStyle(color: Colors.white), maxLines: 3, decoration: InputDecoration(labelText: "Tattoo Idea", filled: true, fillColor: const Color(0xFF1E1E1E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: _styles.map((s) => ChoiceChip(label: Text(s), selected: _selectedStyle == s, selectedColor: const Color(0xFF00FF88), onSelected: (_) => setState(() => _selectedStyle = s))).toList()),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isGenerating ? null : _onGeneratePressed, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF88), foregroundColor: Colors.black), child: _isGenerating ? const CircularProgressIndicator() : Text(isProUser ? "Generate PRO" : "Generate Free"))),
          const SizedBox(height: 20),
          if (_proImage != null) ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(_proImage!, height: 400)) else if (_freeImageUrl != null) ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(_freeImageUrl!, height: 400)) else Container(height: 200, decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)), child: const Center(child: Text("Design here"))),
        ]),
      ),
    );
  }
}
