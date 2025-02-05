import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomePageLogic(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('首页'),
            bottom: const TabBar(
              tabs: [
                Tab(text: '日程'),
                Tab(text: '考试'),
              ],
            ),
          ),
          body: Consumer<HomePageLogic>(
            builder: (context, logic, child) {
              if (logic.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return TabBarView(
                children: [
                  _buildSchedules(logic.schedules, logic, context),
                  _buildExams(logic.tests, logic, context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSchedules(Map<String, dynamic>? schedules, HomePageLogic logic, BuildContext context) {
    if (schedules == null) {
      return const Center(child: Text('无法获取日程安排'));
    }

    final todayClassesCount = logic.getTodayClassesCount();
    final remainingClassesCount = logic.getRemainingClassesCount();

    final sortedDates = schedules.keys.toList()
      ..sort((a, b) => a.compareTo(b)); // 升序排序

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('今日共有 $todayClassesCount 节课', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('本周剩余 $remainingClassesCount 节课', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final events = schedules[date];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ...events.map<Widget>((event) {
                    //final eventStyle = logic.getEventStyle(context);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ListTile(
                        title: Text(event['context']),
                        subtitle: Text('${event['startTime']} - ${event['endTime']} @ ${event['place']}'),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExams(List<dynamic>? exams, HomePageLogic logic, BuildContext context) {
    if (exams == null) {
      return const Center(child: Text('无法获取考试信息'));
    }

    return ListView.builder(
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        final startTime = logic.formatExamTime(exam['startTime']);
        final endTime = logic.formatExamTime(exam['endTime']);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            title: Text(exam['courseNameZh']),
            subtitle: Text('${exam['examDate']} $startTime - $endTime @ ${exam['place']}'),
          ),
        );
      },
    );
  }
}