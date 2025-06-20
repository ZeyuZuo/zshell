import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

/// 设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 页面标题
        _buildHeader(),
        const SizedBox(height: 24),
        // 设置内容
        Expanded(
          child: _buildSettingsContent(),
        ),
      ],
    );
  }

  /// 构建页面头部
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '设置',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '应用配置和偏好设置',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 构建设置内容
  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildAppearanceSection(),
          const SizedBox(height: 24),
          _buildConnectionSection(),
          const SizedBox(height: 24),
          _buildSecuritySection(),
          const SizedBox(height: 24),
          _buildAboutSection(),
        ],
      ),
    );
  }

  /// 构建外观设置部分
  Widget _buildAppearanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '外观',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('主题模式'),
                  subtitle: Text(themeProvider.themeModeDisplayName),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeProvider.themeMode,
                    onChanged: (ThemeMode? mode) {
                      if (mode != null) {
                        themeProvider.setThemeMode(mode);
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('跟随系统'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('浅色主题'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('深色主题'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.font_download),
              title: const Text('字体'),
              subtitle: const Text('JetBrains Mono'),
              trailing: const Icon(Icons.check, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建连接设置部分
  Widget _buildConnectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '连接设置',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('连接超时'),
              subtitle: const Text('30秒'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showTimeoutDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('重试次数'),
              subtitle: const Text('3次'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showRetryDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.terminal),
              title: const Text('默认终端'),
              subtitle: const Text('系统默认'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showTerminalDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建安全设置部分
  Widget _buildSecuritySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '安全',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              secondary: const Icon(Icons.security),
              title: const Text('自动锁定'),
              subtitle: const Text('空闲时自动锁定应用'),
              value: true,
              onChanged: (value) {
                // TODO: 实现自动锁定功能
              },
            ),
            ListTile(
              leading: const Icon(Icons.key),
              title: const Text('SSH密钥管理'),
              subtitle: const Text('管理SSH私钥文件'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showKeyManagementDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('数据备份'),
              subtitle: const Text('备份配置和数据'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showBackupDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建关于部分
  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '关于',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('版本信息'),
              subtitle: const Text('ZShell v1.0.0'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showVersionDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('帮助文档'),
              subtitle: const Text('查看使用说明'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showHelpDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('反馈问题'),
              subtitle: const Text('报告bug或建议'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showFeedbackDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示超时设置对话框
  void _showTimeoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('连接超时设置'),
        content: const Text('连接超时设置功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示重试设置对话框
  void _showRetryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重试次数设置'),
        content: const Text('重试次数设置功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示终端设置对话框
  void _showTerminalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('默认终端设置'),
        content: const Text('默认终端设置功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示密钥管理对话框
  void _showKeyManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SSH密钥管理'),
        content: const Text('SSH密钥管理功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示备份对话框
  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('数据备份'),
        content: const Text('数据备份功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示版本信息对话框
  void _showVersionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('版本信息'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('应用名称: ZShell'),
            Text('版本: 1.0.0'),
            Text('构建日期: 2024-12-20'),
            Text('Flutter版本: 3.8.1'),
            SizedBox(height: 16),
            Text('一个基于Flutter开发的跨平台SSH连接管理工具'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示帮助对话框
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('帮助文档'),
        content: const Text('帮助文档功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示反馈对话框
  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('反馈问题'),
        content: const Text('反馈功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
