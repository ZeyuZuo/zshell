import '../models/ssh_host.dart';
import '../datasources/ssh_host_datasource.dart';
import '../../core/utils/uuid_generator.dart';
import '../../core/utils/validation_utils.dart';
import '../../core/utils/logger.dart';

/// SSH主机仓库
class SSHHostRepository {
  final SSHHostDataSource _dataSource = SSHHostDataSource();

  /// 获取所有主机
  /// 从数据源获取所有SSH主机配置
  /// 返回主机列表，如果出错则抛出异常
  Future<List<SSHHost>> getAllHosts() async {
    AppLogger.methodStart('SSHHostRepository', 'getAllHosts');
    final monitor = PerformanceMonitor('getAllHosts');

    try {
      AppLogger.database('SELECT', 'Fetching all SSH hosts from database');
      final hosts = await _dataSource.getAllHosts();

      AppLogger.database('SELECT', 'Successfully fetched ${hosts.length} hosts');
      AppLogger.methodEnd('SSHHostRepository', 'getAllHosts', result: '${hosts.length} hosts');

      monitor.end(additionalMetrics: {'host_count': hosts.length});
      return hosts;

    } catch (e, stackTrace) {
      AppLogger.exception('SSHHostRepository', 'getAllHosts', e, stackTrace: stackTrace);
      monitor.end(additionalMetrics: {'error': e.toString()});
      throw Exception('获取主机列表失败: $e');
    }
  }

  /// 根据ID获取主机
  Future<SSHHost?> getHostById(String id) async {
    try {
      if (!ValidationUtils.isValidId(id)) {
        throw ArgumentError('无效的主机ID');
      }
      return await _dataSource.getHostById(id);
    } catch (e) {
      throw Exception('获取主机信息失败: $e');
    }
  }

