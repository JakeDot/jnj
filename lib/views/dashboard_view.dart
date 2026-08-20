import 'package:flutter/material.dart';

import '../models/jules_request.dart';
import '../services/shell_engine.dart';

class DashboardView extends StatefulWidget {
  final ShellEngine shellEngine;

  const DashboardView({
    super.key,
    required this.shellEngine,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  RequestStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    // Performance Optimization: Avoid O(N) list allocation and iteration on every render frame
    // when no status filter is applied.
    final allRequests = widget.shellEngine.requestHistory;
    final requests = _statusFilter == null
        ? allRequests
        : allRequests.where((req) => req.status == _statusFilter).toList();

    return Column(
      children: [
        Container(
          color: const Color(0xFF1E1E2E),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Text('Filter Status: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(width: 8),
              DropdownButton<RequestStatus?>(
                value: _statusFilter,
                dropdownColor: const Color(0xFF313244),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                underline: Container(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Statuses')),
                  ...RequestStatus.values.map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.name.toUpperCase()),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _statusFilter = val;
                  });
                },
              ),
              const Spacer(),
              Text(
                '${requests.length} Requests',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),

        Expanded(
          child: requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.code_off, size: 48, color: Colors.white30),
                      const SizedBox(height: 12),
                      const Text(
                        'No Jules Requests Found',
                        style: TextStyle(color: Colors.white60, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.terminal, size: 16),
                        label: const Text('Start Shell Prompt'),
                        onPressed: () {},
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return _buildRequestCard(req);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(JulesRequest req) {
    Color statusColor;
    IconData statusIcon;

    switch (req.status) {
      case RequestStatus.completed:
        statusColor = const Color(0xFFA6E3A1);
        statusIcon = Icons.check_circle;
        break;
      case RequestStatus.failed:
        statusColor = const Color(0xFFF38BA8);
        statusIcon = Icons.error;
        break;
      case RequestStatus.running:
        statusColor = const Color(0xFFF9E2AF);
        statusIcon = Icons.autorenew;
        break;
      case RequestStatus.pending:
        statusColor = const Color(0xFF89B4FA);
        statusIcon = Icons.hourglass_top;
        break;
    }

    return Card(
      color: const Color(0xFF181825),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          req.prompt,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          'ID: ${req.id} • ${req.createdAt.toString().split('.').first}',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (req.linkedGitHubItems.isNotEmpty) ...[
                  const Text('Linked GitHub Items:', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: req.linkedGitHubItems.map((gh) {
                      return Chip(
                        avatar: Icon(gh.isPR ? Icons.merge_type : Icons.bug_report, size: 14, color: Colors.cyanAccent),
                        label: Text('${gh.shortRef}: ${gh.title}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                        backgroundColor: const Color(0xFF313244),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text('Response Output:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF11111B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    req.response.isNotEmpty ? req.response : 'No output available.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                if (req.executionLogs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Execution Logs:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      req.executionLogs.join('\n'),
                      style: const TextStyle(color: Colors.white38, fontFamily: 'monospace', fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }
}
