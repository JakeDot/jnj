import 'package:flutter/material.dart';

import '../models/shell_command.dart';
import '../services/shell_engine.dart';

class TerminalView extends StatefulWidget {
  final ShellEngine shellEngine;

  const TerminalView({
    super.key,
    required this.shellEngine,
  });

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  int _historyIndex = -1;
  bool _isExecuting = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submitCommand() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isExecuting) return;

    _inputController.clear();
    _historyIndex = -1;

    setState(() {
      _isExecuting = true;
    });

    await widget.shellEngine.executeInput(text);

    if (mounted) {
      setState(() {
        _isExecuting = false;
      });
      _scrollToBottom();
      _focusNode.requestFocus();
    }
  }

  void _navigateHistory(int direction) {
    final history = widget.shellEngine.commandHistory;
    if (history.isEmpty) return;

    int newIndex = _historyIndex + direction;
    if (newIndex < -1) newIndex = -1;
    if (newIndex >= history.length) newIndex = history.length - 1;

    _historyIndex = newIndex;

    if (_historyIndex == -1) {
      _inputController.clear();
    } else {
      _inputController.text = history[history.length - 1 - _historyIndex];
      _inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: _inputController.text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeContext = widget.shellEngine.activeGitHubContext;

    return Column(
      children: [
        if (activeContext != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blueGrey.shade900,
            child: Row(
              children: [
                const Icon(Icons.link, color: Colors.cyanAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Active Context: ${activeContext.shortRef} - "${activeContext.title}"',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      widget.shellEngine.setActiveGitHubContext(null);
                    });
                  },
                  child: const Text('Clear', style: TextStyle(color: Colors.white70, fontSize: 12)),
                )
              ],
            ),
          ),

        Container(
          color: const Color(0xFF1E1E2E),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip('jules help', 'Help'),
                _buildQuickChip('gh pr list', 'PRs'),
                _buildQuickChip('gh issue list', 'Issues'),
                _buildQuickChip('config view', 'Config'),
                _buildQuickChip('history', 'History'),
                _buildQuickChip('clear', 'Clear'),
              ],
            ),
          ),
        ),

        Expanded(
          child: Container(
            color: const Color(0xFF11111B),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: widget.shellEngine.outputs.length,
              itemBuilder: (context, index) {
                final item = widget.shellEngine.outputs[index];
                return _buildOutputTile(item);
              },
            ),
          ),
        ),

        Container(
          color: const Color(0xFF181825),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text(
                'jules \$ ',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter command or prompt (e.g., "Fix bug in PR #101")...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _submitCommand(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_upward, color: Colors.white54, size: 20),
                tooltip: 'Previous Command',
                onPressed: () => _navigateHistory(1),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, color: Colors.white54, size: 20),
                tooltip: 'Next Command',
                onPressed: () => _navigateHistory(-1),
              ),
              IconButton(
                icon: _isExecuting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.cyanAccent),
                onPressed: _submitCommand,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip(String command, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: const Color(0xFF313244),
        label: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        onPressed: () {
          _inputController.text = command;
          _submitCommand();
        },
      ),
    );
  }

  Widget _buildOutputTile(ShellOutput item) {
    Color textColor;
    IconData? icon;

    switch (item.type) {
      case ShellOutputType.success:
        textColor = const Color(0xFFA6E3A1);
        icon = Icons.check_circle_outline;
        break;
      case ShellOutputType.error:
        textColor = const Color(0xFFF38BA8);
        icon = Icons.error_outline;
        break;
      case ShellOutputType.info:
        textColor = const Color(0xFF89B4FA);
        icon = Icons.info_outline;
        break;
      case ShellOutputType.card:
        textColor = const Color(0xFFFAB387);
        icon = Icons.grid_view_rounded;
        break;
      case ShellOutputType.json:
      case ShellOutputType.text:
        textColor = Colors.white;
        icon = null;
        break;
    }

    final isCommand = item.content.startsWith('\$ ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor, size: 16),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: SelectableText(
                  item.content,
                  style: TextStyle(
                    color: isCommand ? Colors.greenAccent : textColor,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: isCommand ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          if (item.request != null && item.request!.linkedGitHubItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 24),
              child: Wrap(
                spacing: 8,
                children: item.request!.linkedGitHubItems.map((gh) {
                  return Chip(
                    avatar: Icon(
                      gh.isPR ? Icons.merge_type : Icons.bug_report,
                      size: 14,
                      color: Colors.cyanAccent,
                    ),
                    label: Text(
                      gh.shortRef,
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                    ),
                    backgroundColor: const Color(0xFF181825),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
