/// 自实现的 Miuix 设计令牌层（颜色 / 文字 / 主题）。
///
/// 数值与结构对照 compose-miuix-ui 的 `Colors.kt`、`TextStyles.kt`、
/// `MiuixTheme.kt` 与 `MonetMapping.kt` 逐项对齐，**不依赖 flutter_miuix 移植包**：
/// 颜色令牌用 HyperOS 原值，动态取色用 Google 官方 `material_color_utilities`
/// 生成 MD3 角色后按 miuix 的映射规则扁平化。
library;

import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

// ---------------------------------------------------------------------------
// 颜色
// ---------------------------------------------------------------------------

/// Miuix 配色。对应 Kotlin `top.yukonga.miuix.kmp.theme.Colors`。
///
/// 字段名与官方 token 一一对应，便于与 HyperOS 规范比对；所有颜色均为不透明
/// （动态取色时带透明度的角色会先合成到背景上，与 Kotlin 端一致）。
@immutable
class MiuixColors {
  const MiuixColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryVariant,
    required this.onPrimaryVariant,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.disabledPrimary,
    required this.disabledOnPrimary,
    required this.disabledPrimaryButton,
    required this.disabledOnPrimaryButton,
    required this.disabledPrimarySlider,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryVariant,
    required this.onSecondaryVariant,
    required this.disabledSecondary,
    required this.disabledOnSecondary,
    required this.disabledSecondaryVariant,
    required this.disabledOnSecondaryVariant,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.secondaryContainerVariant,
    required this.onSecondaryContainerVariant,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.tertiaryContainerVariant,
    required this.background,
    required this.onBackground,
    required this.onBackgroundVariant,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceSecondary,
    required this.onSurfaceVariantSummary,
    required this.onSurfaceVariantActions,
    required this.disabledOnSurface,
    required this.surfaceContainer,
    required this.onSurfaceContainer,
    required this.onSurfaceContainerVariant,
    required this.surfaceContainerHigh,
    required this.onSurfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.onSurfaceContainerHighest,
    required this.outline,
    required this.dividerLine,
    required this.windowDimming,
    required this.sliderKeyPoint,
    required this.sliderKeyPointForeground,
    required this.sliderBackground,
  });

  /// 主色：Switch / Button / Slider 的强调色。
  final Color primary;
  final Color onPrimary;

  /// 主色变体：用于 Card。
  final Color primaryVariant;
  final Color onPrimaryVariant;

  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;

  /// 禁用态主色（Switch / Button / Slider 各自一套）。
  final Color disabledPrimary;
  final Color disabledOnPrimary;
  final Color disabledPrimaryButton;
  final Color disabledOnPrimaryButton;
  final Color disabledPrimarySlider;

  final Color primaryContainer;
  final Color onPrimaryContainer;

  /// 次级色：Switch 关闭态轨道等。
  final Color secondary;
  final Color onSecondary;

  /// 次级色变体：Button 默认底色。
  final Color secondaryVariant;
  final Color onSecondaryVariant;

  final Color disabledSecondary;
  final Color disabledOnSecondary;
  final Color disabledSecondaryVariant;
  final Color disabledOnSecondaryVariant;

  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color secondaryContainerVariant;
  final Color onSecondaryContainerVariant;

  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color tertiaryContainerVariant;

  /// 页面背景。
  final Color background;
  final Color onBackground;

  /// 背景上的次级文字（小标题）。
  final Color onBackgroundVariant;

  /// 顶栏等实色表面。
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;

  /// 次级文字（80% 前景）。
  final Color onSurfaceSecondary;

  /// 摘要文字（60% 前景）。
  final Color onSurfaceVariantSummary;

  /// 操作图标（40% 前景）。
  final Color onSurfaceVariantActions;
  final Color disabledOnSurface;

  /// 卡片 / 列表容器。
  final Color surfaceContainer;
  final Color onSurfaceContainer;
  final Color onSurfaceContainerVariant;
  final Color surfaceContainerHigh;
  final Color onSurfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color onSurfaceContainerHighest;

  /// 描边。
  final Color outline;

  /// 分隔线。
  final Color dividerLine;

  /// 弹窗遮罩。
  final Color windowDimming;
  final Color sliderKeyPoint;
  final Color sliderKeyPointForeground;
  final Color sliderBackground;

  /// 复制并覆盖部分颜色。
  MiuixColors copy({
    Color? primary,
    Color? onPrimary,
    Color? primaryVariant,
    Color? onPrimaryVariant,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? disabledPrimary,
    Color? disabledOnPrimary,
    Color? disabledPrimaryButton,
    Color? disabledOnPrimaryButton,
    Color? disabledPrimarySlider,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryVariant,
    Color? onSecondaryVariant,
    Color? disabledSecondary,
    Color? disabledOnSecondary,
    Color? disabledSecondaryVariant,
    Color? disabledOnSecondaryVariant,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? secondaryContainerVariant,
    Color? onSecondaryContainerVariant,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    Color? tertiaryContainerVariant,
    Color? background,
    Color? onBackground,
    Color? onBackgroundVariant,
    Color? surface,
    Color? onSurface,
    Color? surfaceVariant,
    Color? onSurfaceSecondary,
    Color? onSurfaceVariantSummary,
    Color? onSurfaceVariantActions,
    Color? disabledOnSurface,
    Color? surfaceContainer,
    Color? onSurfaceContainer,
    Color? onSurfaceContainerVariant,
    Color? surfaceContainerHigh,
    Color? onSurfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? onSurfaceContainerHighest,
    Color? outline,
    Color? dividerLine,
    Color? windowDimming,
    Color? sliderKeyPoint,
    Color? sliderKeyPointForeground,
    Color? sliderBackground,
  }) => MiuixColors(
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    primaryVariant: primaryVariant ?? this.primaryVariant,
    onPrimaryVariant: onPrimaryVariant ?? this.onPrimaryVariant,
    error: error ?? this.error,
    onError: onError ?? this.onError,
    errorContainer: errorContainer ?? this.errorContainer,
    onErrorContainer: onErrorContainer ?? this.onErrorContainer,
    disabledPrimary: disabledPrimary ?? this.disabledPrimary,
    disabledOnPrimary: disabledOnPrimary ?? this.disabledOnPrimary,
    disabledPrimaryButton: disabledPrimaryButton ?? this.disabledPrimaryButton,
    disabledOnPrimaryButton:
        disabledOnPrimaryButton ?? this.disabledOnPrimaryButton,
    disabledPrimarySlider: disabledPrimarySlider ?? this.disabledPrimarySlider,
    primaryContainer: primaryContainer ?? this.primaryContainer,
    onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
    secondary: secondary ?? this.secondary,
    onSecondary: onSecondary ?? this.onSecondary,
    secondaryVariant: secondaryVariant ?? this.secondaryVariant,
    onSecondaryVariant: onSecondaryVariant ?? this.onSecondaryVariant,
    disabledSecondary: disabledSecondary ?? this.disabledSecondary,
    disabledOnSecondary: disabledOnSecondary ?? this.disabledOnSecondary,
    disabledSecondaryVariant:
        disabledSecondaryVariant ?? this.disabledSecondaryVariant,
    disabledOnSecondaryVariant:
        disabledOnSecondaryVariant ?? this.disabledOnSecondaryVariant,
    secondaryContainer: secondaryContainer ?? this.secondaryContainer,
    onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
    secondaryContainerVariant:
        secondaryContainerVariant ?? this.secondaryContainerVariant,
    onSecondaryContainerVariant:
        onSecondaryContainerVariant ?? this.onSecondaryContainerVariant,
    tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
    tertiaryContainerVariant:
        tertiaryContainerVariant ?? this.tertiaryContainerVariant,
    background: background ?? this.background,
    onBackground: onBackground ?? this.onBackground,
    onBackgroundVariant: onBackgroundVariant ?? this.onBackgroundVariant,
    surface: surface ?? this.surface,
    onSurface: onSurface ?? this.onSurface,
    surfaceVariant: surfaceVariant ?? this.surfaceVariant,
    onSurfaceSecondary: onSurfaceSecondary ?? this.onSurfaceSecondary,
    onSurfaceVariantSummary:
        onSurfaceVariantSummary ?? this.onSurfaceVariantSummary,
    onSurfaceVariantActions:
        onSurfaceVariantActions ?? this.onSurfaceVariantActions,
    disabledOnSurface: disabledOnSurface ?? this.disabledOnSurface,
    surfaceContainer: surfaceContainer ?? this.surfaceContainer,
    onSurfaceContainer: onSurfaceContainer ?? this.onSurfaceContainer,
    onSurfaceContainerVariant:
        onSurfaceContainerVariant ?? this.onSurfaceContainerVariant,
    surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
    onSurfaceContainerHigh:
        onSurfaceContainerHigh ?? this.onSurfaceContainerHigh,
    surfaceContainerHighest:
        surfaceContainerHighest ?? this.surfaceContainerHighest,
    onSurfaceContainerHighest:
        onSurfaceContainerHighest ?? this.onSurfaceContainerHighest,
    outline: outline ?? this.outline,
    dividerLine: dividerLine ?? this.dividerLine,
    windowDimming: windowDimming ?? this.windowDimming,
    sliderKeyPoint: sliderKeyPoint ?? this.sliderKeyPoint,
    sliderKeyPointForeground:
        sliderKeyPointForeground ?? this.sliderKeyPointForeground,
    sliderBackground: sliderBackground ?? this.sliderBackground,
  );

  /// 全部字段，用于相等比较与哈希（顺序与构造函数一致）。
  List<Color> get _all => [
    primary,
    onPrimary,
    primaryVariant,
    onPrimaryVariant,
    error,
    onError,
    errorContainer,
    onErrorContainer,
    disabledPrimary,
    disabledOnPrimary,
    disabledPrimaryButton,
    disabledOnPrimaryButton,
    disabledPrimarySlider,
    primaryContainer,
    onPrimaryContainer,
    secondary,
    onSecondary,
    secondaryVariant,
    onSecondaryVariant,
    disabledSecondary,
    disabledOnSecondary,
    disabledSecondaryVariant,
    disabledOnSecondaryVariant,
    secondaryContainer,
    onSecondaryContainer,
    secondaryContainerVariant,
    onSecondaryContainerVariant,
    tertiaryContainer,
    onTertiaryContainer,
    tertiaryContainerVariant,
    background,
    onBackground,
    onBackgroundVariant,
    surface,
    onSurface,
    surfaceVariant,
    onSurfaceSecondary,
    onSurfaceVariantSummary,
    onSurfaceVariantActions,
    disabledOnSurface,
    surfaceContainer,
    onSurfaceContainer,
    onSurfaceContainerVariant,
    surfaceContainerHigh,
    onSurfaceContainerHigh,
    surfaceContainerHighest,
    onSurfaceContainerHighest,
    outline,
    dividerLine,
    windowDimming,
    sliderKeyPoint,
    sliderKeyPointForeground,
    sliderBackground,
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MiuixColors) return false;
    final List<Color> a = _all;
    final List<Color> b = other._all;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_all);
}

