import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'schedule_service.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScheduleService(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('课表'),
        ),
        body: Consumer<ScheduleService>(
          builder: (context, logic, child) {
            if (logic.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (logic.classes == null || logic.table == null) {
              return const Center(child: Text('无法获取课表信息'));
            }

            final processedClasses = logic.processClasses();
            final timeKeys = processedClasses.keys.toList()..sort();

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: isMobile ? Axis.horizontal : Axis.vertical,
                    child: Table(
                      border: TableBorder.all(color: Colors.grey),
                      defaultColumnWidth: isMobile ? FixedColumnWidth(120.0) : IntrinsicColumnWidth(),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.blueAccent),
                          children: [
                            TableCell(child: Center(child: Text('时间段', style: TextStyle(color: Colors.white)))),
                            TableCell(child: Center(child: Text('周一', style: TextStyle(color: Colors.white)))),
                            TableCell(child: Center(child: Text('周二', style: TextStyle(color: Colors.white)))),
                            TableCell(child: Center(child: Text('周三', style: TextStyle(color: Colors.white)))),
                            TableCell(child: Center(child: Text('周四', style: TextStyle(color: Colors.white)))),
                            TableCell(child: Center(child: Text('周五', style: TextStyle(color: Colors.white)))),
                            TableCell(child: Center(child: Text('周六', style: TextStyle(color: Colors.white)))),
                            TableCell(child: Center(child: Text('周日', style: TextStyle(color: Colors.white)))),
                          ],
                        ),
                        ...timeKeys.map((timeKey) {
                          final weekdays = processedClasses[timeKey]!;

                          return TableRow(
                            children: [
                              TableCell(child: Center(child: Text(timeKey))),
                              ...List.generate(7, (index) {
                                final weekday = '周${index + 1}';
                                final classes = weekdays[weekday] ?? [];

                                return TableCell(
                                  child: Column(
                                    children: classes.map((classItem) {
                                      return InkWell(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(classItem['courseName']),
                                                content: SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: classItem['details'].map<Widget>((detail) {
                                                      final date = detail['date'];
                                                      final startTime = logic.formatTime(detail['startTime']);
                                                      final endTime = logic.formatTime(detail['endTime']);
                                                      final roomName = detail['room']?['nameZh'] ?? '未知教室';
                                                      final teacherName = classItem['teacherName'];
                                                      return Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                        child: Text('日期: $date\n时间: $startTime - $endTime\n教室: $roomName\n教师: $teacherName'),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: const Text('关闭'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: Colors.lightBlueAccent,
                                            borderRadius: BorderRadius.circular(8.0),
                                          ),
                                          child: Text('${classItem['courseName']} @ ${classItem['roomName']}'),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              }),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}