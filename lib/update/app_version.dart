/// 应用版本号，与 `pubspec.yaml` 的 `version:` 字段保持一致。
///
/// CI 打正式包时会用 tag 覆盖安装包的 versionName/versionCode；
/// 检查更新以该常量对应的「源码声明版本」与 GitHub Release tag 比较。
/// 发版改版本时请同步修改 `pubspec.yaml` 与本文件。
const String kAppVersion = '1.0.9';
const String kAppBuildNumber = '10009';
const String kAppVersionDisplay = '$kAppVersion+$kAppBuildNumber';
