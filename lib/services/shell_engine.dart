import 'dart:collection';

import '../models/app_config.dart';
import '../models/github_item.dart';
import '../models/jules_request.dart';
import '../models/shell_command.dart';
import 'github_service.dart';
import 'jules_api_service.dart';

class ShellEngine {
  final JulesApiService julesApiService;
  final GitHubService gitHubService;
  final Function(AppConfig)? onConfigUpdated;

  final List<ShellOutput> _outputs = [];
  final List<String> _commandHistory = [];
  final List<JulesRequest> _requestHistory = [];

  // Performance Optimization: Cache UnmodifiableListView wrappers to avoid O(N) list
  // copying on every getter invocation (preventing O(N^2) overhead during UI list rendering).
  late final UnmodifiableListView<ShellOutput> _unmodifiableOutputs = UnmodifiableListView(_outputs);
  late final UnmodifiableListView<String> _unmodifiableCommandHistory = UnmodifiableListView(_commandHistory);
  late final UnmodifiableListView<JulesRequest> _unmodifiableRequestHistory = UnmodifiableListView(_requestHistory);

  GitHubItem? _activeGitHubContext;

  ShellEngine({
    required this.julesApiService,
    required this.gitHubService,
    this.onConfigUpdated,
  }) {
    _addOutput(ShellOutput(
      content: '⚡ Welcome to Jules Shell Terminal v1.0.0\n'
          'Type "help" or "jules help" to see available shell commands.\n'
          'API Key: Configured | Target Repo: ${julesApiService.config.defaultRepo}',
      type: ShellOutputType.info,
    ));
  }

  List<ShellOutput> get outputs => _unmodifiableOutputs;
  List<String> get commandHistory => _unmodifiableCommandHistory;
  List<JulesRequest> get requestHistory => _unmodifiableRequestHistory;
  GitHubItem? get activeGitHubContext => _activeGitHubContext;

  void setRequests(List<JulesRequest> requests) {
    _requestHistory.clear();
    _requestHistory.addAll(requests);
  }

  void setActiveGitHubContext(GitHubItem? item) {
    _activeGitHubContext = item;
    if (item != null) {
      _addOutput(ShellOutput(
        content: '📌 Selected GitHub Context: ${item.shortRef} - "${item.title}"',
        type: ShellOutputType.info,
        githubItem: item,
      ));
    }
  }

  void clearOutputs() {
    _outputs.clear();
  }

  void _addOutput(ShellOutput output) {
    _outputs.add(output);
  }

  Future<ShellOutput> executeInput(String rawInput) async {
    final input = rawInput.trim();
    if (input.isEmpty) {
      return ShellOutput(content: '', type: ShellOutputType.text);
    }

    _commandHistory.add(input);
    _addOutput(ShellOutput(content: '\$ $input', type: ShellOutputType.text));

    final parsed = ParsedCommand.parse(input);

    switch (parsed.command) {
      case 'help':
      case 'h':
      case '?':
        return _handleHelp();

      case 'send':
      case 'prompt':
      case 'exec':
      case 'run':
        return await _handleSend(parsed);

      case 'gh':
      case 'github':
        return await _handleGitHub(parsed);

      case 'config':
      case 'set':
        return _handleConfig(parsed);

      case 'history':
      case 'list':
      case 'requests':
        return _handleHistory();

      case 'clear':
      case 'cls':
        clearOutputs();
        return ShellOutput(content: 'Terminal cleared.', type: ShellOutputType.info);

      default:
        // Treat plain text inputs as a direct Jules prompt request
        return await _executeJulesPrompt(input, parsed.options);
    }
  }

