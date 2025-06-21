import 'dart:ui';

/// ANSI颜色定义
class AnsiColor {
  static const Color black = Color(0xFF000000);
  static const Color red = Color(0xFFCD3131);
  static const Color green = Color(0xFF0DBC79);
  static const Color yellow = Color(0xFFE5E510);
  static const Color blue = Color(0xFF2472C8);
  static const Color magenta = Color(0xFFBC3FBC);
  static const Color cyan = Color(0xFF11A8CD);
  static const Color white = Color(0xFFE5E5E5);
  
  // 明亮颜色
  static const Color brightBlack = Color(0xFF666666);
  static const Color brightRed = Color(0xFFF14C4C);
  static const Color brightGreen = Color(0xFF23D18B);
  static const Color brightYellow = Color(0xFFF5F543);
  static const Color brightBlue = Color(0xFF3B8EEA);
  static const Color brightMagenta = Color(0xFFD670D6);
  static const Color brightCyan = Color(0xFF29B8DB);
  static const Color brightWhite = Color(0xFFE5E5E5);
  
  // 默认终端颜色
  static const Color defaultForeground = Color(0xFFE6EDF3);
  static const Color defaultBackground = Color(0xFF0C0C0C);
}

/// 文本样式
class TextStyle {
  final bool bold;
  final bool dim;
  final bool italic;
  final bool underline;
  final bool blink;
  final bool reverse;
  final bool strikethrough;
  
  const TextStyle({
    this.bold = false,
    this.dim = false,
    this.italic = false,
    this.underline = false,
    this.blink = false,
    this.reverse = false,
    this.strikethrough = false,
  });
  
  TextStyle copyWith({
    bool? bold,
    bool? dim,
    bool? italic,
    bool? underline,
    bool? blink,
    bool? reverse,
    bool? strikethrough,
  }) {
    return TextStyle(
      bold: bold ?? this.bold,
      dim: dim ?? this.dim,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      blink: blink ?? this.blink,
      reverse: reverse ?? this.reverse,
      strikethrough: strikethrough ?? this.strikethrough,
    );
  }
}

/// 终端字符
class TerminalChar {
  final String char;
  final Color foregroundColor;
  final Color backgroundColor;
  final TextStyle style;
  
  const TerminalChar({
    required this.char,
    this.foregroundColor = AnsiColor.defaultForeground,
    this.backgroundColor = AnsiColor.defaultBackground,
    this.style = const TextStyle(),
  });
  
  TerminalChar copyWith({
    String? char,
    Color? foregroundColor,
    Color? backgroundColor,
    TextStyle? style,
  }) {
    return TerminalChar(
      char: char ?? this.char,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      style: style ?? this.style,
    );
  }
}

/// 终端操作类型
enum TerminalOperationType {
  command,
  character,
}

/// 终端操作
class TerminalOperation {
  final TerminalOperationType type;
  final AnsiCommand? command;
  final TerminalChar? character;

  const TerminalOperation.command(this.command)
      : type = TerminalOperationType.command, character = null;

  const TerminalOperation.character(this.character)
      : type = TerminalOperationType.character, command = null;
}

/// ANSI解析结果
class AnsiParseResult {
  final List<TerminalChar> chars;
  final List<AnsiCommand> commands;
  final List<TerminalOperation> operations; // 新增：按顺序的操作列表

  const AnsiParseResult({
    required this.chars,
    required this.commands,
    required this.operations,
  });
}

/// ANSI命令类型
enum AnsiCommandType {
  cursorUp,
  cursorDown,
  cursorForward,
  cursorBack,
  cursorPosition,
  cursorHome,
  clearScreen,
  clearLine,
  saveCursor,
  restoreCursor,
  setGraphicsMode,
  setMode,
  resetMode,
  unknown,
}

/// ANSI命令
class AnsiCommand {
  final AnsiCommandType type;
  final List<int> parameters;
  final String rawSequence;
  
  const AnsiCommand({
    required this.type,
    required this.parameters,
    required this.rawSequence,
  });
}

