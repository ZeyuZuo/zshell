import 'ansi_parser.dart';

// 调试模式标志
const bool _debugMode = false;

/// 光标位置
class CursorPosition {
  final int row;
  final int col;
  
  const CursorPosition({required this.row, required this.col});
  
  CursorPosition copyWith({int? row, int? col}) {
    return CursorPosition(
      row: row ?? this.row,
      col: col ?? this.col,
    );
  }
  
  @override
  String toString() => 'CursorPosition(row: $row, col: $col)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CursorPosition && other.row == row && other.col == col;
  }
  
  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

/// 终端缓冲区
class TerminalBuffer {
  final int width;
  final int height;

  // 字符缓冲区 - 二维数组存储每个位置的字符
  late List<List<TerminalChar>> _buffer;

  // 历史缓冲区 - 存储滚动出屏幕的行
  final List<List<TerminalChar>> _historyBuffer = [];
  static const int _maxHistoryLines = 1000; // 最大历史行数

  // 光标位置
  CursorPosition _cursor = const CursorPosition(row: 0, col: 0);

  // 保存的光标位置
  CursorPosition? _savedCursor;

  // ANSI解析器
  final AnsiParser _parser = AnsiParser();

  // 滚动区域
  int _scrollTop = 0;
  late int _scrollBottom;

  // Alternate screen buffer状态
  bool _isAlternateScreen = false;
  List<List<TerminalChar>>? _mainScreenBuffer;
  CursorPosition? _mainScreenCursor;
  
  TerminalBuffer({required this.width, required this.height}) {
    _scrollBottom = height - 1;
    _initializeBuffer();
  }
  
  /// 初始化缓冲区
  void _initializeBuffer() {
    _buffer = List.generate(
      height,
      (row) => List.generate(
        width,
        (col) => const TerminalChar(char: ' '),
      ),
    );
  }
  
  /// 获取当前光标位置
  CursorPosition get cursor => _cursor;
  
  /// 获取缓冲区内容
  List<List<TerminalChar>> get buffer => _buffer;

  /// 获取历史缓冲区内容
  List<List<TerminalChar>> get historyBuffer => _historyBuffer;

  /// 获取历史缓冲区行数
  int get historyLineCount => _historyBuffer.length;

  /// 获取总行数（历史 + 当前）
  int get totalLineCount => _historyBuffer.length + height;

  /// 检查是否在alternate screen模式
  bool get isAlternateScreen => _isAlternateScreen;
  
  /// 写入文本到缓冲区
  void write(String text) {
    // 关键修复：忽略空字符串输入，防止覆盖现有字符
    if (text.isEmpty) {
      if (_debugMode) {
        print('WRITE_SKIP: Ignoring empty string input');
      }
      return;
    }

    final parseResult = _parser.parse(text);

    // 检测是否包含命令历史相关的序列
    final hasHistorySequence = _detectCommandHistorySequence(parseResult);

    // 调试：记录所有解析结果
    if (_debugMode) {
      print('PARSE_RESULT: text="${text.replaceAll('\x1b', '\\x1b')}" -> ${parseResult.operations.length} operations');
      for (int i = 0; i < parseResult.operations.length; i++) {
        final op = parseResult.operations[i];
        if (op.type == TerminalOperationType.command) {
          print('  [$i] COMMAND: ${op.command!.type} ${op.command!.rawSequence}');
        } else {
          print('  [$i] CHAR: "${op.character!.char}" (code: ${op.character!.char.isNotEmpty ? op.character!.char.codeUnitAt(0) : 'empty'})');
        }
      }
    }

    // 按顺序处理操作 - 这是修复渲染问题的关键
    for (final operation in parseResult.operations) {
      switch (operation.type) {
        case TerminalOperationType.command:
          if (operation.command != null) {
            _executeCommand(operation.command!);
          }
          break;
        case TerminalOperationType.character:
          if (operation.character != null) {
            _writeChar(operation.character!);
          }
          break;
      }
    }

    // 如果检测到命令历史序列，确保渲染一致性
    if (hasHistorySequence) {
      _ensureRenderingConsistency();
    }
  }

