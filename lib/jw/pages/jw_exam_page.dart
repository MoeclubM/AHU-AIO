import 'package:flutter/material.dart';
import 'jw_webview_page.dart';

class JwExamPage extends StatelessWidget {
  const JwExamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const JwWebViewPage(
      title: '考试安排',
      url: 'https://jw.ahu.edu.cn/student/for-std/exam-arrange',
    );
  }
}