/// 默认浅色方案（HyperOS 原值）。
MiuixColors lightColorScheme() => const MiuixColors(
  primary: Color(0xFF3482FF),
  onPrimary: Color(0xFFFFFFFF),
  primaryVariant: Color(0xFF3482FF),
  onPrimaryVariant: Color(0xFFAECDFF),
  error: Color(0xFFE94634),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFDF6F4),
  onErrorContainer: Color(0xFF410002),
  disabledPrimary: Color(0xFFC2D9FF),
  disabledOnPrimary: Color(0xFFF3F8FF),
  disabledPrimaryButton: Color(0xFFC2D9FF),
  disabledOnPrimaryButton: Color(0xFFFFFFFF),
  disabledPrimarySlider: Color(0xFFB8CFF5),
  primaryContainer: Color(0xFF5D9BFF),
  onPrimaryContainer: Color(0xFFFFFFFF),
  secondary: Color(0xFFE6E6E6),
  onSecondary: Color(0xFFFFFFFF),
  secondaryVariant: Color(0xFFF0F0F0),
  onSecondaryVariant: Color(0xFF303030),
  disabledSecondary: Color(0xFFF0F0F0),
  disabledOnSecondary: Color(0xFFFCFCFC),
  disabledSecondaryVariant: Color(0xFFF2F2F2),
  disabledOnSecondaryVariant: Color(0xFFB2B2B2),
  secondaryContainer: Color(0xFFF0F0F0),
  onSecondaryContainer: Color(0xFFA9A9A9),
  secondaryContainerVariant: Color(0xFFF0F0F0),
  onSecondaryContainerVariant: Color(0xFFA8A8A8),
  tertiaryContainer: Color(0xFFEAF2FF),
  onTertiaryContainer: Color(0xFF3482FF),
  tertiaryContainerVariant: Color(0xFFEAF2FF),
  background: Color(0xFFFFFFFF),
  onBackground: Color(0xFF000000),
  onBackgroundVariant: Color(0xFF8C93B0),
  surface: Color(0xFFF7F7F7),
  onSurface: Color(0xFF000000),
  surfaceVariant: Color(0xFFFFFFFF),
  onSurfaceSecondary: Color(0xCC000000),
  onSurfaceVariantSummary: Color(0x99000000),
  onSurfaceVariantActions: Color(0x66000000),
  disabledOnSurface: Color(0xFFB2B2B2),
  surfaceContainer: Color(0xFFFFFFFF),
  onSurfaceContainer: Color(0xFF000000),
  onSurfaceContainerVariant: Color(0xFF959595),
  surfaceContainerHigh: Color(0xFFE8E8E8),
  onSurfaceContainerHigh: Color(0xFFA2A2A2),
  surfaceContainerHighest: Color(0xFFE8E8E8),
  onSurfaceContainerHighest: Color(0xFF000000),
  outline: Color(0xFFD9D9D9),
  dividerLine: Color(0xFFE0E0E0),
  windowDimming: Color(0x4D000000),
  sliderKeyPoint: Color(0x4DA3B3CD),
  sliderKeyPointForeground: Color(0xFF6EB5FF),
  sliderBackground: Color(0x0F000000),
);

