library;

import 'package:flutter/foundation.dart';

String? idToken;

// 新教务系统状态
bool jwLoggedIn = false;
String? jwStudentNo;

// 刷新主页面的回调
VoidCallback? onLoginStateChanged;
