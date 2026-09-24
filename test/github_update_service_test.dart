import 'package:flutter_test/flutter_test.dart';
import 'package:ahu_aio/update/github_update_service.dart';

void main() {
  group('AppVersion.tryParse', () {
    test('parses plain semver', () {
      final v = AppVersion.tryParse('1.2.3');
      expect(v, isNotNull);
      expect(v!.major, 1);
      expect(v.minor, 2);
      expect(v.patch, 3);
      expect(v.prerelease, '');
    });

    test('parses v-prefixed tag and build number', () {
      final v = AppVersion.tryParse('v1.0.9+10009');
      expect(v, isNotNull);
      expect(v!.toString(), '1.0.9');
      expect(v.build, 10009);
    });

    test('parses prerelease', () {
      final v = AppVersion.tryParse('1.0.9-beta.1');
      expect(v, isNotNull);
      expect(v!.prerelease, 'beta.1');
    });

    test('parses CI beta version string', () {
      // beta.yml: ${BASE_VERSION}-beta.${COMMITS_SINCE}.${SHORT_HASH}
      final v = AppVersion.tryParse('1.0.9-beta.5.abc1234');
      expect(v, isNotNull);
      expect(v!.major, 1);
      expect(v.minor, 0);
      expect(v.patch, 9);
      expect(v.prerelease, 'beta.5.abc1234');
      expect(v.isNonReleaseBuild, isTrue);
    });

    test('stable is release build, debug is not', () {
      expect(AppVersion.tryParse('1.0.9')!.isNonReleaseBuild, isFalse);
      expect(AppVersion.tryParse('v1.0.10')!.isNonReleaseBuild, isFalse);
      expect(
        AppVersion.tryParse('1.0.9-debug.abc1234')!.isNonReleaseBuild,
        isTrue,
      );
    });

    test('rejects garbage', () {
      expect(AppVersion.tryParse(''), isNull);
      expect(AppVersion.tryParse('abc'), isNull);
      expect(AppVersion.tryParse('1.2.3.4'), isNull);
      expect(AppVersion.tryParse(null), isNull);
    });
  });

  group('AppVersion compare', () {
    test('orders by major.minor.patch', () {
      expect(
        AppVersion.tryParse('1.0.10')! > AppVersion.tryParse('1.0.9')!,
        isTrue,
      );
      expect(
        AppVersion.tryParse('1.1.0')! > AppVersion.tryParse('1.0.99')!,
        isTrue,
      );
      expect(
        AppVersion.tryParse('2.0.0')! > AppVersion.tryParse('1.9.9')!,
        isTrue,
      );
    });

    test('stable is greater than prerelease of same number', () {
      expect(
        AppVersion.tryParse('1.0.9')! > AppVersion.tryParse('1.0.9-beta')!,
        isTrue,
      );
    });
  });

  group('pickAssetForPlatform', () {
    final assets = [
      ReleaseAsset(
        name: 'AHU-AIO-Android-arm64-1.0.9-1.apk',
        downloadUrl: 'https://example.com/arm64.apk',
        size: 22479275,
      ),
      ReleaseAsset(
        name: 'AHU-AIO-Android-x86_64-1.0.9-1.apk',
        downloadUrl: 'https://example.com/x86.apk',
        size: 24002631,
      ),
      ReleaseAsset(
        name: 'AHU-AIO-Windows-x64-1.0.9-1.zip',
        downloadUrl: 'https://example.com/win.zip',
        size: 14685792,
      ),
      ReleaseAsset(
        name: 'AHU-AIO-Linux-x86_64-1.0.9-1.tar.gz',
        downloadUrl: 'https://example.com/linux.tar.gz',
        size: 11721185,
      ),
      ReleaseAsset(
        name: 'AHU-AIO-macOS-universal-1.0.9-1.zip',
        downloadUrl: 'https://example.com/mac.zip',
        size: 65609661,
      ),
      ReleaseAsset(
        name: 'AHU-AIO-Beta-Android-arm64-1.0.10-1.apk',
        downloadUrl: 'https://example.com/beta.apk',
        size: 1,
      ),
    ];

    test('android arm64 picks arm64 apk and skips beta', () {
      final a = pickAssetForPlatform(
        assets,
        operatingSystem: 'android',
        architecture: 'arm64',
      );
      expect(a!.name, 'AHU-AIO-Android-arm64-1.0.9-1.apk');
    });

    test('android x86_64 picks x86_64 apk', () {
      final a = pickAssetForPlatform(
        assets,
        operatingSystem: 'android',
        architecture: 'x86_64',
      );
      expect(a!.name, 'AHU-AIO-Android-x86_64-1.0.9-1.apk');
    });

    test('windows picks windows zip', () {
      final a = pickAssetForPlatform(
        assets,
        operatingSystem: 'windows',
        architecture: 'x64',
      );
      expect(a!.name, 'AHU-AIO-Windows-x64-1.0.9-1.zip');
    });

    test('linux picks tar.gz', () {
      final a = pickAssetForPlatform(
        assets,
        operatingSystem: 'linux',
        architecture: 'x64',
      );
      expect(a!.name, 'AHU-AIO-Linux-x86_64-1.0.9-1.tar.gz');
    });

    test('macos picks universal zip', () {
      final a = pickAssetForPlatform(
        assets,
        operatingSystem: 'macos',
        architecture: 'arm64',
      );
      expect(a!.name, 'AHU-AIO-macOS-universal-1.0.9-1.zip');
    });
  });

  group('parseReleaseJson', () {
    test('maps GitHub payload to AppUpdateInfo', () {
      final info = GitHubUpdateService.parseReleaseJson(
        {
          'tag_name': 'v1.0.10',
          'body': '## Changes\n- fix',
          'html_url':
              'https://github.com/MoeclubM/AHU-AIO/releases/tag/v1.0.10',
          'published_at': '2026-09-16T17:02:50Z',
          'assets': [
            {
              'name': 'AHU-AIO-Android-arm64-1.0.10-2.apk',
              'browser_download_url': 'https://example.com/a.apk',
              'size': 100,
            },
          ],
        },
        currentVersion: '1.0.9+10009',
        operatingSystem: 'android',
        architecture: 'arm64',
      );

      expect(info.version, '1.0.10');
      expect(info.tagName, 'v1.0.10');
      expect(info.releaseNotes, contains('fix'));
      expect(info.matchedAsset?.name, 'AHU-AIO-Android-arm64-1.0.10-2.apk');
      expect(info.currentVersion, '1.0.9+10009');
      expect(info.hasDownload, isTrue);
    });
  });

  group('beta build skips release update', () {
    test('checkForUpdate returns null for CI beta current version', () async {
      final service = GitHubUpdateService(
        currentVersionOverride: '1.0.9-beta.5.abc1234',
      );
      // 不应发起网络请求；即便远端是同号/更低正式版也不提示。
      final info = await service.checkForUpdate();
      expect(info, isNull);
      expect(await service.isNonReleaseBuild(), isTrue);
      service.dispose();
    });

    test(
      'checkForUpdate returns null for local debug current version',
      () async {
        final service = GitHubUpdateService(
          currentVersionOverride: '1.0.9-debug.deadbee',
        );
        expect(await service.checkForUpdate(), isNull);
        service.dispose();
      },
    );

    test('currentVersionString uses injected override', () async {
      final service = GitHubUpdateService(
        currentVersionOverride: '1.0.9-beta.5.abc1234',
      );
      expect(await service.currentVersionString(), '1.0.9-beta.5.abc1234');
      service.dispose();
    });
  });
}
