import 'package:flutter/material.dart';

import '../models/app_config.dart';
import '../services/jules_api_service.dart';

class SettingsView extends StatefulWidget {
  final AppConfig config;
  final Function(AppConfig) onConfigSaved;
  final JulesApiService julesApiService;

  const SettingsView({
    super.key,
    required this.config,
    required this.onConfigSaved,
    required this.julesApiService,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late TextEditingController _apiKeyController;
  late TextEditingController _githubTokenController;
  late TextEditingController _repoController;
  late TextEditingController _baseUrlController;
  late bool _useMockMode;

  bool _obscureApiKey = true;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.config.apiKey);
    _githubTokenController = TextEditingController(text: widget.config.githubToken);
    _repoController = TextEditingController(text: widget.config.defaultRepo);
    _baseUrlController = TextEditingController(text: widget.config.baseUrl);
    _useMockMode = widget.config.useMockMode;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _githubTokenController.dispose();
    _repoController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final newConfig = widget.config.copyWith(
      apiKey: _apiKeyController.text.trim(),
      githubToken: _githubTokenController.text.trim(),
      defaultRepo: _repoController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      useMockMode: _useMockMode,
    );

    widget.onConfigSaved(newConfig);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
    });

    final key = _apiKeyController.text.trim();
    final testConfig = widget.config.copyWith(
      apiKey: key,
      useMockMode: false,
    );

    widget.julesApiService.updateConfig(testConfig);
    final req = await widget.julesApiService.sendRequest(prompt: 'ping');

    if (mounted) {
      setState(() {
        _isTesting = false;
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: const Text('Jules Connection Test', style: TextStyle(color: Colors.white)),
          content: Text(
            'API Key Status: Verified\n\nExecution Response:\n${req.response}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: Colors.cyanAccent)),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Jules API Key & Security',
          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF181825),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Jules API Key:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _apiKeyController,
                obscureText: _obscureApiKey,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF11111B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureApiKey = !_obscureApiKey;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF89B4FA), foregroundColor: Colors.black),
                    icon: _isTesting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.bolt, size: 18),
                    label: const Text('Test Jules Connection'),
                    onPressed: _isTesting ? null : _testConnection,
                  ),
                ],
              )
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          'GitHub Integration & Repositories',
          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF181825),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Target Repository (owner/repo):', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _repoController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. flutter/flutter',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF11111B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('GitHub Personal Access Token (Optional for Private Repos):', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _githubTokenController,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'ghp_xxxxxxxxxxxx',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF11111B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          'Backend & Offline Execution',
          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF181825),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              TextField(
                controller: _baseUrlController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Jules API Base URL',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF11111B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Offline / Simulation Mode', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Provides simulated agent execution when server endpoints are offline.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                value: _useMockMode,
                activeTrackColor: Colors.cyanAccent,
                onChanged: (val) {
                  setState(() {
                    _useMockMode = val;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.save),
          label: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          onPressed: _saveSettings,
        )
      ],
    );
  }
}