/// 默认深色方案（HyperOS 原值）。
MiuixColors darkColorScheme() => const MiuixColors(
  primary: Color(0xFF277AF7),
  onPrimary: Color(0xFFFFFFFF),
  primaryVariant: Color(0xFF0073DD),
  onPrimaryVariant: Color(0xFF99C7F1),
  error: Color(0xFFF12522),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFF2E0603),
  onErrorContainer: Color(0xFFFFDAD6),
  disabledPrimary: Color(0xFF253E64),
  disabledOnPrimary: Color(0xFF677993),
  disabledPrimaryButton: Color(0xFF253E64),
  disabledOnPrimaryButton: Color(0xFF677893),
  disabledPrimarySlider: Color(0xFF44587C),
  primaryContainer: Color(0xFF338FE4),
  onPrimaryContainer: Color(0xFFFFFFFF),
  secondary: Color(0xFF505050),
  onSecondary: Color(0xFFFFFFFF),
  secondaryVariant: Color(0xFF434343),
  onSecondaryVariant: Color(0xFFD9D9D9),
  disabledSecondary: Color(0xFF3F3F3F),
  disabledOnSecondary: Color(0xFF797979),
  disabledSecondaryVariant: Color(0xFF404040),
  disabledOnSecondaryVariant: Color(0xFF707170),
  secondaryContainer: Color(0xFF434343),
  onSecondaryContainer: Color(0xFF7C7C7C),
  secondaryContainerVariant: Color(0xFF4F4F4F),
  onSecondaryContainerVariant: Color(0xFF959595),
  tertiaryContainer: Color(0xFF2B3B54),
  onTertiaryContainer: Color(0xFF4788FF),
  tertiaryContainerVariant: Color(0xFF505050),
  background: Color(0xFF242424),
  onBackground: Color(0xE6FFFFFF),
  onBackgroundVariant: Color(0xFF787E96),
  surface: Color(0xFF000000),
  onSurface: Color(0xFFF2F2F2),
  surfaceVariant: Color(0xFF242424),
  onSurfaceSecondary: Color(0xCCFFFFFF),
  onSurfaceVariantSummary: Color(0x80FFFFFF),
  onSurfaceVariantActions: Color(0x66FFFFFF),
  disabledOnSurface: Color(0xFF666666),
  surfaceContainer: Color(0xFF242424),
  onSurfaceContainer: Color(0xE6FFFFFF),
  onSurfaceContainerVariant: Color(0xFF737373),
  surfaceContainerHigh: Color(0xFF242424),
  onSurfaceContainerHigh: Color(0xFF666666),
  surfaceContainerHighest: Color(0xFF2D2D2D),
  onSurfaceContainerHighest: Color(0xFFE9E9E9),
  outline: Color(0xFF404040),
  dividerLine: Color(0xFF393939),
  windowDimming: Color(0x99000000),
  sliderKeyPoint: Color(0x4D7A8AA6),
  sliderKeyPointForeground: Color(0xFF5DAAFF),
  sliderBackground: Color(0x26FFFFFF),
);

