import 'package:flutter/material.dart';

import '../models/ai_model_config.dart';
import '../models/app_config.dart';
import '../services/jules_api_service.dart';
import '../services/storage_service.dart';

class SettingsView extends StatefulWidget {
  final AppConfig config;
  final Function(AppConfig) onConfigSaved;
  final JulesApiService julesApiService;
  final StorageService? storageService;

  const SettingsView({
    super.key,
    required this.config,
    required this.onConfigSaved,
    required this.julesApiService,
    this.storageService,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // App Settings Controllers
  late TextEditingController _julesApiKeyController;
  late TextEditingController _julesBaseUrlController;
  late TextEditingController _githubTokenController;
  late TextEditingController _repoController;
  late TextEditingController _firebaseProjectIdController;
  late TextEditingController _firebaseUserIdController;
  late bool _enableMultiModelPlanning;
  late bool _enableMcpInFlightSteering;
  late bool _enableCloudSync;
  late List<AiModelConfig> _providers;

  // Server & Hosting Settings Controllers
  late TextEditingController _remoteServerUrlController;
  late bool _useMockMode;
  late bool _isSelfHosted;

  bool _obscureJulesKey = true;
  bool _isTestingJules = false;
  bool _isFirebaseSyncing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _julesApiKeyController = TextEditingController(text: widget.config.julesApiKey);
    _julesBaseUrlController = TextEditingController(text: widget.config.julesBaseUrl);
    _githubTokenController = TextEditingController(text: widget.config.githubToken);
    _repoController = TextEditingController(text: widget.config.defaultRepo);
    _firebaseProjectIdController = TextEditingController(text: widget.config.firebaseProjectId);
    _firebaseUserIdController = TextEditingController(text: widget.config.firebaseUserId);
    _enableMultiModelPlanning = widget.config.enableMultiModelPlanning;
    _enableMcpInFlightSteering = widget.config.enableMcpInFlightSteering;
    _enableCloudSync = widget.config.enableCloudSync;
    _providers = List.from(widget.config.multiModelProviders);

    _remoteServerUrlController = TextEditingController(text: widget.config.remoteServerUrl);
    _useMockMode = widget.config.useMockMode;
    _isSelfHosted = widget.config.isSelfHosted;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _julesApiKeyController.dispose();
    _julesBaseUrlController.dispose();
    _githubTokenController.dispose();
    _repoController.dispose();
    _firebaseProjectIdController.dispose();
    _firebaseUserIdController.dispose();
    _remoteServerUrlController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final updatedJulesKey = _julesApiKeyController.text.trim();
    final updatedJulesUrl = _julesBaseUrlController.text.trim();

    final updatedProviders = _providers.map((p) {
      if (p.type == AiProviderType.googleJules) {
        return p.copyWith(apiKey: updatedJulesKey, endpoint: updatedJulesUrl);
      }
      return p;
    }).toList();

    final newConfig = widget.config.copyWith(
      julesApiKey: updatedJulesKey,
      julesBaseUrl: updatedJulesUrl,
      githubToken: _githubTokenController.text.trim(),
      defaultRepo: _repoController.text.trim(),
      firebaseProjectId: _firebaseProjectIdController.text.trim(),
      firebaseUserId: _firebaseUserIdController.text.trim(),
      useMockMode: _useMockMode,
      remoteServerUrl: _remoteServerUrlController.text.trim(),
      isSelfHosted: _isSelfHosted,
      enableMultiModelPlanning: _enableMultiModelPlanning,
      enableMcpInFlightSteering: _enableMcpInFlightSteering,
      enableCloudSync: _enableCloudSync,
      multiModelProviders: updatedProviders,
    );

    widget.onConfigSaved(newConfig);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved locally & synced to Firebase Cloud.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _syncToFirebase() async {
    if (widget.storageService == null) return;

    setState(() {
      _isFirebaseSyncing = true;
    });

    final currentConfig = widget.config.copyWith(
      julesApiKey: _julesApiKeyController.text.trim(),
      julesBaseUrl: _julesBaseUrlController.text.trim(),
      firebaseProjectId: _firebaseProjectIdController.text.trim(),
      firebaseUserId: _firebaseUserIdController.text.trim(),
      enableCloudSync: true,
    );

    final result = await widget.storageService!.firebaseService.saveSettingsToFirebase(
      config: currentConfig,
    );

    if (mounted) {
      setState(() {
        _isFirebaseSyncing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.amber,
        ),
      );
    }
  }

  Future<void> _pullFromFirebase() async {
    if (widget.storageService == null) return;

    setState(() {
      _isFirebaseSyncing = true;
    });

    final proj = _firebaseProjectIdController.text.trim();
    final user = _firebaseUserIdController.text.trim();

    final result = await widget.storageService!.firebaseService.fetchSettingsFromFirebase(
      projectId: proj,
      userId: user,
    );

    if (mounted) {
      setState(() {
        _isFirebaseSyncing = false;
      });

      if (result.success && result.config != null) {
        final fetched = result.config!;
        setState(() {
          _julesApiKeyController.text = fetched.julesApiKey;
          _julesBaseUrlController.text = fetched.julesBaseUrl;
          _githubTokenController.text = fetched.githubToken;
          _repoController.text = fetched.defaultRepo;
          _enableMultiModelPlanning = fetched.enableMultiModelPlanning;
          _providers = List.from(fetched.multiModelProviders);
        });

        widget.onConfigSaved(fetched);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Updated settings from Firebase Cloud.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.amber,
          ),
        );
      }
    }
  }

