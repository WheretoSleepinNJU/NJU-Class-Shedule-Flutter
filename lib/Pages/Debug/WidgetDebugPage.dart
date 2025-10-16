import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/widget_data/services/unified_data_service.dart';
import '../../core/widget_data/communication/native_data_bridge.dart';

/// Widget 调试页面
/// 用于测试 Widget 数据传输
class WidgetDebugPage extends StatefulWidget {
  const WidgetDebugPage({Key? key}) : super(key: key);

  @override
  _WidgetDebugPageState createState() => _WidgetDebugPageState();
}

class _WidgetDebugPageState extends State<WidgetDebugPage> {
  final List<String> _logs = [];
  bool _isLoading = false;
  UnifiedDataService? _service;
  final NativeDataBridge _bridge = NativeDataBridge();

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    final prefs = await SharedPreferences.getInstance();
    _service = UnifiedDataService(preferences: prefs);
    _addLog('服务初始化成功');
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_logs.length > 50) {
        _logs.removeLast();
      }
    });
  }

  Future<void> _sendWidgetData() async {
    if (_service == null) {
      _addLog('❌ 服务未初始化');
      return;
    }

    setState(() => _isLoading = true);
    _addLog('开始发送 Widget 数据...');

    try {
      final success = await _service!.updateWidgetData();
      if (success) {
        _addLog('✅ Widget 数据发送成功');
      } else {
        _addLog('❌ Widget 数据发送失败');
      }
    } catch (e) {
      _addLog('❌ 发送失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshWidgets() async {
    setState(() => _isLoading = true);
    _addLog('请求刷新 Widgets...');

    try {
      final success = await _bridge.refreshWidgets();
      if (success) {
        _addLog('✅ Widget 刷新请求成功');
      } else {
        _addLog('❌ Widget 刷新请求失败');
      }
    } catch (e) {
      _addLog('❌ 刷新失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getPlatformInfo() async {
    setState(() => _isLoading = true);
    _addLog('获取平台信息...');

    try {
      final info = await _bridge.getNativeDataStatus();
      if (info != null) {
        _addLog('✅ 平台信息:');
        info.forEach((key, value) {
          _addLog('  $key: $value');
        });
      } else {
        _addLog('❌ 无法获取平台信息');
      }
    } catch (e) {
      _addLog('❌ 获取失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getWidgetData() async {
    if (_service == null) {
      _addLog('❌ 服务未初始化');
      return;
    }

    setState(() => _isLoading = true);
    _addLog('读取 Widget 数据...');

    try {
      final data = await _service!.getWidgetData();
      _addLog('✅ 数据读取成功:');
      _addLog('  学校: ${data.schoolName}');
      _addLog('  当前周次: ${data.currentWeek}');
      _addLog('  今日课程数: ${data.todayCourseCount}');
      _addLog('  明日课程数: ${data.tomorrowCourseCount}');
      _addLog('  总课程数: ${data.totalCourses}');
      if (data.nextCourse != null) {
        _addLog('  下节课: ${data.nextCourse!.name}');
      }
      if (data.currentCourse != null) {
        _addLog('  当前课: ${data.currentCourse!.name}');
      }
    } catch (e) {
      _addLog('❌ 读取失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget 调试工具'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLogs,
            tooltip: '清空日志',
          ),
        ],
      ),
      body: Column(
        children: [
          // 操作按钮
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendWidgetData,
                  icon: const Icon(Icons.send),
                  label: const Text('发送 Widget 数据'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _getWidgetData,
                        icon: const Icon(Icons.data_object),
                        label: const Text('查看数据'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _refreshWidgets,
                        icon: const Icon(Icons.refresh),
                        label: const Text('刷新 Widget'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _getPlatformInfo,
                  icon: const Icon(Icons.info_outline),
                  label: const Text('获取平台信息'),
                ),
              ],
            ),
          ),

          // 日志区域
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          '点击上方按钮开始测试',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      Color? bgColor;
                      if (log.contains('✅')) {
                        bgColor = Colors.green[50];
                      } else if (log.contains('❌')) {
                        bgColor = Colors.red[50];
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor ?? Colors.grey[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 加载指示器
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('处理中...'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