  /// 检测命令历史序列
  bool _detectCommandHistorySequence(AnsiParseResult parseResult) {
    // 检测典型的命令历史模式：
    // 1. 光标定位到行首
    // 2. 清除行内容
    // 3. 写入新命令
    bool hasCursorPosition = false;
    bool hasClearLine = false;

    for (final command in parseResult.commands) {
      if (command.type == AnsiCommandType.cursorPosition ||
          command.type == AnsiCommandType.cursorBack) {
        hasCursorPosition = true;
      }
      if (command.type == AnsiCommandType.clearLine) {
        hasClearLine = true;
      }
    }

    // 如果有字符输出且有光标操作，可能是命令历史
    return parseResult.chars.isNotEmpty && (hasCursorPosition || hasClearLine);
  }

  /// 确保渲染一致性
  void _ensureRenderingConsistency() {
    // 确保光标位置在有效范围内
    _cursor = _cursor.copyWith(
      row: _cursor.row.clamp(0, height - 1),
      col: _cursor.col.clamp(0, width - 1),
    );
  }
  
  /// 写入单个字符
  void _writeChar(TerminalChar char) {
    // 处理特殊字符
    switch (char.char) {
      case '\r':
        // 回车符：将光标移动到当前行的开头
        // 调试日志：记录回车符操作
        if (_debugMode) {
          print('CR: Moving cursor from ${_cursor.col} to 0 on row ${_cursor.row}');
        }
        _cursor = _cursor.copyWith(col: 0);
        return;
      case '\n':
        // 换行符：移动到下一行
        _newLine();
        return;
      case '\t':
        // Tab键，移动到下一个8的倍数位置
        final nextTab = ((_cursor.col ~/ 8) + 1) * 8;
        _cursor = _cursor.copyWith(col: nextTab.clamp(0, width - 1));
        return;
      case '\b':
        // 退格字符：只移动光标，不删除字符
        // 注意：这里的退格字符通常来自左方向键，应该只移动光标
        if (_cursor.col > 0) {
          _cursor = _cursor.copyWith(col: _cursor.col - 1);
          // 修复：不删除字符，只移动光标
          if (_debugMode) {
            print('BACKSPACE: Moving cursor left without deleting character');
          }
        }
        return;
      case '\x07':
        // BEL字符（响铃），忽略
        return;
    }

    // 如果是可打印字符
    if (char.char.isNotEmpty && char.char.codeUnitAt(0) >= 32) {
      // 计算字符宽度（中文字符占2个位置）
      final charWidth = _getCharWidth(char.char);

      // 检查是否需要换行
      if (_cursor.col + charWidth > width) {
        _newLine();
      }

      // 写入字符
      if (_cursor.row < height && _cursor.col < width) {
        final oldChar = _buffer[_cursor.row][_cursor.col].char;
        _buffer[_cursor.row][_cursor.col] = char;

        // 调试：记录字符覆盖，特别关注空格覆盖
        if (_debugMode && oldChar.isNotEmpty && oldChar != ' ' && char.char != oldChar) {
          print('CHAR_OVERWRITE: pos(${_cursor.row},${_cursor.col}) "$oldChar" -> "${char.char}"');
        }
        // 特别关注空格覆盖非空字符的情况（这可能是导致字符消失的原因）
        if (_debugMode && oldChar.isNotEmpty && oldChar != ' ' && char.char == ' ') {
          print('SPACE_OVERWRITE: pos(${_cursor.row},${_cursor.col}) "$oldChar" -> SPACE - This may cause character disappearance!');
        }

        // 如果是宽字符，在下一个位置放置占位符
        if (charWidth == 2 && _cursor.col + 1 < width) {
          _buffer[_cursor.row][_cursor.col + 1] = const TerminalChar(char: '');
        }

        _cursor = _cursor.copyWith(col: _cursor.col + charWidth);
      }
    }
  }

