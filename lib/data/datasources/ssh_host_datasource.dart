import 'package:sqflite/sqflite.dart';
import '../models/ssh_host.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import 'database_helper.dart';

/// SSH主机数据源
class SSHHostDataSource {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// 获取所有主机
  /// 从数据库查询所有活跃的SSH主机配置
  /// 返回按名称排序的主机列表
  Future<List<SSHHost>> getAllHosts() async {
    AppLogger.methodStart('SSHHostDataSource', 'getAllHosts');

    try {
      final db = await _databaseHelper.database;
      AppLogger.database('QUERY', 'Executing query to fetch all active hosts');

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseTables.hosts,
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );

      AppLogger.database('QUERY', 'Query returned ${maps.length} records');

      // 记录第一条记录的详细信息用于调试
      if (maps.isNotEmpty) {
        AppLogger.debug('First record data: ${maps.first}', tag: 'Database');
      }

      final hosts = <SSHHost>[];
      for (int i = 0; i < maps.length; i++) {
        try {
          final host = SSHHost.fromJson(maps[i]);
          hosts.add(host);
        } catch (e, stackTrace) {
          AppLogger.error(
            'Failed to parse host record at index $i: $e',
            tag: 'Database',
            error: e,
            stackTrace: stackTrace,
          );
          AppLogger.debug('Problematic record: ${maps[i]}', tag: 'Database');
          // 继续处理其他记录，不让一个错误记录影响整个列表
        }
      }

      AppLogger.database('PARSE', 'Successfully parsed ${hosts.length} hosts');
      AppLogger.methodEnd('SSHHostDataSource', 'getAllHosts', result: '${hosts.length} hosts');

      return hosts;

    } catch (e, stackTrace) {
      AppLogger.exception('SSHHostDataSource', 'getAllHosts', e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 根据ID获取主机
  Future<SSHHost?> getHostById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.hosts,
      where: 'id = ? AND is_active = ?',
      whereArgs: [id, 1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return SSHHost.fromJson(maps.first);
    }
    return null;
  }

  /// 搜索主机
  Future<List<SSHHost>> searchHosts(String query) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.hosts,
      where: '''
        is_active = ? AND (
          name LIKE ? OR 
          host LIKE ? OR 
          username LIKE ? OR 
          description LIKE ?
        )
      ''',
      whereArgs: [1, '%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return SSHHost.fromJson(maps[i]);
    });
  }

  /// 添加主机
  Future<String> insertHost(SSHHost host) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseTables.hosts,
      host.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return host.id;
  }

  /// 更新主机
  Future<int> updateHost(SSHHost host) async {
    final db = await _databaseHelper.database;
    return await db.update(
      DatabaseTables.hosts,
      host.toJson(),
      where: 'id = ?',
      whereArgs: [host.id],
    );
  }

  /// 删除主机（软删除）
  Future<int> deleteHost(String id) async {
    final db = await _databaseHelper.database;
    return await db.update(
      DatabaseTables.hosts,
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 永久删除主机
  Future<int> permanentDeleteHost(String id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      DatabaseTables.hosts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 检查主机名是否存在
  Future<bool> isHostNameExists(String name, {String? excludeId}) async {
    final db = await _databaseHelper.database;
    String whereClause = 'name = ? AND is_active = ?';
    List<dynamic> whereArgs = [name, 1];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.hosts,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  /// 检查主机地址是否存在
  Future<bool> isHostAddressExists(String host, int port, {String? excludeId}) async {
    final db = await _databaseHelper.database;
    String whereClause = 'host = ? AND port = ? AND is_active = ?';
    List<dynamic> whereArgs = [host, port, 1];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.hosts,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  /// 获取主机统计信息
  Future<Map<String, int>> getHostStats() async {
    final db = await _databaseHelper.database;
    
    // 总主机数
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseTables.hosts} WHERE is_active = ?',
      [1],
    );
    final totalHosts = totalResult.first['count'] as int;

    // 最近添加的主机数（7天内）
    final recentDate = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    final recentResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseTables.hosts} WHERE is_active = ? AND created_at > ?',
      [1, recentDate],
    );
    final recentHosts = recentResult.first['count'] as int;

    return {
      'total': totalHosts,
      'recent': recentHosts,
    };
  }

  /// 批量导入主机
  Future<List<String>> batchInsertHosts(List<SSHHost> hosts) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();
    final insertedIds = <String>[];

    for (final host in hosts) {
      batch.insert(
        DatabaseTables.hosts,
        host.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      insertedIds.add(host.id);
    }

    await batch.commit(noResult: true);
    return insertedIds;
  }

  /// 导出主机配置
  Future<List<Map<String, dynamic>>> exportHosts() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.hosts,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    // 移除敏感信息
    return maps.map((map) {
      final exportMap = Map<String, dynamic>.from(map);
      exportMap.remove('password'); // 不导出密码
      return exportMap;
    }).toList();
  }

  /// 获取最近使用的主机
  Future<List<SSHHost>> getRecentlyUsedHosts({int limit = 5}) async {
    final db = await _databaseHelper.database;
    
    // 通过SSH会话表获取最近使用的主机
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT h.* FROM ${DatabaseTables.hosts} h
      INNER JOIN ssh_sessions s ON h.id = s.host_id
      WHERE h.is_active = 1
      ORDER BY s.start_time DESC
      LIMIT ?
    ''', [limit]);

    return List.generate(maps.length, (i) {
      return SSHHost.fromJson(maps[i]);
    });
  }
}