// ---------------------------------------------------------------------------
// 动态取色（种子色 → 整套配色）
// ---------------------------------------------------------------------------

/// 动态配色的调色板风格。对应 Kotlin `ThemePaletteStyle`。
enum MiuixPaletteStyle {
  tonalSpot,
  neutral,
  vibrant,
  expressive,
  rainbow,
  fruitSalad,
  monochrome,
  fidelity,
  content,
}

/// 把前景色按 alpha 合成到背景色上。
Color _compositeOver(Color fg, Color bg) {
  final double fa = fg.a;
  final double ba = bg.a;
  final double outA = fa + ba * (1 - fa);
  if (outA == 0) return const Color(0x00000000);
  return Color.from(
    alpha: outA,
    red: (fg.r * fa + bg.r * ba * (1 - fa)) / outA,
    green: (fg.g * fa + bg.g * ba * (1 - fa)) / outA,
    blue: (fg.b * fa + bg.b * ba * (1 - fa)) / outA,
  );
}

/// 合成后丢弃 alpha，得到不透明色。
Color _opaqueOver(Color fg, Color bg) {
  final Color c = _compositeOver(fg, bg);
  return Color.from(alpha: 1, red: c.r, green: c.g, blue: c.b);
}

Color _ensureOpaqueOver(Color fg, Color bg) =>
    fg.a >= 1 ? fg : _opaqueOver(fg, bg);

