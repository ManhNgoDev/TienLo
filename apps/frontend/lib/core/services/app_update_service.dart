import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/api_constants.dart';

class AppUpdateInfo {
  final String currentVersion;
  final int currentBuildNumber;
  final String latestVersion;
  final int latestBuildNumber;
  final bool hasUpdate;
  final bool forceUpdate;
  final String downloadUrl;
  final String releaseNotes;
  final String? publishedAt;

  AppUpdateInfo({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.hasUpdate,
    required this.forceUpdate,
    required this.downloadUrl,
    required this.releaseNotes,
    this.publishedAt,
  });
}

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  /// So sánh hai chuỗi phiên bản dạng semver (ví dụ: '1.0.1' với '1.0.0')
  /// Trả về:
  /// > 0 nếu v1 > v2
  /// < 0 nếu v1 < v2
  /// = 0 nếu v1 == v2
  static int compareSemver(String v1, String v2) {
    final cleanV1 = v1.replaceAll(RegExp(r'[^0-9.]'), '');
    final cleanV2 = v2.replaceAll(RegExp(r'[^0-9.]'), '');

    final parts1 = cleanV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = cleanV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (int i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  /// Kiểm tra xem có phiên bản cập nhật mới không
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // Ví dụ: '1.0.0'
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      String latestVersion = currentVersion;
      int latestBuildNumber = currentBuildNumber;
      String downloadUrl = '';
      String releaseNotes = '';
      bool forceUpdate = false;
      String? publishedAt;
      bool fetchedSuccessfully = false;

      // 1. Thử lấy thông tin từ Backend Tiên Lộ trước
      try {
        final backendUrl = '${ApiConstants.defaultBaseUrl}${ApiConstants.appVersion}';
        final response = await http
            .get(Uri.parse(backendUrl))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data is Map<String, dynamic>) {
            latestVersion = (data['latestVersion'] ?? currentVersion).toString().replaceAll('v', '');
            latestBuildNumber = int.tryParse(data['latestBuildNumber']?.toString() ?? '') ?? currentBuildNumber;
            downloadUrl = data['downloadUrl']?.toString() ?? '';
            releaseNotes = data['releaseNotes']?.toString() ?? '';
            forceUpdate = data['forceUpdate'] == true;
            publishedAt = data['publishedAt']?.toString();
            fetchedSuccessfully = true;
          }
        }
      } catch (e) {
        debugPrint('[AppUpdateService] Backend check failed: $e. Thử GitHub API trực tiếp...');
      }

      // 2. Nếu Backend không phản hồi, truy vấn trực tiếp GitHub Releases API
      if (!fetchedSuccessfully) {
        try {
          final response = await http
              .get(
                Uri.parse(ApiConstants.githubLatestReleaseApi),
                headers: {
                  'Accept': 'application/vnd.github.v3+json',
                  'User-Agent': 'TienLo-Flutter-App',
                },
              )
              .timeout(const Duration(seconds: 6));

          if (response.statusCode == 200) {
            final data = jsonDecode(utf8.decode(response.bodyBytes));
            if (data is Map<String, dynamic>) {
              final tagName = data['tag_name']?.toString() ?? '';
              latestVersion = tagName.replaceAll('v', '').trim();
              releaseNotes = data['body']?.toString() ?? 'Bản cập nhật tối ưu hóa và bổ sung tính năng mới.';
              publishedAt = data['published_at']?.toString();

              // Tìm asset APK trong danh sách release assets
              final assets = data['assets'];
              if (assets is List) {
                for (final asset in assets) {
                  final name = asset['name']?.toString().toLowerCase() ?? '';
                  if (name.endsWith('.apk')) {
                    downloadUrl = asset['browser_download_url']?.toString() ?? '';
                    break;
                  }
                }
              }

              if (downloadUrl.isEmpty) {
                downloadUrl = 'https://github.com/ManhNgoDev/TienLo/releases/latest/download/TienLo-release.apk';
              }
              fetchedSuccessfully = true;
            }
          }
        } catch (e) {
          debugPrint('[AppUpdateService] GitHub API direct check failed: $e');
        }
      }

      if (!fetchedSuccessfully) {
        return null;
      }

      // 3. So sánh phiên bản
      final cmp = compareSemver(latestVersion, currentVersion);
      bool hasUpdate = cmp > 0;
      if (cmp == 0 && latestBuildNumber > currentBuildNumber) {
        hasUpdate = true;
      }

      return AppUpdateInfo(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        latestVersion: latestVersion,
        latestBuildNumber: latestBuildNumber,
        hasUpdate: hasUpdate,
        forceUpdate: forceUpdate,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes,
        publishedAt: publishedAt,
      );
    } catch (e) {
      debugPrint('[AppUpdateService] Error checking for update: $e');
      return null;
    }
  }

  /// Thực hiện tải và kích hoạt cài đặt APK trên thiết bị Android
  Stream<OtaEvent> startOtaUpdate(String downloadUrl) {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        return OtaUpdate().execute(
          downloadUrl,
          destinationFilename: 'TienLo-release.apk',
        );
      } catch (e) {
        debugPrint('[AppUpdateService] OtaUpdate execute error: $e');
        final controller = StreamController<OtaEvent>();
        controller.addError(e);
        controller.close();
        return controller.stream;
      }
    } else {
      final controller = StreamController<OtaEvent>();
      controller.add(OtaEvent(OtaStatus.INTERNAL_ERROR, 'Hệ điều hành hiện tại không hỗ trợ cài đặt APK tự động.'));
      controller.close();
      return controller.stream;
    }
  }
}
