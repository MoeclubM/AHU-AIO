import 'package:flutter/material.dart';
import 'jw_webview_page.dart';

class JwPrecautionPage extends StatelessWidget {
  const JwPrecautionPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 尝试多个可能的路径
    return const JwWebViewPage(
      title: '学业预警',
      url: 'https://jw.ahu.edu.cn/student/for-std/precaution',
    );
  }
}
