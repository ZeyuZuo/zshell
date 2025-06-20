import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';

/// 数据库帮助类
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  /// 获取数据库实例
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 创建SSH主机表
    await db.execute('''
      CREATE TABLE ${DatabaseTables.hosts} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        host TEXT NOT NULL,
        port INTEGER NOT NULL DEFAULT 22,
        username TEXT NOT NULL,
        password TEXT,
        private_key_path TEXT,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 创建快捷指令表
    await db.execute('''
      CREATE TABLE ${DatabaseTables.commands} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        command TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        tags TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        usage_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 创建笔记表
    await db.execute('''
      CREATE TABLE ${DatabaseTables.notes} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        tags TEXT,
        host_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (host_id) REFERENCES ${DatabaseTables.hosts} (id)
      )
    ''');

    // 创建应用设置表
    await db.execute('''
      CREATE TABLE ${DatabaseTables.settings} (
        id TEXT PRIMARY KEY,
        theme_mode INTEGER NOT NULL DEFAULT 0,
        language TEXT NOT NULL DEFAULT 'zh_CN',
        connection_timeout INTEGER NOT NULL DEFAULT 30,
        max_retry_attempts INTEGER NOT NULL DEFAULT 3,
        auto_lock INTEGER NOT NULL DEFAULT 0,
        auto_lock_timeout INTEGER NOT NULL DEFAULT 15,
        enable_logging INTEGER NOT NULL DEFAULT 1,
        default_terminal TEXT NOT NULL DEFAULT 'system',
        enable_notifications INTEGER NOT NULL DEFAULT 1,
        enable_auto_backup INTEGER NOT NULL DEFAULT 0,
        backup_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 创建SSH会话表
    await db.execute('''
      CREATE TABLE ssh_sessions (
        id TEXT PRIMARY KEY,
        host_id TEXT NOT NULL,
        session_name TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        status TEXT NOT NULL,
        last_command TEXT,
        last_activity TEXT,
        command_count INTEGER NOT NULL DEFAULT 0,
        error_message TEXT,
        FOREIGN KEY (host_id) REFERENCES ${DatabaseTables.hosts} (id)
      )
    ''');

    // 创建命令历史表
    await db.execute('''
      CREATE TABLE command_history (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        command TEXT NOT NULL,
        output TEXT,
        exit_code INTEGER NOT NULL,
        executed_at TEXT NOT NULL,
        execution_time_ms INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES ssh_sessions (id)
      )
    ''');

    // 创建索引
    await _createIndexes(db);

    // 插入默认数据
    await _insertDefaultData(db);
  }

  /// 创建索引
  Future<void> _createIndexes(Database db) async {
    // 主机表索引
    await db.execute('CREATE INDEX idx_hosts_name ON ${DatabaseTables.hosts} (name)');
    await db.execute('CREATE INDEX idx_hosts_host ON ${DatabaseTables.hosts} (host)');
    await db.execute('CREATE INDEX idx_hosts_active ON ${DatabaseTables.hosts} (is_active)');

    // 指令表索引
    await db.execute('CREATE INDEX idx_commands_category ON ${DatabaseTables.commands} (category)');
    await db.execute('CREATE INDEX idx_commands_active ON ${DatabaseTables.commands} (is_active)');
    await db.execute('CREATE INDEX idx_commands_usage ON ${DatabaseTables.commands} (usage_count DESC)');

    // 笔记表索引
    await db.execute('CREATE INDEX idx_notes_title ON ${DatabaseTables.notes} (title)');
    await db.execute('CREATE INDEX idx_notes_host ON ${DatabaseTables.notes} (host_id)');
    await db.execute('CREATE INDEX idx_notes_active ON ${DatabaseTables.notes} (is_active)');
    await db.execute('CREATE INDEX idx_notes_pinned ON ${DatabaseTables.notes} (is_pinned DESC)');

    // 会话表索引
    await db.execute('CREATE INDEX idx_sessions_host ON ssh_sessions (host_id)');
    await db.execute('CREATE INDEX idx_sessions_status ON ssh_sessions (status)');
    await db.execute('CREATE INDEX idx_sessions_start_time ON ssh_sessions (start_time DESC)');

    // 命令历史表索引
    await db.execute('CREATE INDEX idx_history_session ON command_history (session_id)');
    await db.execute('CREATE INDEX idx_history_executed_at ON command_history (executed_at DESC)');
  }

  /// 插入默认数据
  Future<void> _insertDefaultData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // 插入默认设置
    await db.insert(DatabaseTables.settings, {
      'id': 'default',
      'created_at': now,
      'updated_at': now,
    });

    // 插入示例主机
    await db.insert(DatabaseTables.hosts, {
      'id': 'example-host-1',
      'name': '示例服务器',
      'host': '192.168.1.100',
      'port': 22,
      'username': 'root',
      'description': '这是一个示例SSH主机配置',
      'created_at': now,
      'updated_at': now,
    });

    // 插入示例指令
    final sampleCommands = [
      {
        'id': 'cmd-1',
        'name': '查看系统信息',
        'command': 'uname -a',
        'description': '显示系统的详细信息',
        'category': '系统管理',
        'tags': '系统,信息',
      },
      {
        'id': 'cmd-2',
        'name': '查看磁盘使用',
        'command': 'df -h',
        'description': '以人性化格式显示磁盘使用情况',
        'category': '系统管理',
        'tags': '磁盘,存储',
      },
      {
        'id': 'cmd-3',
        'name': '列出文件',
        'command': 'ls -la',
        'description': '显示目录中所有文件的详细信息',
        'category': '文件操作',
        'tags': '文件,列表',
      },
    ];

    for (final cmd in sampleCommands) {
      await db.insert(DatabaseTables.commands, {
        ...cmd,
        'created_at': now,
        'updated_at': now,
      });
    }

    // 插入示例笔记
    await db.insert(DatabaseTables.notes, {
      'id': 'note-1',
      'title': '服务器维护记录',
      'content': '记录服务器日常维护的相关操作和注意事项...',
      'tags': '运维,维护',
      'host_id': 'example-host-1',
      'created_at': now,
      'updated_at': now,
    });
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 根据版本进行数据库升级
    if (oldVersion < 2) {
      // 版本2的升级逻辑
    }
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// 清空所有数据
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(DatabaseTables.hosts);
    await db.delete(DatabaseTables.commands);
    await db.delete(DatabaseTables.notes);
    await db.delete('ssh_sessions');
    await db.delete('command_history');
  }

  /// 备份数据库
  Future<String> backupDatabase() async {
    final db = await database;
    final path = db.path;
    // TODO: 实现数据库备份逻辑
    return path;
  }

  /// 恢复数据库
  Future<void> restoreDatabase(String backupPath) async {
    // TODO: 实现数据库恢复逻辑
  }
}
