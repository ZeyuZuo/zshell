import 'package:flutter_test/flutter_test.dart';
import 'package:zshell/core/terminal/ansi_parser.dart';

void main() {
  group('AnsiParser Tests', () {
    late AnsiParser parser;

    setUp(() {
      parser = AnsiParser();
    });

    test('解析普通文本', () {
      const text = 'Hello World';
      final result = parser.parse(text);
      
      expect(result.chars.length, equals(11));
      expect(result.chars[0].char, equals('H'));
      expect(result.chars[0].foregroundColor, equals(AnsiColor.defaultForeground));
      expect(result.commands.length, equals(0));
    });

    test('解析ANSI颜色序列', () {
      const text = '\x1b[01;34mblue text\x1b[0m';
      final result = parser.parse(text);
      
      // 应该有两个命令：设置颜色和重置
      expect(result.commands.length, equals(2));
      expect(result.commands[0].type, equals(AnsiCommandType.setGraphicsMode));
      expect(result.commands[0].parameters, equals([1, 34])); // 粗体 + 蓝色
      expect(result.commands[1].type, equals(AnsiCommandType.setGraphicsMode));
      expect(result.commands[1].parameters, equals([0])); // 重置
    });

    test('解析光标移动序列', () {
      const text = '\x1b[A\x1b[B\x1b[C\x1b[D';
      final result = parser.parse(text);
      
      expect(result.commands.length, equals(4));
      expect(result.commands[0].type, equals(AnsiCommandType.cursorUp));
      expect(result.commands[1].type, equals(AnsiCommandType.cursorDown));
      expect(result.commands[2].type, equals(AnsiCommandType.cursorForward));
      expect(result.commands[3].type, equals(AnsiCommandType.cursorBack));
    });

    test('解析清屏序列', () {
      const text = '\x1b[2J\x1b[H';
      final result = parser.parse(text);
      
      expect(result.commands.length, equals(2));
      expect(result.commands[0].type, equals(AnsiCommandType.clearScreen));
      expect(result.commands[0].parameters, equals([2]));
      expect(result.commands[1].type, equals(AnsiCommandType.cursorPosition));
    });

    test('解析混合内容', () {
      const text = 'Normal \x1b[31mRed\x1b[0m Normal';
      final result = parser.parse(text);

      // 检查字符数量 - "Normal Red Normal" = 7 + 1 + 3 + 1 + 6 = 18
      expect(result.chars.length, equals(18));

      // 检查命令数量
      expect(result.commands.length, equals(2)); // 设置红色和重置

      // 检查第一个命令是设置红色
      expect(result.commands[0].type, equals(AnsiCommandType.setGraphicsMode));
      expect(result.commands[0].parameters, equals([31]));
    });

    test('处理无效ANSI序列', () {
      const text = 'Normal \x1b[invalid text';
      final result = parser.parse(text);
      
      // 无效序列应该被当作普通字符处理
      expect(result.chars.length, equals(text.length));
      expect(result.commands.length, equals(0));
    });

    test('解析复杂的ls输出示例', () {
      // 模拟ls --color输出中的一个文件名
      const text = '\x1b[01;34mcrawl\x1b[0m';
      final result = parser.parse(text);
      
      // 应该有"crawl"这5个字符
      expect(result.chars.length, equals(5));
      expect(result.chars.map((c) => c.char).join(), equals('crawl'));
      
      // 应该有两个命令：设置样式和重置
      expect(result.commands.length, equals(2));
      expect(result.commands[0].parameters, equals([1, 34])); // 粗体蓝色
      expect(result.commands[1].parameters, equals([0])); // 重置
    });
  });


}