/// ANSI序列解析器
class AnsiParser {
  Color _currentForeground = AnsiColor.defaultForeground;
  Color _currentBackground = AnsiColor.defaultBackground;
  TextStyle _currentStyle = const TextStyle();
  
  /// 解析ANSI序列文本
  AnsiParseResult parse(String text) {
    final chars = <TerminalChar>[];
    final commands = <AnsiCommand>[];
    final operations = <TerminalOperation>[]; // 按顺序记录操作

    int i = 0;
    while (i < text.length) {
      if (text[i] == '\x1b' && i + 1 < text.length) {
        if (text[i + 1] == '[') {
          // CSI序列 (Control Sequence Introducer)
          final sequenceResult = _parseAnsiSequence(text, i);
          if (sequenceResult != null) {
            commands.add(sequenceResult.command);
            operations.add(TerminalOperation.command(sequenceResult.command));
            if (sequenceResult.command.type == AnsiCommandType.setGraphicsMode) {
              _applyGraphicsMode(sequenceResult.command.parameters);
            }
            i = sequenceResult.endIndex;
          } else {
            // 无效序列，作为普通字符处理
            final char = TerminalChar(
              char: text[i],
              foregroundColor: _currentForeground,
              backgroundColor: _currentBackground,
              style: _currentStyle,
            );
            chars.add(char);
            operations.add(TerminalOperation.character(char));
            i++;
          }
        } else if (text[i + 1] == ']') {
          // OSC序列 (Operating System Command)
          final oscResult = _parseOscSequence(text, i);
          if (oscResult != null) {
            // OSC序列被解析但不显示（如窗口标题设置）
            i = oscResult;
          } else {
            // 无效OSC序列，作为普通字符处理
            final char = TerminalChar(
              char: text[i],
              foregroundColor: _currentForeground,
              backgroundColor: _currentBackground,
              style: _currentStyle,
            );
            chars.add(char);
            operations.add(TerminalOperation.character(char));
            i++;
          }
        } else {
          // 其他转义序列的处理
          final escapeResult = _parseOtherEscapeSequence(text, i);
          if (escapeResult != null) {
            // 转义序列被解析，跳过
            i = escapeResult;
          } else {
            // 无效转义序列，作为普通字符处理
            final char = TerminalChar(
              char: text[i],
              foregroundColor: _currentForeground,
              backgroundColor: _currentBackground,
              style: _currentStyle,
            );
            chars.add(char);
            operations.add(TerminalOperation.character(char));
            i++;
          }
        }
      } else {
        // 普通字符
        final char = TerminalChar(
          char: text[i],
          foregroundColor: _currentForeground,
          backgroundColor: _currentBackground,
          style: _currentStyle,
        );
        chars.add(char);
        operations.add(TerminalOperation.character(char));
        i++;
      }
    }

    return AnsiParseResult(chars: chars, commands: commands, operations: operations);
  }
  
  /// 解析单个ANSI序列
  _AnsiSequenceResult? _parseAnsiSequence(String text, int startIndex) {
    if (startIndex + 2 >= text.length) return null;

    int i = startIndex + 2; // 跳过 '\x1b['
    final parameters = <int>[];
    String paramBuffer = '';

    // 解析参数
    while (i < text.length) {
      final char = text[i];
      if (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) {
        // 数字
        paramBuffer += char;
      } else if (char == ';') {
        // 参数分隔符
        if (paramBuffer.isNotEmpty) {
          parameters.add(int.tryParse(paramBuffer) ?? 0);
          paramBuffer = '';
        }
      } else if (char.codeUnitAt(0) >= 64 && char.codeUnitAt(0) <= 126) {
        // 命令字符
        if (paramBuffer.isNotEmpty) {
          parameters.add(int.tryParse(paramBuffer) ?? 0);
        }

        final command = _createAnsiCommand(char, parameters, text.substring(startIndex, i + 1));
        return _AnsiSequenceResult(command: command, endIndex: i + 1);
      } else {
        // 无效字符，停止解析
        break;
      }
      i++;
    }

    return null;
  }