/// 从种子色生成整套 Miuix 配色。对应 Kotlin `colorsFromSeed`。
///
/// 用官方 `material_color_utilities` 的 [DynamicScheme] 提取 MD3 角色，
/// 再按 miuix 的映射规则扁平化为 [MiuixColors]（带透明度的角色会先合成到
/// 对应背景上，保证全部不透明）。
MiuixColors miuixColorsFromSeed({
  required Color seed,
  required bool dark,
  MiuixPaletteStyle paletteStyle = MiuixPaletteStyle.tonalSpot,
}) {
  final Hct hct = Hct.fromInt(_argbOf(seed));
  const double contrast = 0.0;
  final DynamicScheme s = switch (paletteStyle) {
    MiuixPaletteStyle.tonalSpot => SchemeTonalSpot(
      sourceColorHct: hct,
      isDark: dark,
      contrastLevel: contrast,
    ),
    MiuixPaletteStyle.neutral => SchemeNeutral(
      sourceColorHct: hct,
      isDark: dark,
      contrastLevel: contrast,
    ),
    MiuixPaletteStyle.vibrant => SchemeVibrant(
      sourceColorHct: hct,
      isDark: dark,
      contrastLevel: contrast,
    ),
    MiuixPaletteStyle.expressive => SchemeExpressive(
      sourceColorHct: hct,
      isDark: dark,
      contrastLevel: contrast,
    ),
    MiuixPaletteStyle.rainbow => SchemeRainbow(
      sourceColorHct: hct,
      isDark: dark,
      contrastLevel: contrast,
    ),
    MiuixPaletteStyle.fruitSalad => SchemeFruitSalad(
      sourceColorHct: hct,
      isDark: dark,
      contrastLevel: contrast,
    ),
    MiuixPaletteStyle.monochrome => SchemeMonochrome(
      sourceColorHct: hct,
      isDark: dark,
      contrastLevel: contrast,
    ),
    MiuixPaletteStyle.fidelity => SchemeFidelity(
      sourceColorHct: hct,
      isDark: dark,
      contrastLevel: contrast,
    ),
    MiuixPaletteStyle.content => SchemeContent(
      sourceColorHct: hct,
      isDark: dark,
      contrastLevel: contrast,
    ),
  };

  Color role(DynamicColor c) => Color(c.getArgb(s));

  final Color primary = role(MaterialDynamicColors.primary);
  final Color onPrimary = role(MaterialDynamicColors.onPrimary);
  final Color surface = role(MaterialDynamicColors.surface);
  final Color onSurface = role(MaterialDynamicColors.onSurface);
  final Color surfaceContainerHigh = role(
    MaterialDynamicColors.surfaceContainerHigh,
  );
  final Color outlineVariant = role(MaterialDynamicColors.outlineVariant);
  final Color primaryDisabled = _ensureOpaqueOver(
    primary.withValues(alpha: 0.38),
    surface,
  );
  final Color disabledSecondary = _ensureOpaqueOver(
    outlineVariant.withValues(alpha: 0.5),
    surface,
  );
  final Color disabledSecondaryVariant = _ensureOpaqueOver(
    surfaceContainerHigh.withValues(alpha: 0.6),
    surface,
  );

  return MiuixColors(
    primary: primary,
    onPrimary: onPrimary,
    primaryVariant: role(MaterialDynamicColors.primaryFixed),
    onPrimaryVariant: role(MaterialDynamicColors.onPrimaryFixed),
    error: role(MaterialDynamicColors.error),
    onError: role(MaterialDynamicColors.onError),
    errorContainer: role(MaterialDynamicColors.errorContainer),
    onErrorContainer: role(MaterialDynamicColors.onErrorContainer),
    disabledPrimary: primaryDisabled,
    disabledOnPrimary: _ensureOpaqueOver(
      onPrimary.withValues(alpha: 0.38),
      primaryDisabled,
    ),
    disabledPrimaryButton: primaryDisabled,
    disabledOnPrimaryButton: _ensureOpaqueOver(
      onPrimary.withValues(alpha: 0.6),
      primaryDisabled,
    ),
    disabledPrimarySlider: primaryDisabled,
    primaryContainer: role(MaterialDynamicColors.primaryContainer),
    onPrimaryContainer: role(MaterialDynamicColors.onPrimaryContainer),
    secondary: outlineVariant,
    onSecondary: role(MaterialDynamicColors.outline),
    secondaryVariant: surfaceContainerHigh,
    onSecondaryVariant: onSurface,
    disabledSecondary: disabledSecondary,
    disabledOnSecondary: _ensureOpaqueOver(
      onSurface.withValues(alpha: 0.38),
      disabledSecondary,
    ),
    disabledSecondaryVariant: disabledSecondaryVariant,
    disabledOnSecondaryVariant: _ensureOpaqueOver(
      onSurface.withValues(alpha: 0.38),
      disabledSecondaryVariant,
    ),
    secondaryContainer: role(MaterialDynamicColors.secondaryContainer),
    onSecondaryContainer: role(MaterialDynamicColors.onSecondaryContainer),
    secondaryContainerVariant: role(
      MaterialDynamicColors.surfaceContainerHighest,
    ),
    onSecondaryContainerVariant: role(MaterialDynamicColors.onSurfaceVariant),
    tertiaryContainer: role(MaterialDynamicColors.tertiaryContainer),
    onTertiaryContainer: role(MaterialDynamicColors.onTertiaryContainer),
    tertiaryContainerVariant: role(MaterialDynamicColors.onTertiaryContainer),
    background: role(MaterialDynamicColors.background),
    onBackground: role(MaterialDynamicColors.onBackground),
    onBackgroundVariant: primary,
    surface: surface,
    onSurface: onSurface,
    surfaceVariant: role(MaterialDynamicColors.surfaceVariant),
    onSurfaceSecondary: _ensureOpaqueOver(
      onSurface.withValues(alpha: 0.8),
      surface,
    ),
    onSurfaceVariantSummary: role(MaterialDynamicColors.onSurfaceVariant),
    onSurfaceVariantActions: role(MaterialDynamicColors.onSurfaceVariant),
    disabledOnSurface: onSurface,
    surfaceContainer: role(MaterialDynamicColors.surfaceContainer),
    onSurfaceContainer: onSurface,
    onSurfaceContainerVariant: role(MaterialDynamicColors.onSurfaceVariant),
    surfaceContainerHigh: surfaceContainerHigh,
    onSurfaceContainerHigh: _ensureOpaqueOver(
      onSurface.withValues(alpha: 0.8),
      surfaceContainerHigh,
    ),
    surfaceContainerHighest: role(
      MaterialDynamicColors.surfaceContainerHighest,
    ),
    onSurfaceContainerHighest: onSurface,
    outline: role(MaterialDynamicColors.outline),
    dividerLine: outlineVariant,
    windowDimming: dark ? const Color(0x99000000) : const Color(0x4D000000),
    sliderKeyPoint: primary,
    sliderKeyPointForeground: surfaceContainerHigh,
    sliderBackground: _ensureOpaqueOver(
      primary.withValues(alpha: 0.2),
      surface,
    ),
  );
}

