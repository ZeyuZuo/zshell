import 'package:flutter/material.dart';

/// AI助手页面
class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 页面标题
        _buildHeader(),
        const SizedBox(height: 24),
        // 聊天区域
        Expanded(
          child: _buildChatArea(),
        ),
        // 输入区域
        _buildInputArea(),
      ],
    );
  }

  /// 构建页面头部
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI助手',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '智能命令助手，帮您解决技术问题',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 构建聊天区域
  Widget _buildChatArea() {
    if (_messages.isEmpty) {
      return _buildWelcomeScreen();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            return _buildMessageBubble(_messages[index]);
          },
        ),
      ),
    );
  }

  /// 构建欢迎界面
  Widget _buildWelcomeScreen() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              '欢迎使用AI助手',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '我可以帮助您：',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildFeatureList(),
            const SizedBox(height: 24),
            Text(
              '在下方输入您的问题开始对话',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建功能列表
  Widget _buildFeatureList() {
    final features = [
      '解释Linux/Unix命令',
      '故障排查建议',
      '最佳实践推荐',
      '脚本编写帮助',
    ];

    return Column(
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(feature),
          ],
        ),
      )).toList(),
    );
  }

  /// 构建消息气泡
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(
                Icons.smart_toy,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建输入区域
  Widget _buildInputArea() {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: '输入您的问题...',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _sendMessage,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  /// 发送消息
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(content: message, isUser: true));
      _messageController.clear();
    });

    // 模拟AI回复
    _simulateAIResponse(message);
  }

  /// 模拟AI回复
  void _simulateAIResponse(String userMessage) {
    // 延迟模拟网络请求
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      
      String response = _generateMockResponse(userMessage);
      
      setState(() {
        _messages.add(ChatMessage(content: response, isUser: false));
      });
    });
  }

  /// 生成模拟回复
  String _generateMockResponse(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('ls') || lowerMessage.contains('列表')) {
      return 'ls 命令用于列出目录内容。常用选项：\n'
          '• ls -l：显示详细信息\n'
          '• ls -a：显示隐藏文件\n'
          '• ls -la：组合使用\n'
          '• ls -h：人性化显示文件大小';
    } else if (lowerMessage.contains('ssh') || lowerMessage.contains('连接')) {
      return 'SSH连接的基本语法：\n'
          'ssh username@hostname\n\n'
          '常用选项：\n'
          '• -p port：指定端口\n'
          '• -i keyfile：使用私钥文件\n'
          '• -v：详细输出（调试用）';
    } else if (lowerMessage.contains('权限') || lowerMessage.contains('chmod')) {
      return 'chmod 命令用于修改文件权限：\n'
          '• chmod 755 file：rwxr-xr-x\n'
          '• chmod 644 file：rw-r--r--\n'
          '• chmod +x file：添加执行权限\n'
          '• chmod -w file：移除写权限';
    } else {
      return '感谢您的问题！这是一个模拟的AI回复。在实际应用中，这里会连接到真正的AI服务来提供智能回答。\n\n'
          '您的问题："$message"\n\n'
          '建议您查阅相关文档或尝试使用 man 命令获取更多帮助信息。';
    }
  }
}

/// 聊天消息模型
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
