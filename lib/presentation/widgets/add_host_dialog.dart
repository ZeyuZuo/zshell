import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/ssh_host.dart';

/// 添加/编辑主机对话框
class AddHostDialog extends StatefulWidget {
  final SSHHost? host; // 如果为null则是添加，否则是编辑
  final Function(Map<String, dynamic>) onSave;

  const AddHostDialog({
    super.key,
    this.host,
    required this.onSave,
  });

  @override
  State<AddHostDialog> createState() => _AddHostDialogState();
}

class _AddHostDialogState extends State<AddHostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _privateKeyController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _usePassword = true;
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _privateKeyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeFields() {
    if (widget.host != null) {
      final host = widget.host!;
      _nameController.text = host.name;
      _hostController.text = host.host;
      _portController.text = host.port.toString();
      _usernameController.text = host.username;
      _passwordController.text = host.password ?? '';
      _privateKeyController.text = host.privateKeyPath ?? '';
      _descriptionController.text = host.description ?? '';
      _usePassword = host.password?.isNotEmpty == true;
    } else {
      _portController.text = '22'; // 默认SSH端口
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.host != null;
    
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? '编辑主机' : '添加主机',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 表单
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),
                      _buildAuthSection(),
                      const SizedBox(height: 24),
                      _buildOptionalSection(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isLoading ? null : _saveHost,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? '更新' : '添加'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '基本信息',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '主机名称',
            hintText: '为这个主机起一个名字',
            prefixIcon: Icon(Icons.label),
          ),
          validator: (value) {
            if (value?.trim().isEmpty == true) {
              return '请输入主机名称';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: '主机地址',
                  hintText: 'IP地址或域名',
                  prefixIcon: Icon(Icons.computer),
                ),
                validator: (value) {
                  if (value?.trim().isEmpty == true) {
                    return '请输入主机地址';
                  }
                  // 简单的IP地址或域名验证
                  final hostPattern = RegExp(r'^[a-zA-Z0-9.-]+$');
                  if (!hostPattern.hasMatch(value!.trim())) {
                    return '请输入有效的IP地址或域名';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: '端口',
                  prefixIcon: Icon(Icons.settings_ethernet),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                validator: (value) {
                  if (value?.trim().isEmpty == true) {
                    return '请输入端口';
                  }
                  final port = int.tryParse(value!);
                  if (port == null || port < 1 || port > 65535) {
                    return '端口范围1-65535';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: '用户名',
            hintText: '登录用户名',
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value?.trim().isEmpty == true) {
              return '请输入用户名';
            }
            // 用户名验证
            final usernamePattern = RegExp(r'^[a-zA-Z0-9_-]+$');
            if (!usernamePattern.hasMatch(value!.trim())) {
              return '用户名只能包含字母、数字、下划线和连字符';
            }
            if (value.trim().length > 32) {
              return '用户名长度不能超过32个字符';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAuthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '认证方式',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('密码'),
                value: true,
                groupValue: _usePassword,
                onChanged: (value) {
                  setState(() {
                    _usePassword = value!;
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('私钥'),
                value: false,
                groupValue: _usePassword,
                onChanged: (value) {
                  setState(() {
                    _usePassword = value!;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_usePassword) ...[
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: '密码',
              hintText: '登录密码',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
            ),
            obscureText: !_showPassword,
            validator: (value) {
              if (_usePassword && (value?.trim().isEmpty == true)) {
                return '请输入密码';
              }
              return null;
            },
          ),
        ] else ...[
          TextFormField(
            controller: _privateKeyController,
            decoration: InputDecoration(
              labelText: '私钥文件路径',
              hintText: '选择私钥文件',
              prefixIcon: const Icon(Icons.key),
              suffixIcon: IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: _selectPrivateKeyFile,
              ),
            ),
            readOnly: true,
            validator: (value) {
              if (!_usePassword && (value?.trim().isEmpty == true)) {
                return '请选择私钥文件';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildOptionalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '可选信息',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: '描述',
            hintText: '主机描述信息（可选）',
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Future<void> _selectPrivateKeyFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        _privateKeyController.text = result.files.first.path ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    }
  }

  Future<void> _saveHost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final hostData = {
        'name': _nameController.text.trim(),
        'host': _hostController.text.trim(),
        'port': int.parse(_portController.text.trim()),
        'username': _usernameController.text.trim(),
        'password': _usePassword ? _passwordController.text.trim() : null,
        'privateKeyPath': !_usePassword ? _privateKeyController.text.trim() : null,
        'description': _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      };

      await widget.onSave(hostData);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
