import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../core/terminal/terminal_buffer.dart';
import '../../core/terminal/ansi_parser.dart' as ansi;

/// 终端渲染器组件
class TerminalRenderer extends StatefulWidget {
  final TerminalBuffer buffer;
  final bool showCursor;
  final double fontSize;
  final String fontFamily;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const TerminalRenderer({
    Key? key,
    required this.buffer,
    this.showCursor = true,
    this.fontSize = 14.0,
    this.fontFamily = 'JetBrainsMono',
    this.padding = const EdgeInsets.all(8.0),
    this.onTap,
  }) : super(key: key);
  
  @override
  State<TerminalRenderer> createState() => _TerminalRendererState();
}

class _TerminalRendererState extends State<TerminalRenderer>
    with TickerProviderStateMixin {
  late AnimationController _cursorController;
  late Animation<double> _cursorAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // 光标闪烁动画
    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _cursorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cursorController,
      curve: Curves.easeInOut,
    ));
    
    _cursorController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        color: ansi.AnsiColor.defaultBackground,
        padding: widget.padding,
        child: CustomPaint(
          painter: _TerminalPainter(
            buffer: widget.buffer,
            fontSize: widget.fontSize,
            fontFamily: widget.fontFamily,
            showCursor: widget.showCursor,
            cursorOpacity: _cursorAnimation.value,
          ),
          size: Size(
            widget.buffer.width * _getCharWidth() + widget.padding.horizontal,
            widget.buffer.height * _getLineHeight() + widget.padding.vertical,
          ),
        ),
      ),
    );
  }
  
  /// 获取字符宽度
  double _getCharWidth() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'M', // 使用M字符测量，因为它通常是最宽的
        style: TextStyle(
          fontSize: widget.fontSize,
          fontFamily: widget.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width;
  }
  
  /// 获取行高
  double _getLineHeight() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'M',
        style: TextStyle(
          fontSize: widget.fontSize,
          fontFamily: widget.fontFamily,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.height;
  }
}

/// 终端绘制器
class _TerminalPainter extends CustomPainter {
  final TerminalBuffer buffer;
  final double fontSize;
  final String fontFamily;
  final bool showCursor;
  final double cursorOpacity;

  late final double _charWidth;
  late final double _lineHeight;

  _TerminalPainter({
    required this.buffer,
    required this.fontSize,
    required this.fontFamily,
    required this.showCursor,
    required this.cursorOpacity,
  }) {
    _calculateDimensions();
  }
  
  /// 计算字符尺寸
  void _calculateDimensions() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'M',
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: fontFamily,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    _charWidth = textPainter.width;
    _lineHeight = textPainter.height;
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景
    final backgroundPaint = Paint()..color = ansi.AnsiColor.defaultBackground;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // 绘制每个字符
    for (int row = 0; row < buffer.height; row++) {
      for (int col = 0; col < buffer.width; col++) {
        final char = buffer.buffer[row][col];
        _drawChar(canvas, char, row, col);
      }
    }

