/// 验证工具类
class ValidationUtils {
  /// 验证ID格式
  static bool isValidId(String id) {
    return id.isNotEmpty && id.length >= 3;
  }

  /// 验证主机地址
  static bool isValidHost(String host) {
    if (host.isEmpty) return false;
    
    // 检查是否为IP地址
    if (isValidIPAddress(host)) return true;
    
    // 检查是否为域名
    if (isValidDomainName(host)) return true;
    
    return false;
  }

  /// 验证IP地址
  static bool isValidIPAddress(String ip) {
    final ipv4Pattern = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');
    final match = ipv4Pattern.firstMatch(ip);
    
    if (match == null) return false;
    
    for (int i = 1; i <= 4; i++) {
      final octet = int.tryParse(match.group(i)!);
      if (octet == null || octet < 0 || octet > 255) {
        return false;
      }
    }
    
    return true;
  }

  /// 验证域名
  static bool isValidDomainName(String domain) {
    if (domain.isEmpty || domain.length > 253) return false;
    
    final domainPattern = RegExp(
      r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$'
    );
    
    return domainPattern.hasMatch(domain);
  }

  /// 验证端口号
  static bool isValidPort(int port) {
    return port >= 1 && port <= 65535;
  }

  /// 验证用户名
  static bool isValidUsername(String username) {
    if (username.isEmpty || username.length > 32) return false;
    
    // 用户名只能包含字母、数字、下划线、连字符
    final usernamePattern = RegExp(r'^[a-zA-Z0-9_-]+$');
    return usernamePattern.hasMatch(username);
  }

  /// 验证密码强度
  static PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.empty;
    if (password.length < 6) return PasswordStrength.weak;
    
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    int score = 0;
    if (hasLower) score++;
    if (hasUpper) score++;
    if (hasDigit) score++;
    if (hasSpecial) score++;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  /// 验证邮箱地址
  static bool isValidEmail(String email) {
    final emailPattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    return emailPattern.hasMatch(email);
  }

  /// 验证文件路径
  static bool isValidFilePath(String path) {
    if (path.isEmpty) return false;
    
    // 检查是否包含非法字符
    final invalidChars = RegExp(r'[<>:"|?*]');
    return !invalidChars.hasMatch(path);
  }

  /// 验证命令名称
  static bool isValidCommandName(String name) {
    if (name.isEmpty || name.length > 100) return false;
    
    // 命令名称不能包含特殊字符
    final commandPattern = RegExp(r'^[a-zA-Z0-9\s\-_()]+$');
    return commandPattern.hasMatch(name);
  }

  /// 验证标签名称
  static bool isValidTagName(String tag) {
    if (tag.isEmpty || tag.length > 50) return false;
    
    // 标签只能包含字母、数字、中文、下划线、连字符
    final tagPattern = RegExp(r'^[\u4e00-\u9fa5a-zA-Z0-9_-]+$');
    return tagPattern.hasMatch(tag);
  }

  /// 验证笔记标题
  static bool isValidNoteTitle(String title) {
    if (title.isEmpty || title.length > 200) return false;
    
    // 标题不能只包含空白字符
    return title.trim().isNotEmpty;
  }

  /// 验证SSH私钥文件路径
  static bool isValidSSHKeyPath(String path) {
    if (!isValidFilePath(path)) return false;
    
    // 检查是否为常见的SSH私钥文件扩展名
    final keyExtensions = ['.pem', '.key', '.ppk', ''];
    final extension = path.contains('.') ? path.substring(path.lastIndexOf('.')) : '';
    
    return keyExtensions.contains(extension) || path.contains('id_rsa') || path.contains('id_ed25519');
  }

  /// 清理和标准化输入
  static String sanitizeInput(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// 验证JSON格式
  static bool isValidJson(String jsonString) {
    try {
      // 这里可以使用dart:convert的jsonDecode来验证
      return jsonString.isNotEmpty && 
             (jsonString.startsWith('{') && jsonString.endsWith('}')) ||
             (jsonString.startsWith('[') && jsonString.endsWith(']'));
    } catch (e) {
      return false;
    }
  }
}

/// 密码强度枚举
enum PasswordStrength {
  empty('空', 0),
  weak('弱', 1),
  medium('中等', 2),
  strong('强', 3);

  const PasswordStrength(this.displayName, this.score);
  final String displayName;
  final int score;
}
