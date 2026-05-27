import 'package:flutter/material.dart';
import 'jw_webview_page.dart';

class JwStudentInfoPage extends StatelessWidget {
  const JwStudentInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const JwWebViewPage(
      title: '学籍信息',
      url: 'https://jw.ahu.edu.cn/student/for-std/student-info',
    );
  }
}
