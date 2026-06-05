import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../api/adwmh_client.dart';

class FinancePayCodePage extends StatefulWidget {
  const FinancePayCodePage({super.key});

  @override
  State<FinancePayCodePage> createState() => _FinancePayCodePageState();
}

class _FinancePayCodePageState extends State<FinancePayCodePage> {
  final _client = AdwmhClient();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();

  bool _loading = true;
  bool _loggingIn = false;
  bool _refreshing = false;
  bool _needsLogin = false;
  String? _error;
  String? _oneCode;
  String? _time;
  String? _balance;
  Uint8List? _captcha;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _client.init();
      final user = await _client.fetchSessionUser();
      if (user == null) {
        final captcha = await _client.fetchCaptcha();
        setState(() {
          _needsLogin = true;
          _captcha = captcha;
          _loading = false;
        });
        return;
      }
      await _loadOneCode(user);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadOneCode(Map<String, dynamic> user) async {
    final oneCode = await _client.fetchOneCode();
    final balance = await _client.fetchBalance();
    setState(() {
      _user = user;
      _oneCode = oneCode.code;
      _time = oneCode.time;
      _balance = balance;
      _needsLogin = false;
      _loading = false;
      _refreshing = false;
      _error = null;
    });
  }

  Future<void> _refreshCaptcha() async {
    final captcha = await _client.fetchCaptcha();
    setState(() {
      _captcha = captcha;
      _captchaController.clear();
    });
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final captcha = _captchaController.text.trim();
    if (username.isEmpty || password.isEmpty || captcha.isEmpty) {
      setState(() => _error = '请输入智慧安大账号、密码和验证码');
      return;
    }
    setState(() {
      _loggingIn = true;
      _error = null;
    });
    try {
      await _client.login(
        username: username,
        password: password,
        captcha: captcha,
      );
      final user = await _client.fetchSessionUser();
      if (user == null) {
        throw StateError('智慧安大登录成功但会话未建立');
      }
      await _loadOneCode(user);
      setState(() => _loggingIn = false);
    } catch (e) {
      final captcha = await _client.fetchCaptcha();
      setState(() {
        _error = e.toString();
        _captcha = captcha;
        _captchaController.clear();
        _loggingIn = false;
      });
    }
  }

  Future<void> _refreshCode() async {
    final user = _user ?? await _client.fetchSessionUser();
    if (user == null) {
      await _load();
      return;
    }
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      await _loadOneCode(user);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _refreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('一码通')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _needsLogin ? _refreshCaptcha : _refreshCode,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_needsLogin) _buildLoginCard() else _buildOneCodeCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildLoginCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.qr_code_2, size: 56, color: colorScheme.primary),
            const SizedBox(height: 12),
            const Text(
              '登录智慧安大后生成一码通',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '一码通二维码来自智慧安大 /xzxcard/qrcode，不再使用一卡通 20 位条码。',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '学号 / 工号',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '智慧安大密码',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _captchaController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_loggingIn) _login();
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '验证码',
                      prefixIcon: Icon(Icons.verified_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _loggingIn ? null : _refreshCaptcha,
                  child: Container(
                    width: 96,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _captcha == null
                        ? const Icon(Icons.refresh)
                        : Image.memory(_captcha!, fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loggingIn ? null : _login,
              icon: _loggingIn
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(_loggingIn ? '登录中...' : '登录并生成一码通'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOneCodeCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final user = _user ?? {};
    final name = _maskedName(user['userName']?.toString());
    final idNumber = user['idNumber']?.toString() ?? '';
    final headimg = user['headimgurl']?.toString();
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      child: Column(
        children: [
          Text(
            '一码通',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 54),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 70, 18, 20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idNumber,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_refreshing)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 72),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 72),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      )
                    else if (_oneCode != null)
                      Container(
                        width: 250,
                        height: 250,
                        padding: const EdgeInsets.all(8),
                        color: Colors.white,
                        child: QrImageView(
                          data: _oneCode!,
                          version: QrVersions.auto,
                          errorCorrectionLevel: QrErrorCorrectLevel.L,
                          backgroundColor: Colors.white,
                          errorStateBuilder: (_, error) =>
                              Center(child: Text('二维码生成失败：$error')),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      _time ?? '',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '余额',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            '￥${_balance ?? '-'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('全部应用'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _refreshing ? null : _refreshCode,
                      icon: const Icon(Icons.refresh),
                      label: const Text('点击刷新'),
                    ),
                    TextButton.icon(
                      onPressed: _oneCode == null
                          ? null
                          : () async {
                              await Clipboard.setData(
                                ClipboardData(text: _oneCode!),
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('一码通内容已复制')),
                              );
                            },
                      icon: const Icon(Icons.copy),
                      label: const Text('复制二维码内容'),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -50,
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: colorScheme.surface,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: _headImage(headimg),
                    child: _headImage(headimg) == null
                        ? Icon(
                            Icons.person,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ImageProvider? _headImage(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http')) return NetworkImage(value);
    return NetworkImage('${AdwmhClient.baseUrl}$value');
  }

  String _maskedName(String? value) {
    if (value == null || value.isEmpty) return '-';
    if (value.length == 2) return '${value.substring(0, 1)} *';
    if (value.length == 3) {
      return '${value.substring(0, 1)} * ${value.substring(2, 3)}';
    }
    return '${value.substring(0, 1)} * * ${value.substring(3)}';
  }
}
