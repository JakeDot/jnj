import 'package:flutter/material.dart';

import '../models/app_config.dart';
import '../services/github_service.dart';
import '../services/jules_api_service.dart';
import '../services/shell_engine.dart';
import '../services/storage_service.dart';
import 'dashboard_view.dart';
import 'github_linkage_view.dart';
import 'settings_view.dart';
import 'terminal_view.dart';

class MainScreen extends StatefulWidget {
  final StorageService storageService;

  const MainScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late AppConfig _config;
  late JulesApiService _julesApiService;
  late GitHubService _gitHubService;
  late ShellEngine _shellEngine;

  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _config = widget.storageService.loadConfig();

    _julesApiService = JulesApiService(config: _config);
    _gitHubService = GitHubService(config: _config);

    _shellEngine = ShellEngine(
      julesApiService: _julesApiService,
      gitHubService: _gitHubService,
      onConfigUpdated: _onConfigUpdated,
    );

    final savedRequests = widget.storageService.loadRequests();
    if (savedRequests.isNotEmpty) {
      _shellEngine.setRequests(savedRequests);
    }
  }

  void _onConfigUpdated(AppConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    widget.storageService.saveConfig(newConfig);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final pages = [
      TerminalView(shellEngine: _shellEngine),
      DashboardView(shellEngine: _shellEngine),
      GitHubLinkageView(
        gitHubService: _gitHubService,
        shellEngine: _shellEngine,
        onStartSession: () {
          setState(() {
            _selectedTabIndex = 0;
          });
        },
      ),
      SettingsView(
        config: _config,
        onConfigSaved: _onConfigUpdated,
        julesApiService: _julesApiService,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181825),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.terminal, color: Colors.cyanAccent),
            const SizedBox(width: 10),
            const Text(
              'Jules Shell',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Windows & Android',
                style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined, color: Colors.white70),
            tooltip: 'Save Request History',
            onPressed: () async {
              await widget.storageService.saveRequests(_shellEngine.requestHistory);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request history saved locally.'), backgroundColor: Colors.green),
                );
              }
            },
          ),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedTabIndex,
                  backgroundColor: const Color(0xFF181825),
                  selectedIconTheme: const IconThemeData(color: Colors.cyanAccent),
                  unselectedIconTheme: const IconThemeData(color: Colors.white54),
                  selectedLabelTextStyle: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                  unselectedLabelTextStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.terminal),
                      label: Text('Terminal'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_customize),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.share_outlined),
                      label: Text('GitHub Link'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1, color: Colors.white12),
                Expanded(child: IndexedStack(index: _selectedTabIndex, children: pages)),
              ],
            )
          : IndexedStack(index: _selectedTabIndex, children: pages),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedTabIndex,
              backgroundColor: const Color(0xFF181825),
              selectedItemColor: Colors.cyanAccent,
              unselectedItemColor: Colors.white54,
              type: BottomNavigationBarType.fixed,
              onTap: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.terminal),
                  label: 'Terminal',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_customize),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.share_outlined),
                  label: 'GitHub',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
    );
  }
}