  /// 获取字符显示宽度
  int _getCharWidth(String char) {
    if (char.isEmpty) return 0;

    final codeUnit = char.codeUnitAt(0);

    // 中文字符范围（简化版本）
    if ((codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) ||  // CJK统一汉字
        (codeUnit >= 0x3400 && codeUnit <= 0x4DBF) ||  // CJK扩展A
        (codeUnit >= 0x20000 && codeUnit <= 0x2A6DF) || // CJK扩展B
        (codeUnit >= 0x2A700 && codeUnit <= 0x2B73F) || // CJK扩展C
        (codeUnit >= 0x2B740 && codeUnit <= 0x2B81F) || // CJK扩展D
        (codeUnit >= 0x2B820 && codeUnit <= 0x2CEAF) || // CJK扩展E
        (codeUnit >= 0x3000 && codeUnit <= 0x303F) ||   // CJK符号和标点
        (codeUnit >= 0xFF00 && codeUnit <= 0xFFEF)) {   // 全角ASCII
      return 2;
    }

    return 1;
  }
  
  /// 换行
  void _newLine() {
    if (_cursor.row >= _scrollBottom) {
      // 需要滚动
      _scrollUp();
    } else {
      _cursor = _cursor.copyWith(row: _cursor.row + 1, col: 0);
    }
  }
  
  /// 向上滚动
  void _scrollUp() {
    // 只在主屏幕模式下保存到历史缓冲区
    if (!_isAlternateScreen) {
      final firstLine = List<TerminalChar>.from(_buffer[_scrollTop]);
      _addToHistory(firstLine);
    }

    // 将所有行向上移动一行
    for (int row = _scrollTop; row < _scrollBottom; row++) {
      for (int col = 0; col < width; col++) {
        _buffer[row][col] = _buffer[row + 1][col];
      }
    }

    // 清空最后一行
    for (int col = 0; col < width; col++) {
      _buffer[_scrollBottom][col] = const TerminalChar(char: ' ');
    }

    // 光标移动到最后一行的开头
    _cursor = CursorPosition(row: _scrollBottom, col: 0);
  }

  /// 添加行到历史缓冲区
  void _addToHistory(List<TerminalChar> line) {
    _historyBuffer.add(line);

    // 如果历史缓冲区超过最大限制，删除最旧的行
    if (_historyBuffer.length > _maxHistoryLines) {
      _historyBuffer.removeAt(0);
    }
  }
  
  /// 执行ANSI命令
  void _executeCommand(AnsiCommand command) {
    final oldCursor = _cursor;

    switch (command.type) {
      case AnsiCommandType.cursorUp:
        final count = command.parameters.isNotEmpty ? command.parameters[0] : 1;
        _cursor = _cursor.copyWith(row: (_cursor.row - count).clamp(0, height - 1));
        break;

      case AnsiCommandType.cursorDown:
        final count = command.parameters.isNotEmpty ? command.parameters[0] : 1;
        _cursor = _cursor.copyWith(row: (_cursor.row + count).clamp(0, height - 1));
        break;

      case AnsiCommandType.cursorForward:
        final count = command.parameters.isNotEmpty ? command.parameters[0] : 1;
        final oldCol = _cursor.col;
        final oldChar = _buffer[_cursor.row][_cursor.col].char;
        _cursor = _cursor.copyWith(col: (_cursor.col + count).clamp(0, width - 1));
        final newChar = _buffer[_cursor.row][_cursor.col].char;
        if (_debugMode) {
          print('CURSOR_FORWARD: $oldCol -> ${_cursor.col}');
          print('  Old pos char: "$oldChar" | New pos char: "$newChar"');
          print('  Line: "${getLineText(_cursor.row)}"');
        }
        break;

      case AnsiCommandType.cursorBack:
        final count = command.parameters.isNotEmpty ? command.parameters[0] : 1;
        final oldCol = _cursor.col;
        final oldChar = _buffer[_cursor.row][_cursor.col].char;
        _cursor = _cursor.copyWith(col: (_cursor.col - count).clamp(0, width - 1));
        final newChar = _buffer[_cursor.row][_cursor.col].char;
        if (_debugMode) {
          print('CURSOR_BACK: $oldCol -> ${_cursor.col}');
          print('  Old pos char: "$oldChar" | New pos char: "$newChar"');
          print('  Line: "${getLineText(_cursor.row)}"');
        }
        break;

      case AnsiCommandType.cursorPosition:
        final row = command.parameters.isNotEmpty ? (command.parameters[0] - 1).clamp(0, height - 1) : 0;
        final col = command.parameters.length > 1 ? (command.parameters[1] - 1).clamp(0, width - 1) : 0;
        _cursor = CursorPosition(row: row, col: col);
        break;

      case AnsiCommandType.cursorHome:
        _cursor = const CursorPosition(row: 0, col: 0);
        break;

      case AnsiCommandType.clearScreen:
        final mode = command.parameters.isNotEmpty ? command.parameters[0] : 0;
        _clearScreen(mode);
        break;

      case AnsiCommandType.clearLine:
        final mode = command.parameters.isNotEmpty ? command.parameters[0] : 0;
        _clearLine(mode);
        break;

      case AnsiCommandType.saveCursor:
        _savedCursor = _cursor;
        break;

      case AnsiCommandType.restoreCursor:
        if (_savedCursor != null) {
          _cursor = _savedCursor!;
        }
        break;

      case AnsiCommandType.setGraphicsMode:
        // 图形模式由解析器处理
        break;

      case AnsiCommandType.setMode:
        _handleSetMode(command.parameters);
        break;

      case AnsiCommandType.resetMode:
        _handleResetMode(command.parameters);
        break;

      case AnsiCommandType.unknown:
        // 忽略未知命令
        break;
    }

    // 详细调试日志：记录所有重要操作
    if (command.type == AnsiCommandType.cursorPosition ||
        command.type == AnsiCommandType.clearLine ||
        command.type == AnsiCommandType.cursorBack ||
        command.type == AnsiCommandType.cursorForward ||
        (command.type == AnsiCommandType.cursorUp && command.parameters.isNotEmpty) ||
        (command.type == AnsiCommandType.cursorDown && command.parameters.isNotEmpty)) {
      // 启用详细日志用于调试命令历史问题
      if (_debugMode) {
        print('ANSI: ${command.rawSequence} | Cursor: $oldCursor -> $_cursor | Line: "${getLineText(_cursor.row)}"');
      }
    }
  }
  
