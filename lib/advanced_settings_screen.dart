import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/auth_manager.dart';
import 'finance/api/synjones_client.dart';
import 'globals.dart' as globals;
import 'jwapp/api/getuserinfo_extended.dart';
import 'miuix/miuix_components.dart';
import 'miuix/liquid_glass_card.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  final AuthManager _authManager = AuthManager();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _jwappPasswordController =
      TextEditingController();
  final TextEditingController _jwPasswordController = TextEditingController();
  final TextEditingController _financePasswordController =
      TextEditingController();

  bool _jwappObscure = true;
  bool _jwObscure = true;
  bool _financeObscure = true;

  bool _jwappLoading = false;
  bool _jwLoading = false;
  bool _financeLoading = false;

  bool? _jwappSuccess;
  String? _jwappMessage;

  bool? _jwSuccess;
  String? _jwMessage;

  bool? _financeSuccess;
  String? _financeMessage;

  @override
  void initState() {
    super.initState();
    _authManager.addListener(_onAuthChanged);
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _authManager.removeListener(_onAuthChanged);
    _usernameController.dispose();
    _jwappPasswordController.dispose();
    _jwPasswordController.dispose();
    _financePasswordController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    var u = prefs.getString('username') ?? globals.username ?? '';

    // 如果 u 恰好是历史误存的教务内部 studentId，重置为空避免错误填充
    final jwInternalId = prefs.getString('jwStudentNo') ?? globals.jwStudentNo;
    if (u.isNotEmpty && jwInternalId != null && u == jwInternalId) {
      u = '';
    }

    // 若本地暂无 username，优先从一卡通已获取的用户信息中提取真实学号 (account)
    if (u.isEmpty) {
      final synjonesUser = SynjonesClient().userInfo;
      final synAccount = synjonesUser?['account']?.toString();
      if (synAccount != null && synAccount.isNotEmpty) {
        u = synAccount;
        globals.username = u;
        await prefs.setString('username', u);
      }
    }

    final pUnified = prefs.getString('password') ?? '';
    final pJwapp = prefs.getString('jwapp_password') ?? pUnified;
    final pJw = prefs.getString('jw_password') ?? pUnified;
    final pFinance = prefs.getString('finance_password') ?? pUnified;

    if (mounted) {
      setState(() {
        _usernameController.text = u;
        _jwappPasswordController.text = pJwapp;
        _jwPasswordController.text = pJw;
        _financePasswordController.text = pFinance;
      });
    }

    // 若仍为空且已登录微教务，异步拉取真实学号并回填
    if (u.isEmpty && globals.idToken != null && globals.idToken!.isNotEmpty) {
      try {
        final info = await UserInfoExtendedApi.getUserInfo(globals.idToken!);
        final account = info['account']?.toString();
        if (account != null && account.isNotEmpty) {
          globals.username = account;
          await prefs.setString('username', account);
          if (mounted && _usernameController.text.isEmpty) {
            setState(() {
              _usernameController.text = account;
            });
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _verifyPlatform(String platform) async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先输入认证学号/账号')));
      return;
    }

    if (platform == 'jwapp') {
      final password = _jwappPasswordController.text;
      if (password.isEmpty) {
        setState(() {
          _jwappSuccess = false;
          _jwappMessage = '请输入微教务密码';
        });
        return;
      }
      setState(() {
        _jwappLoading = true;
        _jwappMessage = null;
      });
      final error = await _authManager.verifyJwapp(
        username: username,
        password: password,
      );
      if (mounted) {
        setState(() {
          _jwappLoading = false;
          _jwappSuccess = error == null;
          _jwappMessage = error ?? '验证成功，后续将使用此独立密码';
        });
      }
    } else if (platform == 'jw') {
      final password = _jwPasswordController.text;
      if (password.isEmpty) {
        setState(() {
          _jwSuccess = false;
          _jwMessage = '请输入安大教务密码';
        });
        return;
      }
      setState(() {
        _jwLoading = true;
        _jwMessage = null;
      });
      final error = await _authManager.verifyJw(
        username: username,
        password: password,
      );
      if (mounted) {
        setState(() {
          _jwLoading = false;
          _jwSuccess = error == null;
          _jwMessage = error ?? '验证成功，后续将使用此独立密码';
        });
      }
    } else if (platform == 'finance') {
      final password = _financePasswordController.text;
      if (password.isEmpty) {
        setState(() {
          _financeSuccess = false;
          _financeMessage = '请输入一卡通密码';
        });
        return;
      }
      setState(() {
        _financeLoading = true;
        _financeMessage = null;
      });
      final error = await _authManager.verifyFinance(
        username: username,
        password: password,
      );
      if (mounted) {
        setState(() {
          _financeLoading = false;
          _financeSuccess = error == null;
          _financeMessage = error ?? '验证成功，后续将使用此独立密码';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mc = MiuixTheme.of(context).colors;

    return Scaffold(
      appBar: AppBar(title: const Text('高级')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          const MiuixSmallTitle('认证与安全'),
          LiquidGlassCard(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              children: [
                MiuixComponent(
                  title: '密码认证行为',
                  summary: _authManager.behavior.displayName,
                  leading: Icon(
                    _authManager.isUnified
                        ? Icons.lock_outline_rounded
                        : Icons.password_rounded,
                    color: mc.primary,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _authManager.behavior.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          color: mc.onSurfaceVariantActions,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: mc.onSurfaceVariantActions,
                      ),
                    ],
                  ),
                  onTap: () => _showAuthBehaviorSheet(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 独立密码认证下展示三个平台的独立密码输入与验证卡片
          if (_authManager.isIndependent) ...[
            const MiuixSmallTitle('独立密码配置'),
            LiquidGlassCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 学号/账号输入
                  Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 20, color: mc.primary),
                      const SizedBox(width: 8),
                      Text(
                        '认证学号/账号',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: mc.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: '请输入统一身份认证学号',
                      isDense: true,
                      filled: true,
                      fillColor: mc.surfaceContainer.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: mc.outline.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // 1. 微教务平台密码
                  _buildPlatformSection(
                    title: '微教务平台',
                    subtitle: '用于课程表、空闲教室等微服务接口',
                    icon: Icons.bolt_rounded,
                    controller: _jwappPasswordController,
                    obscure: _jwappObscure,
                    onToggleObscure: () {
                      setState(() => _jwappObscure = !_jwappObscure);
                    },
                    loading: _jwappLoading,
                    success: _jwappSuccess,
                    message: _jwappMessage,
                    onVerify: () => _verifyPlatform('jwapp'),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // 2. 安大教务系统密码
                  _buildPlatformSection(
                    title: '安大教务系统 (CAS)',
                    subtitle: '用于成绩查询、培养方案与教务业务',
                    icon: Icons.school_rounded,
                    controller: _jwPasswordController,
                    obscure: _jwObscure,
                    onToggleObscure: () {
                      setState(() => _jwObscure = !_jwObscure);
                    },
                    loading: _jwLoading,
                    success: _jwSuccess,
                    message: _jwMessage,
                    onVerify: () => _verifyPlatform('jw'),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // 3. 一卡通系统密码
                  _buildPlatformSection(
                    title: '一卡通系统 (CAS)',
                    subtitle: '用于校园卡余额、一码通与充值缴费',
                    icon: Icons.credit_card_rounded,
                    controller: _financePasswordController,
                    obscure: _financeObscure,
                    onToggleObscure: () {
                      setState(() => _financeObscure = !_financeObscure);
                    },
                    loading: _financeLoading,
                    success: _financeSuccess,
                    message: _financeMessage,
                    onVerify: () => _verifyPlatform('finance'),
                  ),
                ],
              ),
            ),
          ] else ...[
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: mc.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '当前为统一密码认证模式。所有平台均使用登录时输入的统一密码。若各平台密码不同，请在上方切换为「独立密码认证」。',
                      style: TextStyle(
                        fontSize: 13,
                        color: mc.onSurfaceVariantActions,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlatformSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required bool loading,
    required bool? success,
    required String? message,
    required VoidCallback onVerify,
  }) {
    final mc = MiuixTheme.of(context).colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: mc.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: mc.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 11.5, color: mc.onSurfaceVariantActions),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: '请输入密码',
                  isDense: true,
                  filled: true,
                  fillColor: mc.surfaceContainer.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: mc.outline.withOpacity(0.3)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: mc.onSurfaceVariantActions,
                    ),
                    onPressed: onToggleObscure,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: loading ? null : onVerify,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('验证', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (success == true ? Colors.green : Colors.red).withOpacity(
                0.1,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (success == true ? Colors.green : Colors.red)
                    .withOpacity(0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  success == true
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  size: 16,
                  color: success == true ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 12,
                      color: success == true
                          ? (Theme.of(context).brightness == Brightness.dark
                                ? Colors.green.shade300
                                : Colors.green.shade800)
                          : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.red.shade300
                                : Colors.red.shade800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showAuthBehaviorSheet(BuildContext context) {
    final mc = MiuixTheme.of(context).colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).viewPadding.bottom;
        final currentBehavior = _authManager.behavior;

        return Material(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: mc.outline.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '密码认证行为',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: mc.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '选择各业务平台账号密码的认证管理方式',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: mc.onSurfaceVariantActions,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildOption(
                    ctx: ctx,
                    title: '统一密码认证',
                    subtitle: '使用一套账号密码同时登录微教务、安大教务与一卡通（默认）',
                    icon: Icons.link_rounded,
                    isSelected: currentBehavior == AuthBehavior.unified,
                    onTap: () {
                      _authManager.setBehavior(AuthBehavior.unified);
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildOption(
                    ctx: ctx,
                    title: '独立密码认证',
                    subtitle: '各业务平台使用各自独立的账号密码分别认证与维护',
                    icon: Icons.link_off_rounded,
                    isSelected: currentBehavior == AuthBehavior.independent,
                    onTap: () {
                      _authManager.setBehavior(AuthBehavior.independent);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOption({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final mc = MiuixTheme.of(ctx).colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? mc.primary.withOpacity(0.08)
              : mc.surfaceContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? mc.primary : mc.outline.withOpacity(0.3),
            width: isSelected ? 1.5 : 0.6,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isSelected
                  ? mc.primary.withOpacity(0.18)
                  : mc.surfaceContainerHighest,
              child: Icon(
                icon,
                color: isSelected ? mc.primary : mc.onSurfaceVariantActions,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected ? mc.primary : mc.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: mc.onSurfaceVariantActions,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: mc.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
