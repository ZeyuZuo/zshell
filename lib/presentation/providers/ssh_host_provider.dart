import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/models/ssh_host.dart';
import '../../data/repositories/ssh_host_repository.dart';
import '../../core/services/connection_service.dart';
import '../../core/utils/logger.dart';

/// SSH主机状态管理Provider
/// 负责管理SSH主机列表的状态，包括：
/// - 主机数据的加载、搜索、筛选
/// - 连接状态的监控和更新
/// - 用户界面状态的管理（加载、错误等）
/// - 与数据层和服务层的交互
class SSHHostProvider extends ChangeNotifier {
  final SSHHostRepository _repository = SSHHostRepository();
  final ConnectionService _connectionService = ConnectionService();

  List<SSHHost> _hosts = [];
  List<SSHHost> _filteredHosts = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = '全部';
  Map<String, bool> _connectionStates = {};
  StreamSubscription<Map<String, bool>>? _connectionSubscription;

  // Getters
  List<SSHHost> get hosts => _filteredHosts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get hasHosts => _hosts.isNotEmpty;
  int get totalHosts => _hosts.length;
  Map<String, bool> get connectionStates => _connectionStates;

  /// 获取主机连接状态
  bool getHostConnectionState(String hostId) {
    return _connectionStates[hostId] ?? false;
  }

  /// 初始化加载主机列表
  /// 从Repository获取所有主机数据并启动连接监控
  /// 这是Provider的主要入口方法，通常在页面初始化时调用
  Future<void> loadHosts() async {
    AppLogger.methodStart('SSHHostProvider', 'loadHosts');
    final monitor = PerformanceMonitor('loadHosts');

    _setLoading(true);
    _clearError();

    try {
      AppLogger.info('Starting to load SSH hosts', tag: 'Provider');

      // 从Repository获取主机数据
      _hosts = await _repository.getAllHosts();
      AppLogger.info('Loaded ${_hosts.length} hosts from repository', tag: 'Provider');

      // 应用当前的筛选条件
      _applyFilters();
      AppLogger.debug('Applied filters, ${_filteredHosts.length} hosts visible', tag: 'Provider');

      // 启动连接状态监控
      _startConnectionMonitoring();
      AppLogger.info('Started connection monitoring for ${_hosts.length} hosts', tag: 'Provider');

      AppLogger.methodEnd('SSHHostProvider', 'loadHosts',
          result: 'Success: ${_hosts.length} hosts loaded');

    } catch (e, stackTrace) {
      AppLogger.exception('SSHHostProvider', 'loadHosts', e, stackTrace: stackTrace);
      _setError('加载主机列表失败: $e');
    } finally {
      _setLoading(false);
      monitor.end(additionalMetrics: {
        'total_hosts': _hosts.length,
        'filtered_hosts': _filteredHosts.length,
        'has_error': _error != null,
      });
    }
  }

  /// 刷新主机列表
  Future<void> refreshHosts() async {
    await loadHosts();
  }

  /// 搜索主机
  void searchHosts(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// 设置分类筛选
  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  /// 添加主机
  Future<bool> addHost({
    required String name,
    required String host,
    required int port,
    required String username,
    String? password,
    String? privateKeyPath,
    String? description,
  }) async {
    _clearError();

    try {
      final newHost = await _repository.addHost(
        name: name,
        host: host,
        port: port,
        username: username,
        password: password,
        privateKeyPath: privateKeyPath,
        description: description,
      );

      _hosts.add(newHost);
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('添加主机失败: $e');
      return false;
    }
  }

  /// 更新主机
  Future<bool> updateHost({
    required String id,
    required String name,
    required String host,
    required int port,
    required String username,
    String? password,
    String? privateKeyPath,
    String? description,
  }) async {
    _clearError();

    try {
      final updatedHost = await _repository.updateHost(
        id: id,
        name: name,
        host: host,
        port: port,
        username: username,
        password: password,
        privateKeyPath: privateKeyPath,
        description: description,
      );

      final index = _hosts.indexWhere((h) => h.id == id);
      if (index != -1) {
        _hosts[index] = updatedHost;
        _applyFilters();
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('更新主机失败: $e');
      return false;
    }
  }

  /// 删除主机
  Future<bool> deleteHost(String id) async {
    _clearError();

    try {
      await _repository.deleteHost(id);
      _hosts.removeWhere((h) => h.id == id);
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('删除主机失败: $e');
      return false;
    }
  }

  /// 测试主机连接
  Future<bool> testConnection(String id) async {
    _clearError();

    try {
      return await _repository.testConnection(id);
    } catch (e) {
      _setError('测试连接失败: $e');
      return false;
    }
  }

  /// 获取主机统计信息
  Future<Map<String, int>?> getHostStats() async {
    try {
      return await _repository.getHostStats();
    } catch (e) {
      _setError('获取统计信息失败: $e');
      return null;
    }
  }

  /// 导入主机
  Future<bool> importHosts(List<Map<String, dynamic>> hostData) async {
    _clearError();

    try {
      final importedHosts = await _repository.importHosts(hostData);
      _hosts.addAll(importedHosts);
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('导入主机失败: $e');
      return false;
    }
  }

  /// 导出主机
  Future<List<Map<String, dynamic>>?> exportHosts() async {
    try {
      return await _repository.exportHosts();
    } catch (e) {
      _setError('导出主机失败: $e');
      return null;
    }
  }

  /// 根据ID获取主机
  SSHHost? getHostById(String id) {
    try {
      return _hosts.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 应用筛选条件
  void _applyFilters() {
    _filteredHosts = _hosts.where((host) {
      // 搜索筛选
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!host.name.toLowerCase().contains(query) &&
            !host.host.toLowerCase().contains(query) &&
            !host.username.toLowerCase().contains(query) &&
            !(host.description?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // 分类筛选（这里可以根据需要扩展）
      if (_selectedCategory != '全部') {
        // TODO: 根据实际需求实现分类逻辑
      }

      return true;
    }).toList();

    // 按名称排序
    _filteredHosts.sort((a, b) => a.name.compareTo(b.name));
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置错误信息
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// 清除错误信息
  void _clearError() {
    _error = null;
  }

  /// 清除搜索
  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  /// 重置筛选
  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = '全部';
    _applyFilters();
    notifyListeners();
  }

  /// 开始连接监控
  void _startConnectionMonitoring() {
    _connectionSubscription?.cancel();
    _connectionService.startMonitoring(_hosts);

    _connectionSubscription = _connectionService.connectionStates.listen(
      (states) {
        _connectionStates = states;
        notifyListeners();
      },
    );
  }

  /// 手动检测主机连接状态
  Future<bool> checkHostConnection(String hostId) async {
    final host = getHostById(hostId);
    if (host == null) return false;

    return await _connectionService.checkConnection(host);
  }

  /// 释放资源
  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _connectionService.stopAllMonitoring();
    super.dispose();
  }
}
