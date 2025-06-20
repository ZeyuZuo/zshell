import 'ansi_parser.dart';

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
  
  // 光标位置
  CursorPosition _cursor = const CursorPosition(row: 0, col: 0);
  
  // 保存的光标位置
  CursorPosition? _savedCursor;
  
  // ANSI解析器
  final AnsiParser _parser = AnsiParser();
  
  // 滚动区域
  int _scrollTop = 0;
  late int _scrollBottom;
  
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
  
  /// 写入文本到缓冲区
  void write(String text) {
    final parseResult = _parser.parse(text);
    
    // 处理命令
    for (final command in parseResult.commands) {
      _executeCommand(command);
    }
    
    // 写入字符
    for (final char in parseResult.chars) {
      _writeChar(char);
    }
  }
  
  /// 写入单个字符
  void _writeChar(TerminalChar char) {
    // 处理特殊字符
    switch (char.char) {
      case '\r':
        _cursor = _cursor.copyWith(col: 0);
        return;
      case '\n':
        _newLine();
        return;
      case '\t':
        // Tab键，移动到下一个8的倍数位置
        final nextTab = ((_cursor.col ~/ 8) + 1) * 8;
        _cursor = _cursor.copyWith(col: nextTab.clamp(0, width - 1));
        return;
      case '\b':
        // 退格键
        if (_cursor.col > 0) {
          _cursor = _cursor.copyWith(col: _cursor.col - 1);
        }
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
        _buffer[_cursor.row][_cursor.col] = char;

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
      _cursor = _cursor.copyWith(row: _cursor.row + 1);
      // 注意：不要自动设置col为0，让\r字符来处理
    }
  }
  
  /// 向上滚动
  void _scrollUp() {
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
    
    // 光标保持在最后一行的开头
    _cursor = CursorPosition(row: _scrollBottom, col: 0);
  }
  
  /// 执行ANSI命令
  void _executeCommand(AnsiCommand command) {
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
        _cursor = _cursor.copyWith(col: (_cursor.col + count).clamp(0, width - 1));
        break;
        
      case AnsiCommandType.cursorBack:
        final count = command.parameters.isNotEmpty ? command.parameters[0] : 1;
        _cursor = _cursor.copyWith(col: (_cursor.col - count).clamp(0, width - 1));
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
        
      case AnsiCommandType.unknown:
        // 忽略未知命令
        break;
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
