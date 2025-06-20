import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/ssh_connection_service.dart';
import '../../data/models/ssh_host.dart';
import 'logger.dart';

/// SSH调试助手
class SSHDebugHelper {
  static final SSHDebugHelper _instance = SSHDebugHelper._internal();
  factory SSHDebugHelper() => _instance;
  SSHDebugHelper._internal();

  /// 检查SSH客户端可用性
  Future<Map<String, bool>> checkSSHClients() async {
    final results = <String, bool>{};
    
    // 检查OpenSSH
    try {
      final result = await Process.run('ssh', ['-V'], runInShell: Platform.isWindows);
      results['OpenSSH'] = result.exitCode == 0;
      AppLogger.info('OpenSSH检查结果: ${result.exitCode == 0 ? '可用' : '不可用'}', tag: 'SSHDebug');
      if (result.exitCode == 0) {
        AppLogger.info('OpenSSH版本: ${result.stderr}', tag: 'SSHDebug');
      }
    } catch (e) {
      results['OpenSSH'] = false;
      AppLogger.warning('OpenSSH不可用: $e', tag: 'SSHDebug');
    }

    // 检查PuTTY plink (Windows)
    if (Platform.isWindows) {
      try {
        final result = await Process.run('plink', ['-V'], runInShell: true);
        results['PuTTY plink'] = result.exitCode == 0;
        AppLogger.info('PuTTY plink检查结果: ${result.exitCode == 0 ? '可用' : '不可用'}', tag: 'SSHDebug');
      } catch (e) {
        results['PuTTY plink'] = false;
        AppLogger.warning('PuTTY plink不可用: $e', tag: 'SSHDebug');
      }
    }

    return results;
  }

  /// 测试SSH连接
  Future<bool> testSSHConnection(SSHHost host) async {
    AppLogger.info('开始测试SSH连接: ${host.name}', tag: 'SSHDebug');
    
    try {
      // 首先检查SSH客户端
      final clients = await checkSSHClients();
      AppLogger.info('可用的SSH客户端: $clients', tag: 'SSHDebug');

      // 尝试建立连接
      final connection = SSHConnectionService('test_${DateTime.now().millisecondsSinceEpoch}', host);

      // 监听输出用于调试
      connection.outputStream.listen((output) {
        print('测试连接输出: $output');
      });

      connection.errorStream.listen((error) {
        print('测试连接错误: $error');
      });

      await connection.connect();
      
      if (connection.isConnected) {
        AppLogger.info('SSH连接测试成功', tag: 'SSHDebug');
        await connection.disconnect();
        return true;
      } else {
        AppLogger.warning('SSH连接测试失败：连接未建立', tag: 'SSHDebug');
        return false;
      }
    } catch (e) {
      AppLogger.exception('SSHDebug', 'testSSHConnection', e);
      return false;
    }
  }

  /// 生成SSH连接诊断报告
  Future<String> generateDiagnosticReport(SSHHost host) async {
    final report = StringBuffer();
    report.writeln('=== SSH连接诊断报告 ===');
    report.writeln('时间: ${DateTime.now()}');
    report.writeln('主机: ${host.name} (${host.host}:${host.port})');
    report.writeln('用户: ${host.username}');
    report.writeln('认证方式: ${host.privateKeyPath?.isNotEmpty == true ? '私钥' : '密码'}');
    report.writeln('操作系统: ${Platform.operatingSystem}');
    report.writeln('');

    // 检查SSH客户端
    report.writeln('--- SSH客户端检查 ---');
    final clients = await checkSSHClients();
    clients.forEach((client, available) {
      report.writeln('$client: ${available ? '✓ 可用' : '✗ 不可用'}');
    });
    report.writeln('');

    // 网络连接检查
    report.writeln('--- 网络连接检查 ---');
    try {
      final socket = await Socket.connect(host.host, host.port, timeout: const Duration(seconds: 10));
      report.writeln('TCP连接: ✓ 成功');
      await socket.close();
    } catch (e) {
      report.writeln('TCP连接: ✗ 失败 - $e');
    }

    // SSH连接测试
    report.writeln('--- SSH连接测试 ---');
    final sshTest = await testSSHConnection(host);
    report.writeln('SSH连接: ${sshTest ? '✓ 成功' : '✗ 失败'}');

    report.writeln('');
    report.writeln('=== 诊断完成 ===');

    final reportText = report.toString();
    AppLogger.info('SSH诊断报告:\n$reportText', tag: 'SSHDebug');
    return reportText;
  }

  /// 创建测试用的SSH主机配置
  static SSHHost createTestHost() {
    return SSHHost(
      id: 'test_host',
      name: '测试主机',
      host: 'localhost',
      port: 22,
      username: 'test',
      password: 'test',
      description: '用于测试SSH连接的主机配置',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 打印调试信息
  void printDebugInfo() {
    if (kDebugMode) {
      AppLogger.info('=== SSH调试信息 ===', tag: 'SSHDebug');
      AppLogger.info('平台: ${Platform.operatingSystem}', tag: 'SSHDebug');
      AppLogger.info('是否为Windows: ${Platform.isWindows}', tag: 'SSHDebug');
      AppLogger.info('环境变量PATH: ${Platform.environment['PATH']}', tag: 'SSHDebug');
      AppLogger.info('==================', tag: 'SSHDebug');
    }
  }
}