  /// 解析OSC序列 (Operating System Command)
  /// OSC序列格式: ESC ] Ps ; Pt ST
  /// 其中 ST 可以是 ESC \ 或 BEL (\x07)
  int? _parseOscSequence(String text, int startIndex) {
    if (startIndex + 2 >= text.length) return null;

    int i = startIndex + 2; // 跳过 '\x1b]'

    // 查找OSC序列的结束符
    while (i < text.length) {
      final char = text[i];

      // 检查BEL终止符 (\x07)
      if (char == '\x07') {
        return i + 1;
      }

      // 检查ST终止符 (ESC \)
      if (char == '\x1b' && i + 1 < text.length && text[i + 1] == '\\') {
        return i + 2;
      }

      i++;
    }

    // 如果没有找到终止符，返回null表示无效序列
    return null;
  }

  /// 解析其他转义序列
  /// 处理一些常见的转义序列，如 ESC ( 、ESC ) 等
  int? _parseOtherEscapeSequence(String text, int startIndex) {
    if (startIndex + 1 >= text.length) return null;

    final secondChar = text[startIndex + 1];

    // 处理一些常见的两字符转义序列
    switch (secondChar) {
      case '(':  // 字符集选择 G0
      case ')':  // 字符集选择 G1
      case '*':  // 字符集选择 G2
      case '+':  // 字符集选择 G3
        // 这些序列通常后面跟一个字符
        if (startIndex + 2 < text.length) {
          return startIndex + 3;
        }
        break;
      case '=':  // 应用键盘模式
      case '>':  // 数字键盘模式
      case '7':  // 保存光标
      case '8':  // 恢复光标
      case 'D':  // 索引 (向下滚动)
      case 'E':  // 下一行
      case 'H':  // 设置制表符
      case 'M':  // 反向索引 (向上滚动)
      case 'Z':  // 终端标识
      case 'c':  // 重置
        return startIndex + 2;
    }

    return null;
  }
  
  /// 创建ANSI命令
  AnsiCommand _createAnsiCommand(String commandChar, List<int> parameters, String rawSequence) {
    AnsiCommandType type;
    
    switch (commandChar) {
      case 'A':
        type = AnsiCommandType.cursorUp;
        break;
      case 'B':
        type = AnsiCommandType.cursorDown;
        break;
      case 'C':
        type = AnsiCommandType.cursorForward;
        break;
      case 'D':
        type = AnsiCommandType.cursorBack;
        break;
      case 'H':
      case 'f':
        type = AnsiCommandType.cursorPosition;
        break;
      case 'J':
        type = AnsiCommandType.clearScreen;
        break;
      case 'K':
        type = AnsiCommandType.clearLine;
        break;
      case 's':
        type = AnsiCommandType.saveCursor;
        break;
      case 'u':
        type = AnsiCommandType.restoreCursor;
        break;
      case 'm':
        type = AnsiCommandType.setGraphicsMode;
        break;
      case 'h':
        type = AnsiCommandType.setMode;
        break;
      case 'l':
        type = AnsiCommandType.resetMode;
        break;
      default:
        type = AnsiCommandType.unknown;
    }
    
    return AnsiCommand(
      type: type,
      parameters: parameters,
      rawSequence: rawSequence,
    );
  }
  