  /// 清屏
  void _clearScreen(int mode) {
    switch (mode) {
      case 0: // 清除从光标到屏幕末尾
        for (int row = _cursor.row; row < height; row++) {
          final startCol = row == _cursor.row ? _cursor.col : 0;
          for (int col = startCol; col < width; col++) {
            _buffer[row][col] = const TerminalChar(char: ' ');
          }
        }
        break;
        
      case 1: // 清除从屏幕开始到光标
        for (int row = 0; row <= _cursor.row; row++) {
          final endCol = row == _cursor.row ? _cursor.col : width - 1;
          for (int col = 0; col <= endCol; col++) {
            _buffer[row][col] = const TerminalChar(char: ' ');
          }
        }
        break;
        
      case 2: // 清除整个屏幕
        _initializeBuffer();
        _cursor = const CursorPosition(row: 0, col: 0);
        break;
        
      case 3: // 清除整个屏幕和滚动缓冲区
        _initializeBuffer();
        _cursor = const CursorPosition(row: 0, col: 0);
        break;
    }
  }
  
  /// 清行
  void _clearLine(int mode) {
    if (_debugMode) {
      final lineText = getLineText(_cursor.row);
      print('CLEAR_LINE: mode=$mode, cursor=$_cursor, line="$lineText"');
    }

    switch (mode) {
      case 0: // 清除从光标到行尾
        for (int col = _cursor.col; col < width; col++) {
          _buffer[_cursor.row][col] = const TerminalChar(char: ' ');
        }
        break;

      case 1: // 清除从行首到光标
        for (int col = 0; col <= _cursor.col; col++) {
          _buffer[_cursor.row][col] = const TerminalChar(char: ' ');
        }
        break;

      case 2: // 清除整行
        for (int col = 0; col < width; col++) {
          _buffer[_cursor.row][col] = const TerminalChar(char: ' ');
        }
        break;
    }

    if (_debugMode) {
      final newLineText = getLineText(_cursor.row);
      print('CLEAR_LINE_RESULT: line="$newLineText"');
    }
  }

