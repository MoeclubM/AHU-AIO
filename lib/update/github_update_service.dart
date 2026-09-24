import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_version.dart';

/// GitHub 仓库标识（与 README / CI 一致）。
const String kGitHubOwner = 'MoeclubM';
const String kGitHubRepo = 'AHU-AIO';

/// GitHub Releases API：取最新正式 Release。
final Uri kGitHubLatestReleaseUrl = Uri.parse(
  'https://api.github.com/repos/$kGitHubOwner/$kGitHubRepo/releases/latest',
);

/// Release 页面（用户手动下载兜底）。
final Uri kGitHubReleasesPageUrl = Uri.parse(
  'https://github.com/$kGitHubOwner/$kGitHubRepo/releases',
);

/// 已提示过的版本号在本地的存储键，避免同一版本反复弹窗。
const String _kDismissedUpdateTagKey = 'update_dismissed_tag';

/// Release 资产描述。
class ReleaseAsset {
  const ReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });

  final String name;
  final String downloadUrl;
  final int size;

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: (json['name'] as String?) ?? '',
      downloadUrl: (json['browser_download_url'] as String?) ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}

/// GitHub Release 信息 + 与本机相关的下载项。
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.tagName,
    required this.version,
    required this.releaseNotes,
    required this.htmlUrl,
    required this.publishedAt,
    required this.assets,
    this.matchedAsset,
    this.currentVersion = '',
  });

  /// 原始 tag，如 `v1.0.9`。
  final String tagName;

  /// 规范化版本号，如 `1.0.9`。
  final String version;
  final String releaseNotes;
  final String htmlUrl;
  final DateTime? publishedAt;
  final List<ReleaseAsset> assets;

  /// 适配当前平台/架构的下载包；无匹配时为 null（仍可跳转 Release 页）。
  final ReleaseAsset? matchedAsset;

  /// 本机当前版本（展示用）。
  final String currentVersion;

  bool get hasDownload =>
      matchedAsset != null && matchedAsset!.downloadUrl.isNotEmpty;
}

/// 语义化版本（`major.minor.patch`，可选 `+build` / `-prerelease`）。
class AppVersion implements Comparable<AppVersion> {
  const AppVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.build,
    this.prerelease = '',
  });

  final int major;
  final int minor;
  final int patch;
  final int? build;
  final String prerelease;

  /// 纯主版本号（不含 prerelease 与 build）。
  AppVersion get baseVersion =>
      AppVersion(major: major, minor: minor, patch: patch);

  /// 非正式发布构建（CI beta / 本地 debug 等，版本号含 `-prerelease`）。
  ///
  /// CI beta 版本形如 `1.0.9-beta.5.abc1234`，代码可能比同号正式 Release 更新，
  /// 不应用 GitHub Release 覆盖安装。
  bool get isNonReleaseBuild => prerelease.isNotEmpty;

  /// 解析 `1.2.3` / `v1.2.3` / `1.2.3+45` / `1.2.3-beta.1` 等。
  static AppVersion? tryParse(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('v') || s.startsWith('V')) {
      s = s.substring(1);
    }
    // 去掉 +build
    int? build;
    final plus = s.indexOf('+');
    if (plus >= 0) {
      build = int.tryParse(s.substring(plus + 1).trim());
      s = s.substring(0, plus);
    }
    // 拆 prerelease
    String pre = '';
    final dash = s.indexOf('-');
    if (dash >= 0) {
      pre = s.substring(dash + 1).trim();
      s = s.substring(0, dash);
    }
    final parts = s.split('.');
    if (parts.isEmpty || parts.length > 3) return null;
    final nums = <int>[];
    for (final p in parts) {
      final n = int.tryParse(p.trim());
      if (n == null) return null;
      nums.add(n);
    }
    while (nums.length < 3) {
      nums.add(0);
    }
    return AppVersion(
      major: nums[0],
      minor: nums[1],
      patch: nums[2],
      build: build,
      prerelease: pre,
    );
  }

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    // 有 prerelease 的小于同号正式版
    final preCmp = _comparePrerelease(prerelease, other.prerelease);
    if (preCmp != 0) return preCmp;
    final b1 = build ?? 0;
    final b2 = other.build ?? 0;
    return b1.compareTo(b2);
  }

  static int _comparePrerelease(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 0;
    if (a.isEmpty) return 1;
    if (b.isEmpty) return -1;
    return a.compareTo(b);
  }

  bool operator <(AppVersion other) => compareTo(other) < 0;
  bool operator >(AppVersion other) => compareTo(other) > 0;
  bool operator <=(AppVersion other) => compareTo(other) <= 0;
  bool operator >=(AppVersion other) => compareTo(other) >= 0;

  @override
  String toString() {
    final base = '$major.$minor.$patch';
    return prerelease.isEmpty ? base : '$base-$prerelease';
  }
}