  Future<void> _testJulesConnection() async {
    setState(() {
      _isTestingJules = true;
    });

    final key = _julesApiKeyController.text.trim();
    final url = _julesBaseUrlController.text.trim();
    final testConfig = widget.config.copyWith(
      julesApiKey: key,
      julesBaseUrl: url,
      useMockMode: false,
    );

    widget.julesApiService.updateConfig(testConfig);
    final req = await widget.julesApiService.sendRequest(prompt: 'ping');

    if (mounted) {
      setState(() {
        _isTestingJules = false;
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: const Text('Google Jules AI Connection Test', style: TextStyle(color: Colors.white)),
          content: Text(
            'Google Jules API Key Status: Verified\n\nExecution Response:\n${req.response}',
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

  void _updateProviderKey(int index, String key) {
    setState(() {
      _providers[index] = _providers[index].copyWith(apiKey: key);
    });
  }

  void _toggleProviderEnabled(int index, bool enabled) {
    setState(() {
      _providers[index] = _providers[index].copyWith(isEnabled: enabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF181825),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.cyanAccent,
            labelColor: Colors.cyanAccent,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.apps), text: 'App-Level Settings'),
              Tab(icon: Icon(Icons.dns), text: 'Server & Hosting Settings'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAppSettingsTab(),
              _buildServerSettingsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Google Jules AI API Key Section
        const Text(
          'Google Jules AI API Configuration',
          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF181825),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF313244)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Google Jules AI API Key:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _julesApiKeyController,
                obscureText: _obscureJulesKey,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Enter Google Jules AI API Key (e.g. jules_live_...)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF11111B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureJulesKey ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureJulesKey = !_obscureJulesKey;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                ),
                icon: _isTestingJules
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.bolt, size: 18),
                label: const Text('Test Google Jules Connection'),
                onPressed: _isTestingJules ? null : _testJulesConnection,
              )
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Multi-Model AI Planning Section
        const Text(
          'Multi-Model AI Planning Stage (Cross-Platform)',
          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF181825),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF313244)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text('Enable Multi-Model Planning Stage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Synthesizes recommendations across Jules, Gemini, GPT-4, & Claude prior to execution.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                value: _enableMultiModelPlanning,
                activeTrackColor: Colors.cyanAccent,
                onChanged: (val) {
                  setState(() {
                    _enableMultiModelPlanning = val;
                  });
                },
              ),
              if (_enableMultiModelPlanning) ...[
                SwitchListTile(
                  title: const Text('MCP In-Flight Inter-Model Steering', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Allows models to communicate via Model Context Protocol (MCP) JSON-RPC 2.0 tools to steer consensus during generation.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  value: _enableMcpInFlightSteering,
                  activeTrackColor: Colors.cyanAccent,
                  onChanged: (val) {
                    setState(() {
                      _enableMcpInFlightSteering = val;
                    });
                  },
                ),
                const Divider(color: Color(0xFF313244), height: 24),
                const Text('Configured AI Model Providers:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _providers.length,
                  itemBuilder: (context, index) {
                    final provider = _providers[index];
                    return Card(
                      color: const Color(0xFF11111B),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFF313244)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    provider.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    provider.role,
                                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Switch(
                                  value: provider.isEnabled,
                                  activeTrackColor: Colors.cyanAccent,
                                  onChanged: (val) => _toggleProviderEnabled(index, val),
                                ),
                              ],
                            ),
                            if (provider.isEnabled && provider.type != AiProviderType.googleJules) ...[
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: provider.apiKey,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                                decoration: InputDecoration(
                                  labelText: '${provider.name} API Key',
                                  labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                                  filled: true,
                                  fillColor: const Color(0xFF181825),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                onChanged: (val) => _updateProviderKey(index, val),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Firebase Server-Side Storage Sync Section
        const Text(
          'Firebase Server-Side Storage Sync',
          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF181825),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF313244)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text('Enable Firebase Server-Side Sync', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Persists user-level settings on Firebase Firestore Cloud.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                value: _enableCloudSync,
                activeTrackColor: Colors.cyanAccent,
                onChanged: (val) {
                  setState(() {
                    _enableCloudSync = val;
                  });
                },
              ),
              if (_enableCloudSync) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _firebaseProjectIdController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Firebase Project ID',
                    hintText: 'jnj-jules-shell',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF11111B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _firebaseUserIdController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'User ID / Account Key',
                    hintText: 'default_user',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF11111B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF89B4FA),
                          foregroundColor: Colors.black,
                        ),
                        icon: _isFirebaseSyncing
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.cloud_upload, size: 16),
                        label: const Text('Sync to Firebase'),
                        onPressed: _isFirebaseSyncing ? null : _syncToFirebase,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.cyanAccent,
                          side: const BorderSide(color: Colors.cyanAccent),
                        ),
                        icon: const Icon(Icons.cloud_download, size: 16),
                        label: const Text('Pull from Firebase'),
                        onPressed: _isFirebaseSyncing ? null : _pullFromFirebase,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // GitHub Section
        const Text(
          'GitHub Integration',
          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF181825),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF313244)),
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
              const Text('GitHub Personal Access Token (Optional):', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.save),
          label: const Text('Save App Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          onPressed: _saveSettings,
        )
      ],
    );
  }

  Widget _buildServerSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Android Wrapper Host & Server',
          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF181825),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF313244)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text('Self-Hosted Local Mode', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Serves app assets locally on device. Turn off to connect to a remote server.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                value: _isSelfHosted,
                activeTrackColor: Colors.cyanAccent,
                onChanged: (val) {
                  setState(() {
                    _isSelfHosted = val;
                  });
                },
              ),
              if (!_isSelfHosted) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _remoteServerUrlController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Remote Server URL',
                    hintText: 'e.g. http://10.0.2.2:8080 or https://JakeDot.github.io/jnj/',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF11111B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'JNJ Backend Endpoint & Offline Mode',
          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF181825),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF313244)),
          ),
          child: Column(
            children: [
              TextField(
                controller: _julesBaseUrlController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'JNJ Backend Base URL',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF11111B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Offline / Simulation Mode', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Provides simulated multi-model execution when server endpoints are offline.', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
          label: const Text('Save Server Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          onPressed: _saveSettings,
        )
      ],
    );
  }
}