    // 绘制光标
    if (showCursor) {
      _drawCursor(canvas);
    }
  }
  
  /// 绘制单个字符
  void _drawChar(Canvas canvas, ansi.TerminalChar char, int row, int col) {
    // 跳过空占位符（宽字符的第二个位置）
    if (char.char.isEmpty) return;

    final x = col * _charWidth;
    final y = row * _lineHeight;

    // 计算字符宽度
    final charWidth = _getCharDisplayWidth(char.char);
    final displayWidth = charWidth * _charWidth;

    // 确定前景色和背景色
    Color foregroundColor = char.foregroundColor;
    Color backgroundColor = char.backgroundColor;

    // 处理反转样式
    if (char.style.reverse) {
      final temp = foregroundColor;
      foregroundColor = backgroundColor;
      backgroundColor = temp;
    }

    // 处理暗淡样式
    if (char.style.dim) {
      foregroundColor = Color.fromARGB(
        ((foregroundColor.a * 255.0) * 0.6).round() & 0xff,
        (foregroundColor.r * 255.0).round() & 0xff,
        (foregroundColor.g * 255.0).round() & 0xff,
        (foregroundColor.b * 255.0).round() & 0xff,
      );
    }

    // 绘制背景
    if (backgroundColor != ansi.AnsiColor.defaultBackground) {
      final backgroundPaint = Paint()..color = backgroundColor;
      canvas.drawRect(
        Rect.fromLTWH(x, y, displayWidth, _lineHeight),
        backgroundPaint,
      );
    }

    // 绘制字符 - 修复：确保空格字符也被正确渲染
    if (char.char.isNotEmpty) {
      final textStyle = TextStyle(
        fontSize: fontSize,
        fontFamily: fontFamily,
        color: foregroundColor,
        fontWeight: char.style.bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: char.style.italic ? FontStyle.italic : FontStyle.normal,
        decoration: _getTextDecoration(char.style),
        height: 1.2,
      );

      final textPainter = TextPainter(
        text: TextSpan(text: char.char, style: textStyle),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // 对于中文字符，居中显示
      final offsetX = charWidth == 2 ? x + (_charWidth - textPainter.width) / 2 : x;
      textPainter.paint(canvas, Offset(offsetX, y));
    }
  }

  /// 获取字符显示宽度
  int _getCharDisplayWidth(String char) {
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
  
  /// 获取文本装饰
  TextDecoration _getTextDecoration(ansi.TextStyle style) {
    final decorations = <TextDecoration>[];
    
    if (style.underline) {
      decorations.add(TextDecoration.underline);
    }
    
    if (style.strikethrough) {
      decorations.add(TextDecoration.lineThrough);
    }
    
    if (decorations.isEmpty) {
      return TextDecoration.none;
    } else if (decorations.length == 1) {
      return decorations.first;
    } else {
      return TextDecoration.combine(decorations);
    }
  }
  
  /// 绘制光标
  void _drawCursor(Canvas canvas) {
    final cursor = buffer.cursor;
    final x = cursor.col * _charWidth;
    final y = cursor.row * _lineHeight;

    final cursorPaint = Paint()
      ..color = ansi.AnsiColor.defaultForeground.withValues(alpha: cursorOpacity)
      ..style = PaintingStyle.fill;

    // 绘制块状光标
    canvas.drawRect(
      Rect.fromLTWH(x, y, _charWidth, _lineHeight),
      cursorPaint,
    );

    // 如果光标位置有字符，用反色绘制
    if (cursor.row < buffer.height && cursor.col < buffer.width) {
      final char = buffer.buffer[cursor.row][cursor.col];
      if (char.char.isNotEmpty) {
        final textStyle = TextStyle(
          fontSize: fontSize,
          fontFamily: fontFamily,
          color: ansi.AnsiColor.defaultBackground,
          fontWeight: char.style.bold ? FontWeight.bold : FontWeight.normal,
          fontStyle: char.style.italic ? FontStyle.italic : FontStyle.normal,
          decoration: _getTextDecoration(char.style),
          height: 1.2,
        );

        final textPainter = TextPainter(
          text: TextSpan(text: char.char, style: textStyle),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(canvas, Offset(x, y));
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant _TerminalPainter oldDelegate) {
    // 检查基本属性变化
    if (oldDelegate.buffer != buffer ||
        oldDelegate.cursorOpacity != cursorOpacity ||
        oldDelegate.showCursor != showCursor) {
      return true;
    }

    // 关键修复：检查光标位置是否改变
    if (oldDelegate.buffer.cursor.row != buffer.cursor.row ||
        oldDelegate.buffer.cursor.col != buffer.cursor.col) {
      return true;
    }

    return false;
  }
}

/// 终端滚动视图组件
class TerminalScrollView extends StatefulWidget {
  final TerminalBuffer buffer;
  final ScrollController? scrollController;
  final bool showCursor;
  final double fontSize;
  final String fontFamily;
  final VoidCallback? onTap;

  const TerminalScrollView({
    Key? key,
    required this.buffer,
    this.scrollController,
    this.showCursor = true,
    this.fontSize = 14.0,
    this.fontFamily = 'JetBrainsMono',
    this.onTap,
  }) : super(key: key);
  
  @override
  State<TerminalScrollView> createState() => _TerminalScrollViewState();
}

class _TerminalScrollViewState extends State<TerminalScrollView> {
  late final ScrollController _scrollController;
  bool _ownsController = false;
  bool _isUserScrolling = false;
  double _lastMaxScrollExtent = 0;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
      _ownsController = false;
    } else {
      _scrollController = ScrollController();
      _ownsController = true;
    }

    // 监听滚动事件，检测用户是否在手动滚动
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (_ownsController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  /// 监听滚动事件
  void _onScroll() {
    if (_scrollController.hasClients) {
      final currentOffset = _scrollController.offset;
      final maxExtent = _scrollController.position.maxScrollExtent;

      // 检测用户是否在手动滚动（不在底部）
      // 使用更大的容差，因为滚动可能不够精确
      _isUserScrolling = currentOffset < maxExtent - 50; // 50像素的容差

      // 如果用户滚动到底部附近，重置用户滚动状态
      if (currentOffset >= maxExtent - 20) {
        _isUserScrolling = false;
      }
    }
  }
  
  /// 滚动到底部
  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 检查是否需要自动滚动到底部
  void _checkAutoScroll() {
    if (_scrollController.hasClients) {
      final maxExtent = _scrollController.position.maxScrollExtent;

      // 如果内容高度发生变化，且用户没有手动滚动，则自动滚动到底部
      if (maxExtent != _lastMaxScrollExtent) {
        _lastMaxScrollExtent = maxExtent;

        // 在alternate screen模式下，总是自动滚动到底部
        // 在普通模式下，只有在用户没有手动滚动时才自动滚动
        final shouldAutoScroll = widget.buffer.isAlternateScreen || !_isUserScrolling;

        if (shouldAutoScroll && maxExtent > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients && mounted) {
              try {
                _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
              } catch (e) {
                // 如果jumpTo失败，尝试animateTo
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 50),
                  curve: Curves.easeOut,
                );
              }
            }
          });
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // 检查是否需要自动滚动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoScroll();
    });

    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          // 处理鼠标滚轮事件
          final delta = pointerSignal.scrollDelta.dy;
          if (_scrollController.hasClients) {
            final currentOffset = _scrollController.offset;
            final maxExtent = _scrollController.position.maxScrollExtent;
            final newOffset = (currentOffset + delta).clamp(0.0, maxExtent);

            // 如果用户向上滚动，标记为手动滚动
            if (delta > 0 && newOffset < maxExtent - 20) {
              _isUserScrolling = true;
            }
            // 如果用户滚动到底部，取消手动滚动标记
            else if (newOffset >= maxExtent - 20) {
              _isUserScrolling = false;
            }

            _scrollController.jumpTo(newOffset);
          }
        }
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        child: widget.buffer.isAlternateScreen
            ? TerminalRenderer(
                buffer: widget.buffer,
                showCursor: widget.showCursor,
                fontSize: widget.fontSize,
                fontFamily: widget.fontFamily,
                onTap: widget.onTap,
              )
            : _TerminalWithHistoryRenderer(
                buffer: widget.buffer,
                showCursor: widget.showCursor,
                fontSize: widget.fontSize,
                fontFamily: widget.fontFamily,
                onTap: widget.onTap,
              ),
      ),
    );
  }
}

