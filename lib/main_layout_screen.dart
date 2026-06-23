import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart' as globals;
import 'jwapp/mainpage/mainpage_view.dart';
import 'jw/home/jw_main_tabs.dart';
import 'finance/api/synjones_client.dart';
import 'finance/home/finance_main_tabs.dart';
import 'app_settings_screen.dart';
import 'auth/unified_login_page.dart';
import 'auth/cas_auth_cache.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  bool _isInitializing = true;
  int _currentBottomIndex = 0;
  final SynjonesClient _synjonesClient = SynjonesClient();

  @override
  void initState() {
    super.initState();
    // Register the global state change notifier
    globals.onLoginStateChanged = _onLoginStateChanged;
    _checkInit();
  }

  @override
  void dispose() {
    if (globals.onLoginStateChanged == _onLoginStateChanged) {
      globals.onLoginStateChanged = null;
    }
    super.dispose();
  }

  void _onLoginStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _checkInit() async {
    setState(() {
      _isInitializing = true;
    });
    await _synjonesClient.init();
    final prefs = await SharedPreferences.getInstance();
    final cachedIdToken = prefs.getString('idToken');
    if (cachedIdToken != null) {
      globals.idToken = cachedIdToken;
    }
    globals.jwLoggedIn = await CasAuthCache.isLoggedIn();
    globals.jwStudentNo = prefs.getString('jwStudentNo');
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Widget _buildTabContent() {
    switch (_currentBottomIndex) {
      case 0:
        return const MainPage();
      case 1:
        return const JwMainTabs();
      case 2:
        return const FinanceMainTabs();
      case 3:
        return AppSettingsScreen(
          onSwitchTab: (index) {
            setState(() {
              _currentBottomIndex = index;
            });
          },
        );
      default:
        return const Center(child: Text('未知页面'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isLoggedIn =
        globals.idToken != null ||
        globals.jwLoggedIn ||
        _synjonesClient.loggedIn;

    if (!isLoggedIn) {
      return UnifiedLoginPage(
        onLoginSuccess: () {
          setState(() {});
        },
      );
    }

    return Scaffold(
      body: _buildTabContent(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentBottomIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentBottomIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt),
            label: '微教务',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: '安大教务',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card),
            label: '一卡通',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
