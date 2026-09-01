import 'github_item.dart';
import 'jules_request.dart';

enum ShellOutputType { text, success, error, info, json, card }

class ShellOutput {
  final String content;
  final ShellOutputType type;
  final DateTime timestamp;
  final JulesRequest? request;
  final GitHubItem? githubItem;

  ShellOutput({
    required this.content,
    this.type = ShellOutputType.text,
    DateTime? timestamp,
    this.request,
    this.githubItem,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ParsedCommand {
  final String command;
  final List<String> args;
  final Map<String, String> options;
  final String rawInput;

  ParsedCommand({
    required this.command,
    required this.args,
    required this.options,
    required this.rawInput,
  });

  static ParsedCommand parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return ParsedCommand(command: '', args: [], options: {}, rawInput: input);
    }

    final tokens = _tokenize(trimmed);
    if (tokens.isEmpty) {
      return ParsedCommand(command: '', args: [], options: {}, rawInput: input);
    }

    var cmd = tokens.first.toLowerCase();
    // Allow 'jules <cmd>' prefix
    int startIndex = 1;
    if (cmd == 'jules' && tokens.length > 1) {
      cmd = tokens[1].toLowerCase();
      startIndex = 2;
    }

    final args = <String>[];
    final options = <String, String>{};

    for (int i = startIndex; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.startsWith('--')) {
        final parts = token.substring(2).split('=');
        final key = parts[0];
        final val = parts.length > 1 ? parts.sublist(1).join('=') : 'true';
        options[key] = val;
      } else if (token.startsWith('-') && token.length == 2) {
        final key = token.substring(1);
        if (i + 1 < tokens.length && !tokens[i + 1].startsWith('-')) {
          options[key] = tokens[i + 1];
          i++;
        } else {
          options[key] = 'true';
        }
      } else {
        args.add(token);
      }
    }

    return ParsedCommand(
      command: cmd,
      args: args,
      options: options,
      rawInput: input,
    );
  }

  // Performance Optimization: Use integer code units and substring slicing rather than
  // character-by-character `input[i]` indexing and `StringBuffer.write` per character.
  // Slicing tokens with `input.substring(start, end)` reduces intermediate object
  // allocations and string copy overhead when parsing command inputs.
  static List<String> _tokenize(String input) {
    final tokens = <String>[];
    final length = input.length;
    int i = 0;

    // Code units for fast integer comparisons
    const int space = 0x20; // ' '
    const int doubleQuote = 0x22; // '"'
    const int singleQuote = 0x27; // '\''

    StringBuffer? quotedSb;

    while (i < length) {
      // Skip leading whitespace
      while (i < length && input.codeUnitAt(i) == space) {
        i++;
      }
      if (i >= length) break;

      final start = i;
      bool containsQuotes = false;

      // Scan token boundaries
      while (i < length) {
        final code = input.codeUnitAt(i);
        if (code == space) {
          break;
        } else if (code == doubleQuote || code == singleQuote) {
          containsQuotes = true;
          final quote = code;
          i++; // skip open quote
          while (i < length && input.codeUnitAt(i) != quote) {
            i++;
          }
          if (i < length) {
            i++; // skip close quote
          }
        } else {
          i++;
        }
      }

      if (!containsQuotes) {
        // Fast path: pure substring slice without any quotes
        tokens.add(input.substring(start, i));
      } else {
        // Quoted token: strip enclosing quote characters cleanly
        quotedSb ??= StringBuffer();
        quotedSb.clear();

        int j = start;
        int activeQuote = 0;

        while (j < i) {
          final code = input.codeUnitAt(j);
          if (activeQuote == 0) {
            if (code == doubleQuote || code == singleQuote) {
              activeQuote = code;
            } else {
              quotedSb.writeCharCode(code);
            }
          } else if (code == activeQuote) {
            activeQuote = 0;
          } else {
            quotedSb.writeCharCode(code);
          }
          j++;
        }

        tokens.add(quotedSb.toString());
      }
    }

    return tokens;
  }
}