  /// 搜索主机
  Future<List<SSHHost>> searchHosts(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllHosts();
      }
      return await _dataSource.searchHosts(query.trim());
    } catch (e) {
      throw Exception('搜索主机失败: $e');
    }
  }

  /// 添加主机
  Future<SSHHost> addHost({
    required String name,
    required String host,
    required int port,
    required String username,
    String? password,
    String? privateKeyPath,
    String? description,
  }) async {
    try {
      // 验证输入
      _validateHostInput(name, host, port, username);

      // 检查主机名是否已存在
      if (await _dataSource.isHostNameExists(name)) {
        throw Exception('主机名 "$name" 已存在');
      }

      // 检查主机地址是否已存在
      if (await _dataSource.isHostAddressExists(host, port)) {
        throw Exception('主机地址 "$host:$port" 已存在');
      }

      final now = DateTime.now();
      final sshHost = SSHHost(
        id: UuidGenerator.generate(),
        name: name.trim(),
        host: host.trim(),
        port: port,
        username: username.trim(),
        password: password?.trim(),
        privateKeyPath: privateKeyPath?.trim(),
        description: description?.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await _dataSource.insertHost(sshHost);
      return sshHost;
    } catch (e) {
      throw Exception('添加主机失败: $e');
    }
  }

  /// 更新主机
  Future<SSHHost> updateHost({
    required String id,
    required String name,
    required String host,
    required int port,
    required String username,
    String? password,
    String? privateKeyPath,
    String? description,
  }) async {
    try {
      // 验证输入
      if (!ValidationUtils.isValidId(id)) {
        throw ArgumentError('无效的主机ID');
      }
      _validateHostInput(name, host, port, username);

      // 获取原主机信息
      final existingHost = await _dataSource.getHostById(id);
      if (existingHost == null) {
        throw Exception('主机不存在');
      }

      // 检查主机名是否已存在（排除当前主机）
      if (await _dataSource.isHostNameExists(name, excludeId: id)) {
        throw Exception('主机名 "$name" 已存在');
      }

      // 检查主机地址是否已存在（排除当前主机）
      if (await _dataSource.isHostAddressExists(host, port, excludeId: id)) {
        throw Exception('主机地址 "$host:$port" 已存在');
      }

      final updatedHost = existingHost.copyWith(
        name: name.trim(),
        host: host.trim(),
        port: port,
        username: username.trim(),
        password: password?.trim(),
        privateKeyPath: privateKeyPath?.trim(),
        description: description?.trim(),
        updatedAt: DateTime.now(),
      );

      await _dataSource.updateHost(updatedHost);
      return updatedHost;
    } catch (e) {
      throw Exception('更新主机失败: $e');
    }
  }

  /// 删除主机
  Future<void> deleteHost(String id) async {
    try {
      if (!ValidationUtils.isValidId(id)) {
        throw ArgumentError('无效的主机ID');
      }

      final host = await _dataSource.getHostById(id);
      if (host == null) {
        throw Exception('主机不存在');
      }

      await _dataSource.deleteHost(id);
    } catch (e) {
      throw Exception('删除主机失败: $e');
    }
  }

  /// 测试主机连接
  Future<bool> testConnection(String id) async {
    try {
      final host = await _dataSource.getHostById(id);
      if (host == null) {
        throw Exception('主机不存在');
      }

      // TODO: 实现实际的SSH连接测试
      // 这里暂时返回模拟结果
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      throw Exception('测试连接失败: $e');
    }
  }

  /// 获取主机统计信息
  Future<Map<String, int>> getHostStats() async {
    try {
      return await _dataSource.getHostStats();
    } catch (e) {
      throw Exception('获取主机统计失败: $e');
    }
  }

  /// 批量导入主机
  Future<List<SSHHost>> importHosts(List<Map<String, dynamic>> hostData) async {
    try {
      final hosts = <SSHHost>[];
      final now = DateTime.now();

      for (final data in hostData) {
        // 验证数据
        final name = data['name'] as String?;
        final host = data['host'] as String?;
        final port = data['port'] as int? ?? 22;
        final username = data['username'] as String?;

        if (name == null || host == null || username == null) {
          continue; // 跳过无效数据
        }

        _validateHostInput(name, host, port, username);

        // 检查是否已存在
        if (await _dataSource.isHostNameExists(name) ||
            await _dataSource.isHostAddressExists(host, port)) {
          continue; // 跳过已存在的主机
        }

        final sshHost = SSHHost(
          id: UuidGenerator.generate(),
          name: name.trim(),
          host: host.trim(),
          port: port,
          username: username.trim(),
          password: (data['password'] as String?)?.trim(),
          privateKeyPath: (data['private_key_path'] as String?)?.trim(),
          description: (data['description'] as String?)?.trim(),
          createdAt: now,
          updatedAt: now,
        );

        hosts.add(sshHost);
      }

      if (hosts.isNotEmpty) {
        await _dataSource.batchInsertHosts(hosts);
      }

      return hosts;
    } catch (e) {
      throw Exception('导入主机失败: $e');
    }
  }

  /// 导出主机配置
  Future<List<Map<String, dynamic>>> exportHosts() async {
    try {
      return await _dataSource.exportHosts();
    } catch (e) {
      throw Exception('导出主机配置失败: $e');
    }
  }

  /// 获取最近使用的主机
  Future<List<SSHHost>> getRecentlyUsedHosts({int limit = 5}) async {
    try {
      return await _dataSource.getRecentlyUsedHosts(limit: limit);
    } catch (e) {
      throw Exception('获取最近使用的主机失败: $e');
    }
  }

  /// 验证主机输入
  void _validateHostInput(String name, String host, int port, String username) {
    if (name.trim().isEmpty) {
      throw ArgumentError('主机名不能为空');
    }

    if (host.trim().isEmpty) {
      throw ArgumentError('主机地址不能为空');
    }

    if (!ValidationUtils.isValidHost(host)) {
      throw ArgumentError('主机地址格式无效');
    }

    if (!ValidationUtils.isValidPort(port)) {
      throw ArgumentError('端口号必须在1-65535之间');
    }

    if (username.trim().isEmpty) {
      throw ArgumentError('用户名不能为空');
    }

    if (!ValidationUtils.isValidUsername(username)) {
      throw ArgumentError('用户名格式无效');
    }
  }
}