  ShellOutput _handleHelp() {
    const helpMessage = '''
💡 **Jules Shell Commands Reference:**

  **Jules API Requests:**
    send <prompt>               Send a request prompt to Jules
    <plain text prompt>         Directly sends prompt to Jules

  **GitHub Linkage & Sessions:**
    gh pr list [repo]           List pull requests for repository
    gh issue list [repo]        List issues for repository
    gh link <url_or_ref>        Parse GitHub URL/ref (#123) and start session
    gh context [clear]          View or clear currently active GitHub context

  **Configuration:**
    config view                 Display current Jules API Key and Settings
    config set-key <api_key>    Update Jules API Key
    config set-repo <owner/repo> Set target GitHub repository

  **Terminal Utility:**
    history                     Display list of past Jules requests
    clear                       Clear terminal output screen
    help                        Show this command reference
''';
    final out = ShellOutput(content: helpMessage, type: ShellOutputType.info);
    _addOutput(out);
    return out;
  }

  Future<ShellOutput> _handleSend(ParsedCommand parsed) async {
    final prompt = parsed.args.join(' ');
    if (prompt.isEmpty) {
      final out = ShellOutput(
        content: 'Error: Please specify a prompt. Example: send "Fix error handling"',
        type: ShellOutputType.error,
      );
      _addOutput(out);
      return out;
    }
    return await _executeJulesPrompt(prompt, parsed.options);
  }

  Future<ShellOutput> _executeJulesPrompt(String prompt, Map<String, String> options) async {
    _addOutput(ShellOutput(content: '⏳ Sending request to Jules API...', type: ShellOutputType.info));

    final linkedItems = <GitHubItem>[];
    if (_activeGitHubContext != null) {
      linkedItems.add(_activeGitHubContext!);
    }

    // Check if prompt contains GitHub URL or shorthand
    final parsedItem = gitHubService.parseGitHubUrl(prompt);
    if (parsedItem != null && !linkedItems.any((e) => e.number == parsedItem.number)) {
      linkedItems.add(parsedItem);
    }

    final request = await julesApiService.sendRequest(
      prompt: prompt,
      linkedItems: linkedItems,
    );

    _requestHistory.insert(0, request);

    final out = ShellOutput(
      content: '✅ Jules Execution Complete:\n\n${request.response}',
      type: ShellOutputType.success,
      request: request,
    );
    _addOutput(out);
    return out;
  }

  Future<ShellOutput> _handleGitHub(ParsedCommand parsed) async {
    if (parsed.args.isEmpty) {
      return _addAndReturn(ShellOutput(
        content: 'Usage: gh <pr|issue|link|context> [subcommand]',
        type: ShellOutputType.error,
      ));
    }

    final sub = parsed.args[0].toLowerCase();

    if (sub == 'pr' || sub == 'prs' || sub == 'pulls') {
      final list = await gitHubService.fetchPullRequests();
      final sb = StringBuffer('📂 Pull Requests (${gitHubService.config.defaultRepo}):\n\n');
      for (var pr in list) {
        sb.writeln('  [PR #${pr.number}] ${pr.title} (${pr.state})');
        sb.writeln('    URL: ${pr.url}');
      }
      return _addAndReturn(ShellOutput(content: sb.toString(), type: ShellOutputType.info));
    }

    if (sub == 'issue' || sub == 'issues') {
      final list = await gitHubService.fetchIssues();
      final sb = StringBuffer('🐛 Issues (${gitHubService.config.defaultRepo}):\n\n');
      for (var issue in list) {
        sb.writeln('  [Issue #${issue.number}] ${issue.title} (${issue.state})');
        sb.writeln('    URL: ${issue.url}');
      }
      return _addAndReturn(ShellOutput(content: sb.toString(), type: ShellOutputType.info));
    }

    if (sub == 'link' || sub == 'select') {
      if (parsed.args.length < 2) {
        return _addAndReturn(ShellOutput(
          content: 'Usage: gh link <github_url_or_ref> (e.g. gh link #201 or https://github.com/owner/repo/issues/201)',
          type: ShellOutputType.error,
        ));
      }
      final target = parsed.args.sublist(1).join(' ');
      final item = gitHubService.parseGitHubUrl(target);
      if (item != null) {
        setActiveGitHubContext(item);
        return ShellOutput(
          content: 'Linked GitHub context ${item.shortRef} to active Jules session.',
          type: ShellOutputType.success,
          githubItem: item,
        );
      } else {
        return _addAndReturn(ShellOutput(
          content: 'Could not parse GitHub reference. Format as owner/repo#123 or paste GitHub URL.',
          type: ShellOutputType.error,
        ));
      }
    }

    if (sub == 'context') {
      if (parsed.args.length > 1 && parsed.args[1] == 'clear') {
        _activeGitHubContext = null;
        return _addAndReturn(ShellOutput(content: 'Cleared active GitHub context.', type: ShellOutputType.info));
      }
      if (_activeGitHubContext == null) {
        return _addAndReturn(ShellOutput(content: 'No active GitHub context set.', type: ShellOutputType.info));
      }
      return _addAndReturn(ShellOutput(
        content: 'Active GitHub context: ${_activeGitHubContext!.shortRef} - "${_activeGitHubContext!.title}"',
        type: ShellOutputType.info,
        githubItem: _activeGitHubContext,
      ));
    }

    return _addAndReturn(ShellOutput(content: 'Unknown GitHub command: gh $sub', type: ShellOutputType.error));
  }

