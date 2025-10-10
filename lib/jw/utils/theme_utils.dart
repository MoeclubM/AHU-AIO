import 'package:flutter/material.dart';

/// 主题工具类
class ThemeUtils {
  /// 检查是否为深色模式
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// 获取主题数据
  static ThemeData getTheme(BuildContext context) {
    return Theme.of(context);
  }

  /// 获取文本样式
  static TextStyle getTextStyle(BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    final theme = getTheme(context);
    return theme.textTheme.bodyMedium?.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? (isDarkMode(context) ? Colors.white : Colors.black87),
    ) ?? const TextStyle();
  }

  /// 获取主色调
  static Color getPrimaryColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? Colors.blue.shade600 : Colors.blue.shade700;
  }

  /// 获取背景色
  static Color getBackgroundColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? Colors.grey.shade900 : Colors.grey.shade50;
  }

  /// 获取卡片颜色
  static Color getCardColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? Colors.grey.shade800 : Colors.white;
  }

  /// 获取表面颜色
  static Color getSurfaceColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? Colors.grey.shade700 : Colors.grey.shade50;
  }

  /// 获取分割线颜色
  static Color getDividerColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? Colors.grey.shade700 : Colors.grey.shade200;
  }

  /// 获取文字颜色
  static Color getTextColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? Colors.grey.shade200 : Colors.grey.shade800;
  }

  /// 获取副文字颜色
  static Color getSecondaryTextColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
  }

  /// 获取提示文字颜色
  static Color getHintTextColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? Colors.grey.shade500 : Colors.grey.shade500;
  }

  /// 获取成功颜色
  static Color getSuccessColor(BuildContext context) {
    return Colors.green.shade600;
  }

  /// 获取错误颜色
  static Color getErrorColor(BuildContext context) {
    return Colors.red.shade600;
  }

  /// 获取警告颜色
  static Color getWarningColor(BuildContext context) {
    return Colors.orange.shade600;
  }

  /// 获取信息颜色
  static Color getInfoColor(BuildContext context) {
    return Colors.blue.shade600;
  }

  /// 获取阴影颜色
  static Color getShadowColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1);
  }

  /// 获取边框颜色
  static Color getBorderColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? Colors.grey.shade700 : Colors.grey.shade200;
  }

  /// 获取加载指示器颜色
  static Color getLoadingIndicatorColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? Colors.blue.shade300 : Colors.blue.shade600;
  }

  /// 获取 AppBar 渐变色
  static List<Color> getAppBarGradientColors(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark
        ? [Colors.blue.shade800, Colors.blue.shade600, Colors.indigo.shade700]
        : [Colors.blue.shade600, Colors.blue.shade700, Colors.indigo.shade600];
  }

  /// 获取统计卡片渐变色
  static List<Color> getStatCardGradientColors(BuildContext context, int index) {
    switch (index % 2) {
      case 0:
        return [Colors.blue.shade400, Colors.blue.shade600];
      case 1:
        return [Colors.indigo.shade400, Colors.indigo.shade600];
      default:
        return [Colors.blue.shade400, Colors.blue.shade600];
    }
  }

  /// 获取自适应的边距
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    return const EdgeInsets.all(16.0);
  }

  /// 获取自适应的圆角
  static double getAdaptiveBorderRadius(BuildContext context) {
    return 12.0;
  }

  /// 获取自适应的字体大小
  static double getAdaptiveFontSize(BuildContext context, double baseSize) {
    return baseSize;
  }
}