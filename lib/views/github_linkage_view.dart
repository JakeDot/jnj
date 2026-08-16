import 'package:flutter/material.dart';

import '../models/github_item.dart';
import '../services/github_service.dart';
import '../services/shell_engine.dart';

class GitHubLinkageView extends StatefulWidget {
  final GitHubService gitHubService;
  final ShellEngine shellEngine;
  final VoidCallback onStartSession;

  const GitHubLinkageView({
    super.key,
    required this.gitHubService,
    required this.shellEngine,
    required this.onStartSession,
  });

  @override
  State<GitHubLinkageView> createState() => _GitHubLinkageViewState();
}

class _GitHubLinkageViewState extends State<GitHubLinkageView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlInputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<GitHubItem> _pullRequests = [];
  List<GitHubItem> _issues = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGitHubData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlInputController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGitHubData() async {
    setState(() {
      _isLoading = true;
    });

    final prs = await widget.gitHubService.fetchPullRequests();
    final issues = await widget.gitHubService.fetchIssues();

    if (mounted) {
      setState(() {
        _pullRequests = prs;
        _issues = issues;
        _isLoading = false;
      });
    }
  }

  void _linkUrlOrRef() {
    final text = _urlInputController.text.trim();
    if (text.isEmpty) return;

    final item = widget.gitHubService.parseGitHubUrl(text);
    if (item != null) {
      _startSessionWithItem(item);
      _urlInputController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not parse GitHub link or reference. Use format owner/repo#123 or full GitHub URL.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _startSessionWithItem(GitHubItem item) {
    widget.shellEngine.setActiveGitHubContext(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚡ Active Jules session started with context: ${item.shortRef}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    widget.onStartSession();
  }

  @override
  Widget build(BuildContext context) {
    final activeContext = widget.shellEngine.activeGitHubContext;

    return Column(
      children: [
        if (activeContext != null)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.cyan.shade900,
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.cyanAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Active Session Context: ${activeContext.shortRef} - "${activeContext.title}"',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.terminal, size: 16),
                  label: const Text('Go to Shell'),
                  onPressed: widget.onStartSession,
                )
              ],
            ),
          ),

        Container(
          color: const Color(0xFF1E1E2E),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste GitHub URL or Shorthand Ref (#123 or owner/repo#123):',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlInputController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'https://github.com/${widget.gitHubService.config.defaultRepo}/pull/101',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF181825),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _linkUrlOrRef(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF89B4FA),
                      foregroundColor: const Color(0xFF11111B),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.add_link, size: 18),
                    label: const Text('Start Session'),
                    onPressed: _linkUrlOrRef,
                  )
                ],
              ),
            ],
          ),
        ),

        Container(
          color: const Color(0xFF181825),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.cyanAccent,
                  labelColor: Colors.cyanAccent,
                  unselectedLabelColor: Colors.white60,
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.merge_type, size: 18),
                      text: 'Pull Requests (${_pullRequests.length})',
                    ),
                    Tab(
                      icon: const Icon(Icons.bug_report, size: 18),
                      text: 'Issues (${_issues.length})',
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                tooltip: 'Refresh GitHub Items',
                onPressed: _loadGitHubData,
              )
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search PRs and Issues by title, number, or author...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
              filled: true,
              fillColor: const Color(0xFF181825),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.toLowerCase();
              });
            },
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildItemsList(_pullRequests),
                    _buildItemsList(_issues),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildItemsList(List<GitHubItem> items) {
    final filtered = items.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.title.toLowerCase().contains(_searchQuery) ||
          item.number.toString().contains(_searchQuery) ||
          item.author.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('No matching items found.', style: TextStyle(color: Colors.white54, fontSize: 14)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final isSelected = widget.shellEngine.activeGitHubContext?.id == item.id;

        return Card(
          color: isSelected ? const Color(0xFF313244) : const Color(0xFF181825),
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isSelected ? const BorderSide(color: Colors.cyanAccent, width: 1.5) : BorderSide.none,
          ),
          child: ListTile(
            leading: Icon(
              item.isPR ? Icons.merge_type : Icons.bug_report,
              color: item.state == 'open' ? Colors.greenAccent : (item.state == 'merged' ? Colors.purpleAccent : Colors.redAccent),
            ),
            title: Text(
              '#${item.number}: ${item.title}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              'State: ${item.state.toUpperCase()} • Author: @${item.author} • ${item.shortRef}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.greenAccent : const Color(0xFF89B4FA),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: Icon(isSelected ? Icons.check : Icons.play_arrow_rounded, size: 16),
              label: Text(isSelected ? 'Selected' : 'Start Session'),
              onPressed: () => _startSessionWithItem(item),
            ),
          ),
        );
      },
    );
  }
}