/// 取 [Color] 的 ARGB int，供 `Hct.fromInt` 使用。
int _argbOf(Color c) {
  int ch(double v) => (v * 255).round().clamp(0, 255);
  return (ch(c.a) << 24) | (ch(c.r) << 16) | (ch(c.g) << 8) | ch(c.b);
}

// ---------------------------------------------------------------------------
// 文字
// ---------------------------------------------------------------------------

/// Miuix 文本样式集。对应 Kotlin `TextStyles`。
///
/// 只定义字号 / 字重 / 行高，运行时颜色由使用处按语义（`onBackground`、
/// `onSurfaceVariantSummary` 等）指定。
@immutable
class MiuixTextStyles {
  const MiuixTextStyles({
    required this.main,
    required this.paragraph,
    required this.body1,
    required this.body2,
    required this.button,
    required this.footnote1,
    required this.footnote2,
    required this.headline1,
    required this.headline2,
    required this.subtitle,
    required this.title1,
    required this.title2,
    required this.title3,
    required this.title4,
  });

  /// 主文本 17sp。
  final TextStyle main;

  /// 段落 17sp / 行高 1.2。
  final TextStyle paragraph;

  /// 正文 16sp。
  final TextStyle body1;

  /// 正文 14sp。
  final TextStyle body2;

