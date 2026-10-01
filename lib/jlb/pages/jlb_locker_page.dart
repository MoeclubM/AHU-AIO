import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../adaptive_ui.dart';
import '../../miuix/adaptive_top_app_bar.dart';
import '../api/jlb_client.dart';
import '../models/jlb_models.dart';
import '../services/jlb_storage.dart';
import '../services/wechat_launcher.dart';
import 'jlb_scanner_page.dart';

/// 近邻宝快递柜格口查询与开箱主页面
class JlbLockerPage extends StatefulWidget {
  const JlbLockerPage({super.key});

  @override
  State<JlbLockerPage> createState() => _JlbLockerPageState();
}

class _JlbLockerPageState extends State<JlbLockerPage>
    with WidgetsBindingObserver {
  final TextEditingController _expController = TextEditingController();
  final TextEditingController _sessionController = TextEditingController();
  final JlbClient _client = JlbClient();

  bool _isSessionExpanded = false;
  bool _isValidatingSession = false;
  bool _isQuerying = false;
  bool _isLoadingUnpicked = false;

  JlbUserInfo? _userInfo;
  String _sessionStatusText = '正在检测凭证...';
  bool _isSessionValid = false;

  JlbParcelInfo? _currentParcel;
  List<JlbParcelInfo> _unpickedList = [];
  bool _showUnpickedList = false;
  List<String> _historyCodes = [];

  String? _lastCheckedClipboard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _expController.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboardForSession();
    }
  }

  Future<void> _initData() async {
    final sessionId = await JlbStorage.getSessionId();
    final lastExp = await JlbStorage.getLastExpCode();
    final history = await JlbStorage.getHistoryExpCodes();

    if (mounted) {
      setState(() {
        _sessionController.text = sessionId;
        _client.sessionId = sessionId;
        _expController.text = lastExp;
        _historyCodes = history;
      });
    }

    if (sessionId.isNotEmpty) {
      await _validateSession(silent: true);
    } else {
      if (mounted) {
        setState(() {
          _sessionStatusText = '未配置 Session ID，请先完成微信授权';
          _isSessionValid = false;
          _isSessionExpanded = true;
        });
      }
    }
  }

  /// 验证 Session 有效性
  Future<void> _validateSession({bool silent = false}) async {
    final sid = _sessionController.text.trim();
    if (sid.isEmpty) {
      if (!silent && mounted) {
        _showSnackBar('请先输入近邻宝 Session ID');
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isValidatingSession = true;
      });
    }

    _client.sessionId = sid;
    final res = await _client.checkSession();

    if (mounted) {
      setState(() {
        _isValidatingSession = false;
        _isSessionValid = res.ok;
        _sessionStatusText = res.message;
        _userInfo = res.user;
      });

      if (res.ok) {
        await JlbStorage.saveSessionId(sid);
        if (_userInfo != null) {
          await JlbStorage.saveUserInfo(
            phone: _userInfo!.phone,
            userName: _userInfo!.userName,
          );
        }
        if (!silent) {
          _showSnackBar('Session 验证成功！', isSuccess: true);
        }
        // 自动拉取待取包裹
        _fetchUnpickedList(silent: true);
      } else {
        if (!silent) {
          _showSnackBar(res.message);
        }
      }
    }
  }

  /// 检测剪贴板是否含有 Session
  Future<void> _checkClipboardForSession() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isEmpty || text == _lastCheckedClipboard) return;

      // 常见近邻宝 Session ID 长度通常为 32 或包含特定前缀/十六进制
      final isPotentialSession = (text.length >= 24 &&
              text.length <= 64 &&
              !text.contains('http') &&
              !text.contains(' ') &&
              RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(text)) ||
          text.contains('sessionId');

      if (isPotentialSession && text != _sessionController.text.trim()) {
        _lastCheckedClipboard = text;
        String extracted = text;
        if (text.contains('sessionId')) {
          final match = RegExp(r'sessionId[:=]\s*([a-zA-Z0-9_-]+)').firstMatch(text);
          if (match != null) {
            extracted = match.group(1)!;
          }
        }

        if (mounted) {
          final confirm = await showAdaptiveConfirmDialog(
            context: context,
            title: '检测到剪贴板凭据',
            content: Text('检测到剪贴板中疑似近邻宝 Session 凭据：\n\n$extracted\n\n是否立即导入并验证？'),
            confirmText: '立即导入',
            cancelText: '忽略',
          );
          if (confirm == true && mounted) {
            _sessionController.text = extracted;
            await _validateSession();
          }
        }
      }
    } catch (_) {}
  }

  /// 唤起微信 App
  Future<void> _launchWeChatApp() async {
    final installed = await WeChatLauncher.isInstalled();
    if (!installed) {
      if (mounted) {
        _showSnackBar('未检测到微信客户端，请先安装微信');
      }
      return;
    }

    final success = await WeChatLauncher.launch();
    if (!success && mounted) {
      _showSnackBar('拉起微信失败，请手动打开微信');
    }
  }

  /// 打开离线二维码扫描页面
  Future<void> _openScannerPage() async {
    final scannedSession = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const JlbScannerPage()),
    );
    if (scannedSession != null && scannedSession.isNotEmpty) {
      _sessionController.text = scannedSession.trim();
      _showSnackBar('已扫描到授权凭证，正在验证...', isSuccess: true);
      await _validateSession();
    }
  }

  /// 查询快递单号
  Future<void> _queryExpCode([String? codeToQuery]) async {
    final code = (codeToQuery ?? _expController.text).trim();
    if (code.isEmpty) {
      _showSnackBar('请输入快递运单号');
      return;
    }

    if (!_isSessionValid) {
      _showSnackBar('请先配置并验证有效的近邻宝 Session');
      setState(() => _isSessionExpanded = true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isQuerying = true;
      _showUnpickedList = false;
    });

    final res = await _client.queryByExpCode(code);

    if (mounted) {
      setState(() {
        _isQuerying = false;
        if (res.ok && res.parcel != null) {
          _currentParcel = res.parcel;
          JlbStorage.saveLastExpCode(code);
          _expController.text = code;
          JlbStorage.getHistoryExpCodes().then((h) {
            if (mounted) setState(() => _historyCodes = h);
          });
        } else {
          _showSnackBar(res.message);
        }
      });
    }
  }

  /// 获取当前所有待取包裹列表
  Future<void> _fetchUnpickedList({bool silent = false}) async {
    if (!_isSessionValid) return;

    if (!silent) {
      setState(() => _isLoadingUnpicked = true);
    }

    final res = await _client.getUnpickupList(pageIndex: 1, pageSize: 50);

    if (mounted) {
      setState(() {
        _isLoadingUnpicked = false;
        if (res.ok) {
          _unpickedList = res.list;
          if (!silent) {
            _showUnpickedList = true;
          }
        } else {
          if (!silent) _showSnackBar(res.message);
        }
      });
    }
  }

  /// 执行一键开箱流程
  Future<void> _handleOpenBox(JlbParcelInfo parcel) async {
    if (!parcel.canOpenBox) {
      _showSnackBar('该包裹不支持在线开箱');
      return;
    }

    final confirm = await showAdaptiveConfirmDialog(
      context: context,
      title: '确认一键打开柜门',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('运单号: ${parcel.expCode}'),
          Text('柜体编号: ${parcel.cabCode}', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('格口编号: ${parcel.cellDesc}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          Text('开箱取件码: ${parcel.pickupCode}'),
          const SizedBox(height: 12),
          const Text(
            '【现场提示】下发指令后箱门将立即弹开！请确保您本人已站在对应快递柜前。',
            style: TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ],
      ),
      confirmText: '确认开箱',
      cancelText: '取消',
      isDanger: true,
    );

    if (confirm != true || !mounted) return;

    // 显示进度弹窗
    _showOpenBoxProgressDialog(parcel);
  }

  /// 再次/重新开箱流程 (用于已取走但箱门误关或物品遗留)
  Future<void> _handleReopenBox(JlbParcelInfo parcel) async {
    final confirm = await showAdaptiveConfirmDialog(
      context: context,
      title: '尝试重新开箱',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('运单号: ${parcel.expCode}'),
          Text('柜体编号: ${parcel.cabCode}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('格口编号: ${parcel.cellDesc}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 12),
          const Text(
            '【状态说明】该包裹状态已为【用户已取走】。\n若因柜门意外关上导致包裹遗留，可尝试向近邻宝发送【重新开箱】指令。\n\n是否立即发送？',
            style: TextStyle(color: Colors.orange, fontSize: 13),
          ),
        ],
      ),
      confirmText: '发送重开指令',
      cancelText: '取消',
      isDanger: true,
    );

    if (confirm != true || !mounted) return;

    _showSnackBar('正在发送重开箱门指令...');
    final res = await _client.cabPickupReopen(parcel.orderId);
    if (mounted) {
      if (res.ok) {
        _showSnackBar('重开箱门指令已发送！请观察柜门是否弹开。', isSuccess: true);
        await showAdaptiveConfirmDialog(
          context: context,
          title: '指令发送成功',
          content: Text(
              '${parcel.cabCode} · ${parcel.cellDesc}\n\n已成功下发重开指令，请在柜体前确认箱门是否弹开。'),
          confirmText: '好的',
          cancelText: '',
        );
      } else {
        _showSnackBar(res.message);
      }
    }
  }

  void _showOpenBoxProgressDialog(JlbParcelInfo parcel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _OpenBoxProgressDialog(
          client: _client,
          parcel: parcel,
          onComplete: () {
            // 开箱完成后刷新状态
            _queryExpCode(parcel.expCode);
            _fetchUnpickedList(silent: true);
          },
        );
      },
    );
  }

  void _copyParcelInfo(JlbParcelInfo p) {
    final text = '运单号: ${p.expCode}\n'
        '快递柜编号: ${p.cabCode}\n'
        '格口编号: ${p.cellDesc}\n'
        '取件码: ${p.pickupCode}\n'
        '地址: ${p.addr}';
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('已复制快递柜与格口信息到剪贴板！', isSuccess: true);
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green.shade700 : null,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdaptiveTopAppBar(
        title: const Text('近邻宝快递柜助手'),
        actions: [
          AdaptiveIconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: '扫码导入凭据',
            onPressed: _openScannerPage,
          ),
          AdaptiveIconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新待取包裹',
            onPressed: () => _fetchUnpickedList(silent: false),
          ),
        ],
      ),
      body: ListView(
        padding: adaptivePagePadding(context, horizontal: 16, top: 12),
        children: [
          _buildAuthCard(),
          const SizedBox(height: 12),
          _buildQueryCard(),
          const SizedBox(height: 12),
          if (_showUnpickedList) ...[
            _buildUnpickedListSection(),
            const SizedBox(height: 12),
          ],
          if (_currentParcel != null) ...[
            _buildLockerDetailCard(_currentParcel!),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  /// 1. 微信授权与 Session 管理卡片
  Widget _buildAuthCard() {
    final scheme = Theme.of(context).colorScheme;

    return AdaptiveCard(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isSessionValid
                      ? Icons.verified_user
                      : Icons.gpp_maybe_outlined,
                  color: _isSessionValid ? Colors.green : Colors.orange,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSessionValid ? '近邻宝授权：已连接' : '近邻宝授权：未连接',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _sessionStatusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: _isSessionValid
                              ? Colors.green.shade700
                              : scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AdaptiveTextButton(
                  onPressed: () {
                    setState(() {
                      _isSessionExpanded = !_isSessionExpanded;
                    });
                  },
                  child: Text(_isSessionExpanded ? '收起配置' : '配置/管理'),
                ),
              ],
            ),
            if (_isSessionExpanded) ...[
              const Divider(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                label: const Text('电脑屏幕扫码自动导入 (推荐)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: _openScannerPage,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _sessionController,
                decoration: InputDecoration(
                  labelText: '近邻宝 Session ID',
                  hintText: '粘贴抓包获取的 sessionId 凭证',
                  isDense: true,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.content_paste, size: 20),
                    tooltip: '粘贴剪贴板',
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        _sessionController.text = data!.text!.trim();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.wechat, size: 18),
                      label: const Text('拉起微信'),
                      onPressed: _launchWeChatApp,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdaptivePrimaryButton(
                      minimumSize: const Size.fromHeight(40),
                      onPressed: _isValidatingSession ? null : () => _validateSession(),
                      child: _isValidatingSession
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('验证凭证'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '【提示】电脑运行一键提取工具生成二维码后，点击上方“扫码自动导入”对准屏幕扫描即可秒级完成授权，免手动复制。',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 2. 运单号查询操作卡片
  Widget _buildQueryCard() {
    return AdaptiveCard(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '快递单号查询',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _queryExpCode(),
                    decoration: InputDecoration(
                      hintText: '输入或粘贴快递单号',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixIcon: _expController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _expController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.content_paste, size: 20),
                  tooltip: '粘贴',
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      _expController.text = data!.text!.trim();
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
            if (_historyCodes.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 28,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _historyCodes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final code = _historyCodes[index];
                    return ActionChip(
                      label: Text(code, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        _expController.text = code;
                        _queryExpCode(code);
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AdaptivePrimaryButton(
                    minimumSize: const Size.fromHeight(42),
                    onPressed: _isQuerying ? null : () => _queryExpCode(),
                    child: _isQuerying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('查询快递柜格口'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                    onPressed: _isLoadingUnpicked
                        ? null
                        : () => _fetchUnpickedList(silent: false),
                    child: _isLoadingUnpicked
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _unpickedList.isNotEmpty
                                ? '待取件 (${_unpickedList.length})'
                                : '待取列表',
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 待取包裹列表
  Widget _buildUnpickedListSection() {
    return AdaptiveCard(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '当前待取包裹 (${_unpickedList.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                AdaptiveTextButton(
                  onPressed: () => setState(() => _showUnpickedList = false),
                  child: const Text('收起'),
                ),
              ],
            ),
            const Divider(height: 16),
            if (_unpickedList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('当前暂无待取包裹')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _unpickedList.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _unpickedList[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: item.isSmartLocker
                          ? Colors.blue.shade100
                          : Colors.orange.shade100,
                      child: Icon(
                        item.isSmartLocker ? Icons.inbox : Icons.local_shipping,
                        color: item.isSmartLocker
                            ? Colors.blue.shade700
                            : Colors.orange.shade700,
                        size: 20,
                      ),
                    ),
                    title: Text('${item.expressName} ${item.expCode}'),
                    subtitle: Text(
                      '${item.cabCode} · ${item.cellDesc} · 取件码: ${item.pickupCode}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      setState(() {
                        _currentParcel = item;
                        _expController.text = item.expCode;
                        _showUnpickedList = false;
                      });
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 3. 快递柜与格口详细卡片（核心展示区域）
  Widget _buildLockerDetailCard(JlbParcelInfo parcel) {
    final scheme = Theme.of(context).colorScheme;

    return AdaptiveCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      parcel.isSmartLocker ? Icons.lock_clock : Icons.store,
                      color: scheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      parcel.storageTypeName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: parcel.isUnpicked
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: parcel.isUnpicked
                          ? Colors.green.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    parcel.statusName,
                    style: TextStyle(
                      fontSize: 12,
                      color: parcel.isUnpicked
                          ? Colors.green.shade800
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 核心高亮：快递柜 ID 与 格子编号
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('快递柜编号/ID',
                            style: TextStyle(
                                fontSize: 12, color: Colors.blue.shade800)),
                        const SizedBox(height: 4),
                        Text(
                          parcel.cabCode,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('快递柜格子编号',
                            style: TextStyle(
                                fontSize: 12, color: Colors.red.shade800)),
                        const SizedBox(height: 4),
                        Text(
                          parcel.cellDesc,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 开箱取件码
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('开箱取件码',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        parcel.pickupCode.isNotEmpty ? parcel.pickupCode : '暂无取件码',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: '复制取件码',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: parcel.pickupCode.replaceAll(' ', '')));
                      _showSnackBar('已复制取件码: ${parcel.pickupCode}', isSuccess: true);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            _buildDetailRow('快递公司', '${parcel.expressName} (${parcel.expCode})'),
            _buildDetailRow('柜体地址', parcel.addr),
            if (parcel.createTime.isNotEmpty)
              _buildDetailRow('存入时间', parcel.createTime),

            const SizedBox(height: 16),

            // 操作按钮栏：一键开门 / 重新开箱 与 复制信息
            Row(
              children: [
                if (parcel.canOpenBox) ...[
                  Expanded(
                    flex: 3,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      icon: const Icon(Icons.lock_open, size: 20),
                      label: const Text('一键打开柜门',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      onPressed: () => _handleOpenBox(parcel),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (parcel.isSmartLocker &&
                    parcel.orderId.isNotEmpty) ...[
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade800,
                        side: BorderSide(color: Colors.orange.shade400),
                        minimumSize: const Size.fromHeight(44),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: const Text('已取走 (再次开箱)',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      onPressed: () => _handleReopenBox(parcel),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('复制详情'),
                    onPressed: () => _copyParcelInfo(parcel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// 开箱状态及传感器轮询弹窗
class _OpenBoxProgressDialog extends StatefulWidget {
  final JlbClient client;
  final JlbParcelInfo parcel;
  final VoidCallback onComplete;

  const _OpenBoxProgressDialog({
    required this.client,
    required this.parcel,
    required this.onComplete,
  });

  @override
  State<_OpenBoxProgressDialog> createState() => _OpenBoxProgressDialogState();
}

class _OpenBoxProgressDialogState extends State<_OpenBoxProgressDialog> {
  String _statusText = '正在检查包裹费用...';
  bool _isFinished = false;
  bool _isSuccess = false;
  String _errorDetail = '';
  int _secondsLeft = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startOpenProcess();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startOpenProcess() async {
    // 1. 检查滞留费用
    final chargeRes = await widget.client.getCharge(widget.parcel.orderId);
    if (chargeRes.ok && chargeRes.amountFen > 0) {
      if (mounted) {
        setState(() {
          _isFinished = true;
          _isSuccess = false;
          _statusText = '存在待支付费用';
          _errorDetail =
              '该包裹存在滞留/保管费 ${(chargeRes.amountFen / 100).toStringAsFixed(2)} 元，请先前往微信小程序缴费后再开箱。';
        });
      }
      return;
    }

    // 2. 发送开箱指令
    if (mounted) {
      setState(() => _statusText = '正在下发开箱指令...');
    }

    final quickRes = await widget.client.cabPickupQuick(
      widget.parcel.orderId,
      widget.parcel.stationId,
    );

    if (!quickRes.ok) {
      if (mounted) {
        setState(() {
          _isFinished = true;
          _isSuccess = false;
          _statusText = '指令下发失败';
          _errorDetail = quickRes.message;
        });
      }
      return;
    }

    // 3. 轮询传感器状态（10秒，每秒一次）
    if (mounted) {
      setState(() => _statusText = '指令已发送，正在等待箱门弹开 (10s)...');
    }

    _secondsLeft = 10;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      _secondsLeft--;

      final chkRes = await widget.client.cabPickupCheck(widget.parcel.orderId);
      if (chkRes.isOpened) {
        _timer?.cancel();
        if (mounted) {
          setState(() {
            _isFinished = true;
            _isSuccess = true;
            _statusText = '箱门已成功弹开！';
          });
          widget.onComplete();
        }
        return;
      }

      if (_secondsLeft <= 0) {
        _timer?.cancel();
        if (mounted) {
          setState(() {
            _isFinished = true;
            _isSuccess = false;
            _statusText = '开门超时或未检测到反馈';
            _errorDetail = '10秒内未收到传感器反馈。若现场未弹开，请再次重试或在柜机屏幕手动输入取件码。';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _statusText = '正在等待箱门弹开 (${_secondsLeft}s)...';
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isFinished
                ? (_isSuccess ? Icons.check_circle : Icons.error)
                : Icons.lock_open,
            color: _isFinished
                ? (_isSuccess ? Colors.green : Colors.red)
                : Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(_isFinished ? (_isSuccess ? '开箱成功' : '开箱未完成') : '正在开箱'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.parcel.cabCode} · ${widget.parcel.cellDesc}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(_statusText, style: const TextStyle(fontSize: 14)),
          if (!_isFinished) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (_errorDetail.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _errorDetail,
              style: TextStyle(fontSize: 13, color: Colors.red.shade700),
            ),
          ],
        ],
      ),
      actions: [
        if (_isFinished)
          AdaptiveTextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('完成'),
          ),
      ],
    );
  }
}