/// 按平台/架构挑选 Release 资产（命名与 `.github/workflows/main.yml` 一致）。
ReleaseAsset? pickAssetForPlatform(
  List<ReleaseAsset> assets, {
  String? operatingSystem,
  String? architecture,
}) {
  final os = (operatingSystem ?? Platform.operatingSystem).toLowerCase();
  final arch = (architecture ?? _normalizedArch()).toLowerCase();

  late final String osKeyword;
  late final List<String> archKeywords;
  late final List<String> extKeywords;

  if (os == 'android') {
    osKeyword = 'android';
    // 优先 arm64，其次 x86_64
    if (arch.contains('arm64') || arch.contains('aarch64')) {
      archKeywords = ['arm64'];
    } else if (arch.contains('x64') ||
        arch.contains('x86_64') ||
        arch.contains('amd64')) {
      archKeywords = ['x86_64'];
    } else {
      archKeywords = ['arm64', 'x86_64'];
    }
    extKeywords = ['.apk'];
  } else if (os == 'windows') {
    osKeyword = 'windows';
    archKeywords = ['x64', 'x86_64', 'win'];
    extKeywords = ['.zip'];
  } else if (os == 'linux') {
    osKeyword = 'linux';
    archKeywords = ['x86_64', 'x64', 'amd64', 'arm64'];
    extKeywords = ['.tar.gz', '.tgz', '.zip', '.AppImage'];
  } else if (os == 'macos' || os == 'ios') {
    osKeyword = 'macos';
    archKeywords = ['universal', 'arm64', 'x64'];
    extKeywords = ['.zip', '.dmg', '.tar.gz'];
  } else {
    return null;
  }

  // 排除 Beta 产物，只取正式 Release 包。
  final candidates = assets.where((a) {
    final n = a.name.toLowerCase();
    if (n.contains('beta')) return false;
    if (!n.contains(osKeyword)) return false;
    return extKeywords.any(n.endsWith);
  }).toList();

  for (final archKey in archKeywords) {
    for (final a in candidates) {
      if (a.name.toLowerCase().contains(archKey) && a.downloadUrl.isNotEmpty) {
        return a;
      }
    }
  }
  // 无架构匹配时退回同平台任意包
  for (final a in candidates) {
    if (a.downloadUrl.isNotEmpty) return a;
  }
  return null;
}

String _normalizedArch() {
  if (Platform.isWindows) {
    final envArch = (Platform.environment['PROCESSOR_ARCHITECTURE'] ?? '')
        .toUpperCase();
    if (envArch.contains('ARM')) return 'arm64';
    return 'x64';
  }
  // Flutter 在 Android/Linux/macOS 上的 Platform.version 形如
  // `3.x.x (stable) ... on "android_arm64"`，可据此识别 ABI。
  final v = Platform.version.toLowerCase();
  if (v.contains('arm64') || v.contains('aarch64')) return 'arm64';
  if (v.contains('x64') || v.contains('x86_64') || v.contains('amd64')) {
    return 'x64';
  }
  // 手机端默认 arm64。
  return Platform.isAndroid ? 'arm64' : 'x64';
}

/// 从 GitHub 拉取并解析最新 Release。网络/解析失败抛 [UpdateException]。
class GitHubUpdateService {
  GitHubUpdateService({http.Client? client, this.currentVersionOverride})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// 单元测试注入的版本号；为空时读运行时/源码声明版本。
  final String? currentVersionOverride;

  /// 当前应用版本（含构建号或 beta 后缀），如 `1.0.9+10009` / `1.0.9-beta.5.abc`。
  Future<String> currentVersionString() async {
    final override = currentVersionOverride;
    if (override != null && override.isNotEmpty) return override;
    try {
      final info = await PackageInfo.fromPlatform();
      final v = info.version.trim();
      final b = info.buildNumber.trim();
      if (v.isNotEmpty) {
        return b.isEmpty ? v : '$v+$b';
      }
    } catch (_) {
      // 插件不可用时回退到源码声明版本。
    }
    return kAppVersionDisplay;
  }