  /// 处理设置模式命令
  void _handleSetMode(List<int> parameters) {
    for (final param in parameters) {
      switch (param) {
        case 1049: // 启用alternate screen buffer
          _enterAlternateScreen();
          break;
        // 可以添加其他模式的处理
      }
    }
  }

  /// 处理重置模式命令
  void _handleResetMode(List<int> parameters) {
    for (final param in parameters) {
      switch (param) {
        case 1049: // 退出alternate screen buffer
          _exitAlternateScreen();
          break;
        // 可以添加其他模式的处理
      }
    }
  }

  /// 进入alternate screen buffer
  void _enterAlternateScreen() {
    if (!_isAlternateScreen) {
      // 保存当前主屏幕状态
      _mainScreenBuffer = List.generate(
        height,
        (row) => List.from(_buffer[row]),
      );
      _mainScreenCursor = _cursor;

      // 清空当前缓冲区
      _initializeBuffer();
      _cursor = const CursorPosition(row: 0, col: 0);

      _isAlternateScreen = true;
    }
  }

  /// 退出alternate screen buffer
  void _exitAlternateScreen() {
    if (_isAlternateScreen && _mainScreenBuffer != null) {
      // 恢复主屏幕状态
      _buffer = _mainScreenBuffer!;
      _cursor = _mainScreenCursor ?? const CursorPosition(row: 0, col: 0);

      _mainScreenBuffer = null;
      _mainScreenCursor = null;
      _isAlternateScreen = false;
    }
  }
  
  /// 调整缓冲区大小
  void resize(int newWidth, int newHeight) {
    final oldBuffer = _buffer;
    final oldWidth = width;
    final oldHeight = height;
    
    // 创建新缓冲区
    _buffer = List.generate(
      newHeight,
      (row) => List.generate(
        newWidth,
        (col) => const TerminalChar(char: ' '),
      ),
    );
    
    // 复制旧内容
    final copyRows = oldHeight < newHeight ? oldHeight : newHeight;
    final copyCols = oldWidth < newWidth ? oldWidth : newWidth;
    
    for (int row = 0; row < copyRows; row++) {
      for (int col = 0; col < copyCols; col++) {
        _buffer[row][col] = oldBuffer[row][col];
      }
    }
    
    // 调整光标位置
    _cursor = _cursor.copyWith(
      row: _cursor.row.clamp(0, newHeight - 1),
      col: _cursor.col.clamp(0, newWidth - 1),
    );
    
    // 调整滚动区域
    _scrollBottom = newHeight - 1;
  }
  
  /// 获取指定行的文本内容
  String getLineText(int row) {
    if (row < 0 || row >= height) return '';

    final buffer = StringBuffer();
    for (int col = 0; col < width; col++) {
      buffer.write(_buffer[row][col].char);
    }

    return buffer.toString().trimRight();
  }

  /// 获取指定行的字符数据（包括历史缓冲区）
  List<TerminalChar>? getLine(int absoluteRow) {
    if (absoluteRow < 0) return null;

    if (absoluteRow < _historyBuffer.length) {
      // 从历史缓冲区获取
      return _historyBuffer[absoluteRow];
    } else {
      // 从当前缓冲区获取
      final currentRow = absoluteRow - _historyBuffer.length;
      if (currentRow < height) {
        return _buffer[currentRow];
      }
    }

    return null;
  }

  /// 获取指定行的文本内容（包括历史缓冲区）
  String getLineTextAbsolute(int absoluteRow) {
    final line = getLine(absoluteRow);
    if (line == null) return '';

    final buffer = StringBuffer();
    for (int col = 0; col < width; col++) {
      if (col < line.length) {
        buffer.write(line[col].char);
      } else {
        buffer.write(' ');
      }
    }

    return buffer.toString().trimRight();
  }
  
  /// 获取所有文本内容
  String getAllText() {
    final buffer = StringBuffer();
    for (int row = 0; row < height; row++) {
      final lineText = getLineText(row);
      if (lineText.isNotEmpty || row < height - 1) {
        buffer.writeln(lineText);
      }
    }
    
    return buffer.toString();
  }
  
  /// 清空缓冲区
  void clear() {
    _initializeBuffer();
    _cursor = const CursorPosition(row: 0, col: 0);
    _parser.reset();
  }
}
