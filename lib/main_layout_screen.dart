import 'package:flutter/material.dart';
import 'globals.dart' as globals;
import 'jwapp/login/login_view.dart';
import 'jwapp/mainpage/mainpage_view.dart';
import 'jw/login/jw_login_view.dart';
import 'jw/home/jw_main_tabs.dart';
import 'finance/login/finance_login_view.dart';
import 'finance/api/synjones_client.dart';
import 'finance/home/finance_main_tabs.dart';
import 'app_settings_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
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
    await _synjonesClient.init();
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildTabContent() {
    switch (_currentBottomIndex) {
      case 0:
        if (globals.idToken == null) {
          return JWLoginPage(
            onLoginSuccess: () {
              setState(() {});
            },
          );
        }
        return const MainPage();
      case 1:
        if (!globals.jwLoggedIn) {
          return JwLoginPage(
            onLoginSuccess: () {
              setState(() {});
            },
          );
        }
        return const JwMainTabs();
      case 2:
        if (!_synjonesClient.loggedIn) {
          return FinanceLoginPage(
            onLoginSuccess: () {
              setState(() {});
            },
          );
        }
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
