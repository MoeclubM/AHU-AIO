import 'package:flutter/material.dart';
import '../utils/theme_utils.dart';

/// 通用UI组件
class CommonWidgets {
  /// 构建加载指示器
  static Widget buildLoadingIndicator({
    required BuildContext context,
    String? message,
    double? size,
  }) {
    return Card.filled(
      color: ThemeUtils.getCardColor(context),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size ?? 40,
              height: size ?? 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ThemeUtils.getLoadingIndicatorColor(context),
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 20),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: ThemeUtils.getTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建错误状态
  static Widget buildErrorState({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? actionText,
    VoidCallback? onAction,
    IconData? icon,
  }) {
    return Card.filled(
      color: ThemeUtils.getCardColor(context),
      elevation: 0,
      margin: const EdgeInsets.all(32),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeUtils.getWarningColor(context).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                size: 48,
                color: ThemeUtils.getWarningColor(context),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ThemeUtils.getTextColor(context),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: ThemeUtils.getSecondaryTextColor(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: ThemeUtils.getAppBarGradientColors(context),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeUtils.getPrimaryColor(context).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: Text(actionText, style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建空状态
  static Widget buildEmptyState({
    required BuildContext context,
    required String title,
    String? subtitle,
    IconData? icon,
    Color? iconColor,
  }) {
    return Card.filled(
      color: ThemeUtils.getCardColor(context),
      elevation: 0,
      margin: const EdgeInsets.all(32),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (iconColor ?? ThemeUtils.getInfoColor(context)).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon ?? Icons.info_outline,
                size: 48,
                color: iconColor ?? ThemeUtils.getInfoColor(context),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ThemeUtils.getTextColor(context),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: ThemeUtils.getSecondaryTextColor(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建统一的卡片
  static Widget buildCard({
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Color? color,
    double? elevation,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: margin,
      child: Card.filled(
        color: color,
        elevation: elevation ?? 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ),
    );
  }

  /// 构建统计卡片
  static Widget buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int count,
    required int index,
    VoidCallback? onTap,
  }) {
    final colors = ThemeUtils.getStatCardGradientColors(context, index);

    return Card(
      elevation: 2,
      shadowColor: colors.first.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colors.first.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建分割线
  static Widget buildDivider({
    required BuildContext context,
    double? height,
    double? thickness,
    Color? color,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      height: height,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: color ?? ThemeUtils.getDividerColor(context),
            width: thickness ?? 1,
          ),
        ),
      ),
    );
  }

  /// 构建带图标的文本行
  static Widget buildIconTextRow({
    required BuildContext context,
    required IconData icon,
    required String text,
    Color? iconColor,
    Color? textColor,
    double? iconSize,
    double? fontSize,
    double? spacing,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: iconSize ?? 16,
          color: iconColor ?? ThemeUtils.getSecondaryTextColor(context),
        ),
        SizedBox(width: spacing ?? 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize ?? 13,
              color: textColor ?? ThemeUtils.getTextColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}