  /// 应用图形模式设置
  void _applyGraphicsMode(List<int> parameters) {
    if (parameters.isEmpty) {
      parameters = [0]; // 默认重置
    }
    
    for (final param in parameters) {
      switch (param) {
        case 0: // 重置
          _currentForeground = AnsiColor.defaultForeground;
          _currentBackground = AnsiColor.defaultBackground;
          _currentStyle = const TextStyle();
          break;
        case 1: // 粗体
          _currentStyle = _currentStyle.copyWith(bold: true);
          break;
        case 2: // 暗淡
          _currentStyle = _currentStyle.copyWith(dim: true);
          break;
        case 3: // 斜体
          _currentStyle = _currentStyle.copyWith(italic: true);
          break;
        case 4: // 下划线
          _currentStyle = _currentStyle.copyWith(underline: true);
          break;
        case 5: // 闪烁
          _currentStyle = _currentStyle.copyWith(blink: true);
          break;
        case 7: // 反转
          _currentStyle = _currentStyle.copyWith(reverse: true);
          break;
        case 9: // 删除线
          _currentStyle = _currentStyle.copyWith(strikethrough: true);
          break;
        case 22: // 正常强度
          _currentStyle = _currentStyle.copyWith(bold: false, dim: false);
          break;
        case 23: // 非斜体
          _currentStyle = _currentStyle.copyWith(italic: false);
          break;
        case 24: // 非下划线
          _currentStyle = _currentStyle.copyWith(underline: false);
          break;
        case 25: // 非闪烁
          _currentStyle = _currentStyle.copyWith(blink: false);
          break;
        case 27: // 非反转
          _currentStyle = _currentStyle.copyWith(reverse: false);
          break;
        case 29: // 非删除线
          _currentStyle = _currentStyle.copyWith(strikethrough: false);
          break;
        // 前景色
        case 30: _currentForeground = AnsiColor.black; break;
        case 31: _currentForeground = AnsiColor.red; break;
        case 32: _currentForeground = AnsiColor.green; break;
        case 33: _currentForeground = AnsiColor.yellow; break;
        case 34: _currentForeground = AnsiColor.blue; break;
        case 35: _currentForeground = AnsiColor.magenta; break;
        case 36: _currentForeground = AnsiColor.cyan; break;
        case 37: _currentForeground = AnsiColor.white; break;
        case 39: _currentForeground = AnsiColor.defaultForeground; break;
        // 背景色
        case 40: _currentBackground = AnsiColor.black; break;
        case 41: _currentBackground = AnsiColor.red; break;
        case 42: _currentBackground = AnsiColor.green; break;
        case 43: _currentBackground = AnsiColor.yellow; break;
        case 44: _currentBackground = AnsiColor.blue; break;
        case 45: _currentBackground = AnsiColor.magenta; break;
        case 46: _currentBackground = AnsiColor.cyan; break;
        case 47: _currentBackground = AnsiColor.white; break;
        case 49: _currentBackground = AnsiColor.defaultBackground; break;
        // 明亮前景色
        case 90: _currentForeground = AnsiColor.brightBlack; break;
        case 91: _currentForeground = AnsiColor.brightRed; break;
        case 92: _currentForeground = AnsiColor.brightGreen; break;
        case 93: _currentForeground = AnsiColor.brightYellow; break;
        case 94: _currentForeground = AnsiColor.brightBlue; break;
        case 95: _currentForeground = AnsiColor.brightMagenta; break;
        case 96: _currentForeground = AnsiColor.brightCyan; break;
        case 97: _currentForeground = AnsiColor.brightWhite; break;
        // 明亮背景色
        case 100: _currentBackground = AnsiColor.brightBlack; break;
        case 101: _currentBackground = AnsiColor.brightRed; break;
        case 102: _currentBackground = AnsiColor.brightGreen; break;
        case 103: _currentBackground = AnsiColor.brightYellow; break;
        case 104: _currentBackground = AnsiColor.brightBlue; break;
        case 105: _currentBackground = AnsiColor.brightMagenta; break;
        case 106: _currentBackground = AnsiColor.brightCyan; break;
        case 107: _currentBackground = AnsiColor.brightWhite; break;
      }
    }
  }
  
  /// 重置解析器状态
  void reset() {
    _currentForeground = AnsiColor.defaultForeground;
    _currentBackground = AnsiColor.defaultBackground;
    _currentStyle = const TextStyle();
  }
}

/// ANSI序列解析结果（内部使用）
class _AnsiSequenceResult {
  final AnsiCommand command;
  final int endIndex;
  
  const _AnsiSequenceResult({
    required this.command,
    required this.endIndex,
  });
}
