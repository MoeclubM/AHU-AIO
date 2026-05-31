import 'package:flutter/material.dart';

import '../api/synjones_client.dart';

class FinanceAppsPage extends StatefulWidget {
  const FinanceAppsPage({super.key});

  @override
  State<FinanceAppsPage> createState() => _FinanceAppsPageState();
}

class _FinanceAppsPageState extends State<FinanceAppsPage> {
  final _client = SynjonesClient();
  List<Map<String, dynamic>> _apps = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _client.init();
      final resp = await _client.getAllApps();
      _apps = ((resp['data'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('服务目录')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadApps,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (_, index) => _buildApp(_apps[index]),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemCount: _apps.length,
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadApps, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  Widget _buildApp(Map<String, dynamic> app) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: Icon(Icons.apps, color: Colors.indigo.shade700),
        ),
        title: Text(_appTitle(app)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('编号：${app['bh'] ?? app['id'] ?? '-'}'),
              Text(
                '编码：${app['appCode'] ?? app['code'] ?? app['indexCode'] ?? '-'}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _appTitle(Map<String, dynamic> app) {
    return app['name']?.toString() ??
        app['mc']?.toString() ??
        app['appName']?.toString() ??
        app['title']?.toString() ??
        '未命名服务';
  }
}
