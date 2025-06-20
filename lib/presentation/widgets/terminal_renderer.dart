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

    // 绘制字符
    if (char.char.trim().isNotEmpty) {
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
      if (char.char.trim().isNotEmpty) {
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
    return oldDelegate.buffer != buffer ||
           oldDelegate.cursorOpacity != cursorOpacity ||
           oldDelegate.showCursor != showCursor;
  }
}

/// 终端滚动视图组件
class TerminalScrollView extends StatefulWidget {
  final TerminalBuffer buffer;
  final bool showCursor;
  final double fontSize;
  final String fontFamily;
  final VoidCallback? onTap;
  
  const TerminalScrollView({
    Key? key,
    required this.buffer,
    this.showCursor = true,
    this.fontSize = 14.0,
    this.fontFamily = 'JetBrainsMono',
    this.onTap,
  }) : super(key: key);
  
  @override
  State<TerminalScrollView> createState() => _TerminalScrollViewState();
}

class _TerminalScrollViewState extends State<TerminalScrollView> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
  
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          // 处理鼠标滚轮事件
          final delta = pointerSignal.scrollDelta.dy;
          if (_scrollController.hasClients) {
            final newOffset = (_scrollController.offset + delta).clamp(
              0.0,
              _scrollController.position.maxScrollExtent,
            );
            _scrollController.jumpTo(newOffset);
          }
        }
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        child: TerminalRenderer(
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
