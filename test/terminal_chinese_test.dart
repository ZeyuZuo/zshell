import 'package:flutter_test/flutter_test.dart';
import 'package:zshell/core/terminal/terminal_buffer.dart';

void main() {
  group('中文字符处理测试', () {
    test('中文字符宽度计算', () {
      final buffer = TerminalBuffer(width: 10, height: 5);
      
      // 写入中文字符
      buffer.write('表名.sql');
      
      // 检查光标位置 - "表名.sql" = 2 + 2 + 1 + 3 = 8个字符位置
      expect(buffer.cursor.col, equals(8));
      
      // 检查第一行内容
      final line = buffer.getLineText(0);
      expect(line, contains('表名.sql'));
    });

    test('中文字符换行处理', () {
      final buffer = TerminalBuffer(width: 6, height: 5);
      
      // 写入会导致换行的中文内容
      buffer.write('表名很长.sql');
      
      // 应该在合适的位置换行
      expect(buffer.cursor.row, greaterThan(0));
    });

    test('混合中英文处理', () {
      final buffer = TerminalBuffer(width: 25, height: 5);

      // 写入混合内容
      buffer.write('user@host:~# ls 表名.sql');

      // 检查内容正确显示
      final line = buffer.getLineText(0);
      expect(line, contains('表名'));
      expect(line, contains('.sql'));
    });

    test('ANSI颜色序列与中文字符', () {
      final buffer = TerminalBuffer(width: 20, height: 5);
      
      // 模拟带颜色的中文输出
      buffer.write('\x1b[01;34m表名\x1b[0m.sql');
      
      // 检查内容正确显示
      final line = buffer.getLineText(0);
      expect(line, contains('表名.sql'));
    });

    test('提示符重复问题测试', () {
      final buffer = TerminalBuffer(width: 80, height: 24);
      
      // 模拟可能导致重复的输出序列
      buffer.write('user@host:~# ');
      buffer.write('\r\n');
      buffer.write('user@host:~# ');
      
      // 检查不应该有重复的提示符在同一行
      final lines = <String>[];
      for (int i = 0; i < buffer.height; i++) {
        final line = buffer.getLineText(i);
        if (line.isNotEmpty) {
          lines.add(line);
        }
      }
      
      // 应该有两行，每行一个提示符
      expect(lines.length, equals(2));
      expect(lines[0], contains('user@host:~#'));
      expect(lines[1], contains('user@host:~#'));
    });
  });
}
