import 'dart:math';

/// UUID生成器
class UuidGenerator {
  static final Random _random = Random();

  /// 生成UUID v4
  static String generate() {
    // 生成32个十六进制字符
    final bytes = List<int>.generate(16, (i) => _random.nextInt(256));
    
    // 设置版本号为4
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // 设置变体
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    // 转换为十六进制字符串
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    
    // 添加连字符
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// 生成短UUID（8位）
  static String generateShort() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(8, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  /// 验证UUID格式
  static bool isValid(String uuid) {
    final pattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', caseSensitive: false);
    return pattern.hasMatch(uuid);
  }
}
