// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _chatGptApiKey;
  String? _googleMapsApiKey;

  final TextEditingController _chatGptApiKeyController = TextEditingController();
  final TextEditingController _googleMapsApiKeyController = TextEditingController();
  
  bool _isChatGptApiKeyObscured = true;
  bool _isGoogleMapsApiKeyObscured = true;

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load settings when the screen initializes
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _chatGptApiKey = prefs.getString('chatGptApiKey');
      _googleMapsApiKey = prefs.getString('googleMapsApiKey');
    });
    _chatGptApiKeyController.text = _chatGptApiKey ?? '';
    _googleMapsApiKeyController.text = _googleMapsApiKey ?? '';

    // Debug logs to verify loaded API keys
    print('Loaded ChatGPT API Key: $_chatGptApiKey');
    print('Loaded Google Maps API Key: $_googleMapsApiKey');
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chatGptApiKey', _chatGptApiKeyController.text);
    await prefs.setString('googleMapsApiKey', _googleMapsApiKeyController.text);

    // Debug logs to verify saved API keys
    print('Saved ChatGPT API Key: ${_chatGptApiKeyController.text}');
    print('Saved Google Maps API Key: ${_googleMapsApiKeyController.text}');
  }

  void _toggleChatGptApiKeyVisibility() {
    setState(() {
      _isChatGptApiKeyObscured = !_isChatGptApiKeyObscured;
    });
  }

  void _toggleGoogleMapsApiKeyVisibility() {
    setState(() {
      _isGoogleMapsApiKeyObscured = !_isGoogleMapsApiKeyObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ChatGPT API KEY:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _chatGptApiKeyController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'ChatGPT API KEYを入力',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isChatGptApiKeyObscured ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: _toggleChatGptApiKeyVisibility,
                ),
              ),
              obscureText: _isChatGptApiKeyObscured,
            ),
            const SizedBox(height: 16),
            const Text(
              'Google Maps API KEY:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _googleMapsApiKeyController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Google Maps API KEYを入力',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isGoogleMapsApiKeyObscured ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: _toggleGoogleMapsApiKeyVisibility,
                ),
              ),
              obscureText: _isGoogleMapsApiKeyObscured,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await _saveSettings();
                // Confirm the save operation with a message
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('設定が保存されました')),
                );
              },
              child: const Text('設定を保存'),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: true, // Adjust layout when keyboard appears
    );
  }
}
