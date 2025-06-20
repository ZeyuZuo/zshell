import 'package:sqflite/sqflite.dart';
import '../models/command.dart';
import '../../core/constants/app_constants.dart';
import 'database_helper.dart';

/// 快捷指令数据源
class CommandDataSource {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// 获取所有指令
  Future<List<Command>> getAllCommands() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.commands,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'usage_count DESC, name ASC',
    );

    return List.generate(maps.length, (i) {
      return Command.fromJson(maps[i]);
    });
  }

  /// 根据分类获取指令
  Future<List<Command>> getCommandsByCategory(String category) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.commands,
      where: 'category = ? AND is_active = ?',
      whereArgs: [category, 1],
      orderBy: 'usage_count DESC, name ASC',
    );

    return List.generate(maps.length, (i) {
      return Command.fromJson(maps[i]);
    });
  }

  /// 根据ID获取指令
  Future<Command?> getCommandById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.commands,
      where: 'id = ? AND is_active = ?',
      whereArgs: [id, 1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Command.fromJson(maps.first);
    }
    return null;
  }

  /// 搜索指令
  Future<List<Command>> searchCommands(String query) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.commands,
      where: '''
        is_active = ? AND (
          name LIKE ? OR 
          command LIKE ? OR 
          description LIKE ? OR 
          tags LIKE ?
        )
      ''',
      whereArgs: [1, '%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'usage_count DESC, name ASC',
    );

    return List.generate(maps.length, (i) {
      return Command.fromJson(maps[i]);
    });
  }

  /// 添加指令
  Future<String> insertCommand(Command command) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseTables.commands,
      command.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return command.id;
  }

  /// 更新指令
  Future<int> updateCommand(Command command) async {
    final db = await _databaseHelper.database;
    return await db.update(
      DatabaseTables.commands,
      command.toJson(),
      where: 'id = ?',
      whereArgs: [command.id],
    );
  }

  /// 删除指令（软删除）
  Future<int> deleteCommand(String id) async {
    final db = await _databaseHelper.database;
    return await db.update(
      DatabaseTables.commands,
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 增加指令使用次数
  Future<int> incrementUsageCount(String id) async {
    final db = await _databaseHelper.database;
    return await db.rawUpdate('''
      UPDATE ${DatabaseTables.commands} 
      SET usage_count = usage_count + 1, updated_at = ?
      WHERE id = ?
    ''', [DateTime.now().toIso8601String(), id]);
  }

  /// 获取所有分类
  Future<List<String>> getAllCategories() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT category FROM ${DatabaseTables.commands} 
      WHERE is_active = ? 
      ORDER BY category ASC
    ''', [1]);

    return maps.map((map) => map['category'] as String).toList();
  }

  /// 获取所有标签
  Future<List<String>> getAllTags() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.commands,
      columns: ['tags'],
      where: 'is_active = ? AND tags IS NOT NULL AND tags != ""',
      whereArgs: [1],
    );

    final Set<String> allTags = {};
    for (final map in maps) {
      final tags = (map['tags'] as String?)?.split(',') ?? [];
      allTags.addAll(tags.where((tag) => tag.trim().isNotEmpty));
    }

    return allTags.toList()..sort();
  }

  /// 获取最常用的指令
  Future<List<Command>> getMostUsedCommands({int limit = 10}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.commands,
      where: 'is_active = ? AND usage_count > 0',
      whereArgs: [1],
      orderBy: 'usage_count DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return Command.fromJson(maps[i]);
    });
  }

  /// 获取最近添加的指令
  Future<List<Command>> getRecentCommands({int limit = 10}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.commands,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return Command.fromJson(maps[i]);
    });
  }

  /// 检查指令名称是否存在
  Future<bool> isCommandNameExists(String name, {String? excludeId}) async {
    final db = await _databaseHelper.database;
    String whereClause = 'name = ? AND is_active = ?';
    List<dynamic> whereArgs = [name, 1];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.commands,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  /// 获取指令统计信息
  Future<Map<String, dynamic>> getCommandStats() async {
    final db = await _databaseHelper.database;
    
    // 总指令数
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseTables.commands} WHERE is_active = ?',
      [1],
    );
    final totalCommands = totalResult.first['count'] as int;

    // 分类统计
    final categoryResult = await db.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM ${DatabaseTables.commands} 
      WHERE is_active = ? 
      GROUP BY category 
      ORDER BY count DESC
    ''', [1]);

    // 使用统计
    final usageResult = await db.rawQuery('''
      SELECT SUM(usage_count) as total_usage, AVG(usage_count) as avg_usage
      FROM ${DatabaseTables.commands} 
      WHERE is_active = ?
    ''', [1]);

    return {
      'total': totalCommands,
      'categories': categoryResult,
      'totalUsage': usageResult.first['total_usage'] ?? 0,
      'averageUsage': usageResult.first['avg_usage'] ?? 0.0,
    };
  }

  /// 批量导入指令
  Future<List<String>> batchInsertCommands(List<Command> commands) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();
    final insertedIds = <String>[];

    for (final command in commands) {
      batch.insert(
        DatabaseTables.commands,
        command.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      insertedIds.add(command.id);
    }

    await batch.commit(noResult: true);
    return insertedIds;
  }

  /// 导出指令
  Future<List<Map<String, dynamic>>> exportCommands() async {
    final db = await _databaseHelper.database;
    return await db.query(
      DatabaseTables.commands,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'category ASC, name ASC',
    );
  }

  /// 重置使用统计
  Future<int> resetUsageStats() async {
    final db = await _databaseHelper.database;
    return await db.update(
      DatabaseTables.commands,
      {
        'usage_count': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'is_active = ?',
      whereArgs: [1],
    );
  }
}
