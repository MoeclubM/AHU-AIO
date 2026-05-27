import 'package:flutter/material.dart';
import 'jw_webview_page.dart';

class JwCourseSelectPage extends StatelessWidget {
  const JwCourseSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const JwWebViewPage(
      title: '选课系统',
      url: 'https://jw.ahu.edu.cn/student/for-std/course-select',
    );
  }
}