/// 支持历史缓冲区的终端渲染器
class _TerminalWithHistoryRenderer extends StatelessWidget {
  final TerminalBuffer buffer;
  final bool showCursor;
  final double fontSize;
  final String fontFamily;
  final VoidCallback? onTap;

  const _TerminalWithHistoryRenderer({
    required this.buffer,
    this.showCursor = true,
    this.fontSize = 14.0,
    this.fontFamily = 'JetBrainsMono',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: ansi.AnsiColor.defaultBackground,
        child: CustomPaint(
          painter: _TerminalWithHistoryPainter(
            buffer: buffer,
            fontSize: fontSize,
            fontFamily: fontFamily,
            showCursor: showCursor,
          ),
          size: Size(
            buffer.width * _getCharWidth(),
            buffer.totalLineCount * _getLineHeight(),
          ),
        ),
      ),
    );
  }

  double _getCharWidth() {
    return fontSize * 0.6; // 近似字符宽度
  }

  double _getLineHeight() {
    return fontSize * 1.2; // 行高
  }
}

/// 支持历史缓冲区的终端画笔
class _TerminalWithHistoryPainter extends CustomPainter {
  final TerminalBuffer buffer;
  final double fontSize;
  final String fontFamily;
  final bool showCursor;

  _TerminalWithHistoryPainter({
    required this.buffer,
    required this.fontSize,
    required this.fontFamily,
    required this.showCursor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final charWidth = fontSize * 0.6;
    final lineHeight = fontSize * 1.2;

    // 绘制历史缓冲区内容
    for (int row = 0; row < buffer.historyLineCount; row++) {
      final line = buffer.getLine(row);
      if (line != null) {
        _drawLine(canvas, line, row, charWidth, lineHeight);
      }
    }

    // 绘制当前缓冲区内容
    for (int row = 0; row < buffer.height; row++) {
      final absoluteRow = buffer.historyLineCount + row;
      final line = buffer.buffer[row];
      _drawLine(canvas, line, absoluteRow, charWidth, lineHeight);
    }

    // 绘制光标（只在当前缓冲区中显示）
    if (showCursor) {
      final cursorRow = buffer.historyLineCount + buffer.cursor.row;
      final cursorX = buffer.cursor.col * charWidth;
      final cursorY = cursorRow * lineHeight;

      final cursorPaint = Paint()
        ..color = ansi.AnsiColor.defaultForeground
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(cursorX, cursorY, charWidth, lineHeight),
        cursorPaint,
      );
    }
  }

  void _drawLine(Canvas canvas, List<ansi.TerminalChar> line, int row, double charWidth, double lineHeight) {
    for (int col = 0; col < line.length && col < buffer.width; col++) {
      final char = line[col];
      if (char.char.isNotEmpty && char.char != ' ') {
        final x = col * charWidth;
        final y = row * lineHeight;

        _drawChar(canvas, char, x, y, charWidth, lineHeight);
      }
    }
  }

  void _drawChar(Canvas canvas, ansi.TerminalChar char, double x, double y, double charWidth, double lineHeight) {
    // 绘制背景
    if (char.backgroundColor != ansi.AnsiColor.defaultBackground) {
      final bgPaint = Paint()
        ..color = char.backgroundColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(x, y, charWidth, lineHeight), bgPaint);
    }

    // 绘制文字
    final textPainter = TextPainter(
      text: TextSpan(
        text: char.char,
        style: TextStyle(
          color: char.foregroundColor,
          fontSize: fontSize,
          fontFamily: fontFamily,
          fontWeight: char.style.bold ? FontWeight.bold : FontWeight.normal,
          fontStyle: char.style.italic ? FontStyle.italic : FontStyle.normal,
          decoration: char.style.underline ? TextDecoration.underline : TextDecoration.none,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // 总是重绘以确保内容更新
  }
}