  ShellOutput _handleConfig(ParsedCommand parsed) {
    final cfg = julesApiService.config;

    if (parsed.args.isEmpty || parsed.args.first == 'view') {
      final maskedKey = cfg.apiKey.length > 8
          ? '${cfg.apiKey.substring(0, 4)}...${cfg.apiKey.substring(cfg.apiKey.length - 4)}'
          : cfg.apiKey;
      final info = '⚙️ Current Jules Shell Configuration:\n'
          '  API Key: $maskedKey\n'
          '  Target Repository: ${cfg.defaultRepo}\n'
          '  Base URL: ${cfg.baseUrl}\n'
          '  Mock Mode: ${cfg.useMockMode}';
      return _addAndReturn(ShellOutput(content: info, type: ShellOutputType.info));
    }

    final sub = parsed.args[0].toLowerCase();
    if (sub == 'set-key' && parsed.args.length > 1) {
      final newKey = parsed.args[1];
      final newCfg = cfg.copyWith(apiKey: newKey);
      julesApiService.updateConfig(newCfg);
      gitHubService.updateConfig(newCfg);
      onConfigUpdated?.call(newCfg);
      return _addAndReturn(ShellOutput(content: 'Updated Jules API key.', type: ShellOutputType.success));
    }

    if (sub == 'set-repo' && parsed.args.length > 1) {
      final newRepo = parsed.args[1];
      final newCfg = cfg.copyWith(defaultRepo: newRepo);
      julesApiService.updateConfig(newCfg);
      gitHubService.updateConfig(newCfg);
      onConfigUpdated?.call(newCfg);
      return _addAndReturn(ShellOutput(content: 'Updated target repository to $newRepo.', type: ShellOutputType.success));
    }

    return _addAndReturn(ShellOutput(content: 'Unknown config option.', type: ShellOutputType.error));
  }

  ShellOutput _handleHistory() {
    if (_requestHistory.isEmpty) {
      return _addAndReturn(ShellOutput(content: 'No Jules requests in history.', type: ShellOutputType.info));
    }

    final sb = StringBuffer('📜 Jules Requests History (${_requestHistory.length}):\n\n');
    for (int i = 0; i < _requestHistory.length; i++) {
      final req = _requestHistory[i];
      sb.writeln('  [${i + 1}] ID: ${req.id} | Status: ${req.status.name.toUpperCase()}');
      sb.writeln('      Prompt: "${req.prompt}"');
      if (req.linkedGitHubItems.isNotEmpty) {
        sb.writeln('      Linked: ${req.linkedGitHubItems.map((e) => e.shortRef).join(', ')}');
      }
    }
    return _addAndReturn(ShellOutput(content: sb.toString(), type: ShellOutputType.info));
  }

  ShellOutput _addAndReturn(ShellOutput output) {
    _addOutput(output);
    return output;
  }
}
