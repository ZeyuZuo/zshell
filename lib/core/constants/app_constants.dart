/// 应用常量定义
class AppConstants {
  // 应用信息
  static const String appName = 'ZShell';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'SSH连接管理工具';

  // 布局常量
  static const double sidebarWidth = 280.0;
  static const double sidebarMinWidth = 200.0;
  static const double sidebarMaxWidth = 400.0;
  
  // 动画时长
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  
  // 数据库
  static const String databaseName = 'zshell.db';
  static const int databaseVersion = 1;
  
  // 存储键名
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String windowSizeKey = 'window_size';
  
  // SSH连接
  static const int defaultSSHPort = 22;
  static const int connectionTimeout = 30; // 秒
  static const int maxRetryAttempts = 3;
}

/// 路由常量
class Routes {
  static const String hosts = '/hosts';
  static const String aiAssistant = '/ai-assistant';
  static const String commands = '/commands';
  static const String notes = '/notes';
  static const String settings = '/settings';
}

/// 数据库表名
class DatabaseTables {
  static const String hosts = 'hosts';
  static const String commands = 'commands';
  static const String notes = 'notes';
  static const String settings = 'settings';
}