  /// 按钮 17sp。
  final TextStyle button;

  /// 脚注 13sp / 11sp。
  final TextStyle footnote1;
  final TextStyle footnote2;

  /// 标题行 17sp / 16sp（列表项标题）。
  final TextStyle headline1;
  final TextStyle headline2;

  /// 副标题 14sp 加粗（分组小标题）。
  final TextStyle subtitle;

  /// 大标题 32sp / 24sp / 20sp / 18sp。
  final TextStyle title1;
  final TextStyle title2;
  final TextStyle title3;
  final TextStyle title4;
}

/// 默认文本样式（Miuix 规范）。
MiuixTextStyles defaultTextStyles() => const MiuixTextStyles(
  main: TextStyle(fontSize: 17),
  paragraph: TextStyle(fontSize: 17, height: 1.2),
  body1: TextStyle(fontSize: 16),
  body2: TextStyle(fontSize: 14),
  button: TextStyle(fontSize: 17),
  footnote1: TextStyle(fontSize: 13),
  footnote2: TextStyle(fontSize: 11),
  headline1: TextStyle(fontSize: 17),
  headline2: TextStyle(fontSize: 16),
  subtitle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
  title1: TextStyle(fontSize: 32),
  title2: TextStyle(fontSize: 24),
  title3: TextStyle(fontSize: 20),
  title4: TextStyle(fontSize: 18),
);

/// 按 [adjustment] 偏移字重，对应 Android 的
/// `Configuration.fontWeightAdjustment`（跟随系统字体粗细）。
///
/// 100 为一档：+100 时 w400→w500、w600→w700。[weight] 为 null 按 w400 处理；
/// [adjustment] 为 0 时原样返回。
FontWeight? adjustFontWeight(FontWeight? weight, int adjustment) {
  if (adjustment == 0) return weight;
  final int base = (weight ?? FontWeight.w400).value;
  final int idx = ((base + adjustment) ~/ 100 - 1).clamp(
    0,
    FontWeight.values.length - 1,
  );
  return FontWeight.values[idx];
}

