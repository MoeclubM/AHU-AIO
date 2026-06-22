import 'package:flutter/material.dart';
import '../home/home_view.dart';
import '../schedule/schedule_view.dart';
import 'mainpage_service.dart';
import '../funcs/func_view.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    MainPageService.checkTokenAndNavigate(context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('安大微教务'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '首页', icon: Icon(Icons.home)),
            Tab(text: '课表', icon: Icon(Icons.schedule)),
            Tab(text: '更多功能', icon: Icon(Icons.apps)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          HomePage(isVisible: _tabController.index == 0),
          const SchedulePage(),
          const FuncPage(),
        ],
      ),
    );
  }
}