  /// 解析后的当前版本。
  Future<AppVersion?> currentVersion() async {
    return AppVersion.tryParse(await currentVersionString());
  }

  /// 当前是否为 beta/debug 等非正式发布构建。
  Future<bool> isNonReleaseBuild() async {
    final v = await currentVersion();
    return v?.isNonReleaseBuild ?? false;
  }

  /// 拉取最新 Release 并组装 [AppUpdateInfo]。
  Future<AppUpdateInfo> fetchLatestRelease() async {
    final http.Response response;
    try {
      response = await _client
          .get(
            kGitHubLatestReleaseUrl,
            headers: const {
              'accept': 'application/vnd.github+json',
              'user-agent': 'AHU-AIO-Updater',
              'x-github-api-version': '2022-11-28',
            },
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw UpdateException('无法连接 GitHub，请检查网络后重试');
    }

    if (response.statusCode == 404) {
      throw UpdateException('仓库暂无正式 Release');
    }
    if (response.statusCode == 403 || response.statusCode == 429) {
      throw UpdateException('GitHub API 请求过于频繁，请稍后再试');
    }
    if (response.statusCode != 200) {
      throw UpdateException('GitHub 返回错误（HTTP ${response.statusCode}）');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw UpdateException('Release 数据解析失败');
    }

    return parseReleaseJson(json, currentVersion: await currentVersionString());
  }

  /// 将 API JSON 解析为 [AppUpdateInfo]（便于单元测试）。
  static AppUpdateInfo parseReleaseJson(
    Map<String, dynamic> json, {
    String currentVersion = '',
    String? operatingSystem,
    String? architecture,
  }) {
    final tagName = (json['tag_name'] as String?) ?? '';
    final version = AppVersion.tryParse(tagName)?.toString() ?? tagName;
    final assetsJson = (json['assets'] as List?) ?? const [];
    final assets = assetsJson
        .whereType<Map<String, dynamic>>()
        .map(ReleaseAsset.fromJson)
        .toList();

    DateTime? publishedAt;
    final published = (json['published_at'] as String?) ?? '';
    if (published.isNotEmpty) {
      publishedAt = DateTime.tryParse(published);
    }

    return AppUpdateInfo(
      tagName: tagName,
      version: version,
      releaseNotes: (json['body'] as String?) ?? '',
      htmlUrl:
          (json['html_url'] as String?) ?? kGitHubReleasesPageUrl.toString(),
      publishedAt: publishedAt,
      assets: assets,
      matchedAsset: pickAssetForPlatform(
        assets,
        operatingSystem: operatingSystem,
        architecture: architecture,
      ),
      currentVersion: currentVersion,
    );
  }

  /// 检查是否有可用更新；无可用更新时返回 null。
  ///
  /// - 正式版：若远端 Release 版本严格更新（latest > current）则提示；
  /// - Beta/Debug 构建：代码通常新于同号正式版（如 1.0.9-beta.5 对比 1.0.9），
  ///   因此同号时不提示，仅当远端存在更高主版本的正式版（如 1.0.10 > 1.0.9）时才提示更新。
  Future<AppUpdateInfo?> checkForUpdate() async {
    final info = await fetchLatestRelease();
    final current = await currentVersion();
    final latest = AppVersion.tryParse(info.version);

    if (current == null || latest == null) {
      // 版本解析失败时仍返回远端信息，由 UI 提示用户手动确认。
      return info;
    }

    if (current.isNonReleaseBuild) {
      // 非正式构建：远端基础版本严格更高才提示
      if (latest.baseVersion > current.baseVersion) return info;
      return null;
    }

    // 正式版：按标准 SemVer 严格比较
    if (latest > current) return info;
    return null;
  }

  /// 启动时静默检查：仅当有更新且用户未点过「忽略该版本」时返回。
  Future<AppUpdateInfo?> checkForUpdateSilently() async {
    try {
      final info = await checkForUpdate();
      if (info == null) return null;
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getString(_kDismissedUpdateTagKey);
      if (dismissed != null && dismissed == info.tagName) return null;
      return info;
    } catch (_) {
      // 静默失败
      return null;
    }
  }

  /// 记录用户已忽略某个版本，启动时不再弹出。
  Future<void> dismissUpdate(String tagName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDismissedUpdateTagKey, tagName);
  }

  void dispose() {
    _client.close();
  }
}

/// 更新相关可预期错误。
class UpdateException implements Exception {
  UpdateException(this.message);
  final String message;

  @override
  String toString() => message;
}