/// 在任意 [TextStyle] 上应用 Miuix 字重偏移。
extension MiuixFontWeightAdjustment on TextStyle {
  TextStyle withMiuixWeight(int adjustment) => adjustment == 0
      ? this
      : copyWith(fontWeight: adjustFontWeight(fontWeight, adjustment));
}

// ---------------------------------------------------------------------------
// 主题
// ---------------------------------------------------------------------------

/// 不可变的 Miuix 主题数据，聚合 [colors]、[textStyles] 与 [brightness]。
@immutable
class MiuixThemeData {
  const MiuixThemeData({
    required this.colors,
    required this.textStyles,
    required this.brightness,
    this.fontWeightAdjustment = 0,
  });

  final MiuixColors colors;
  final MiuixTextStyles textStyles;
  final Brightness brightness;

  /// 全局字重偏移量（100 为一档），通常由系统「粗体文字」驱动。
  final int fontWeightAdjustment;

  factory MiuixThemeData.light({
    MiuixColors? colors,
    MiuixTextStyles? textStyles,
    int fontWeightAdjustment = 0,
  }) => MiuixThemeData(
    colors: colors ?? lightColorScheme(),
    textStyles: textStyles ?? defaultTextStyles(),
    brightness: Brightness.light,
    fontWeightAdjustment: fontWeightAdjustment,
  );

  factory MiuixThemeData.dark({
    MiuixColors? colors,
    MiuixTextStyles? textStyles,
    int fontWeightAdjustment = 0,
  }) => MiuixThemeData(
    colors: colors ?? darkColorScheme(),
    textStyles: textStyles ?? defaultTextStyles(),
    brightness: Brightness.dark,
    fontWeightAdjustment: fontWeightAdjustment,
  );

  /// 按 [brightness] 选择浅色 / 深色配色。
  factory MiuixThemeData.of(
    Brightness brightness, {
    MiuixColors? lightColors,
    MiuixColors? darkColors,
    MiuixTextStyles? textStyles,
    int fontWeightAdjustment = 0,
  }) {
    final bool isDark = brightness == Brightness.dark;
    return MiuixThemeData(
      colors: isDark
          ? (darkColors ?? darkColorScheme())
          : (lightColors ?? lightColorScheme()),
      textStyles: textStyles ?? defaultTextStyles(),
      brightness: brightness,
      fontWeightAdjustment: fontWeightAdjustment,
    );
  }

  MiuixThemeData copyWith({
    MiuixColors? colors,
    MiuixTextStyles? textStyles,
    Brightness? brightness,
    int? fontWeightAdjustment,
  }) => MiuixThemeData(
    colors: colors ?? this.colors,
    textStyles: textStyles ?? this.textStyles,
    brightness: brightness ?? this.brightness,
    fontWeightAdjustment: fontWeightAdjustment ?? this.fontWeightAdjustment,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MiuixThemeData &&
          other.colors == colors &&
          other.textStyles == textStyles &&
          other.brightness == brightness &&
          other.fontWeightAdjustment == fontWeightAdjustment);

  @override
  int get hashCode =>
      Object.hash(colors, textStyles, brightness, fontWeightAdjustment);
}

/// 向子树提供 [MiuixThemeData]。对应 Kotlin 的 `MiuixTheme { ... }`。
class MiuixTheme extends InheritedWidget {
  const MiuixTheme({super.key, required this.data, required super.child});

  final MiuixThemeData data;

  /// 读取当前主题；未包裹时回退到浅色默认值。
  static MiuixThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MiuixTheme>()?.data ??
      MiuixThemeData.light();

  /// 只读取不建立依赖。
  static MiuixThemeData? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MiuixTheme>()?.data;

  @override
  bool updateShouldNotify(MiuixTheme oldWidget) => data != oldWidget.data;
}

/// 上下文扩展：`context.miuixTheme` / `context.miuixColors`。
extension MiuixContextExt on BuildContext {
  MiuixThemeData get miuixTheme => MiuixTheme.of(this);
  MiuixColors get miuixColors => MiuixTheme.of(this).colors;
}
