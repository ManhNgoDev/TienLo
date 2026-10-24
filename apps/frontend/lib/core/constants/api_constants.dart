import 'package:flutter/foundation.dart';

class ApiConstants {
  static String? customBaseUrl;

  /// Đường dẫn máy chủ Backend đã deploy trên Render (dành cho bản build APK)
  static String productionRenderUrl = 'https://tienlo.onrender.com/api';

  /// Nhận biến môi trường khi build: flutter build apk --dart-define=BACKEND_URL=https://...
  static const String envBackendUrl = String.fromEnvironment('BACKEND_URL', defaultValue: '');

  /// Tự động chuyển đổi môi trường:
  /// - Khi chạy trên máy (Dev / Debug): trỏ localhost:3000 hoặc 10.0.2.2:3000
  /// - Khi build APK (Release): tự động trỏ đến đường dẫn Render deploy
  static String get defaultBaseUrl {
    if (customBaseUrl != null && customBaseUrl!.trim().isNotEmpty) {
      return customBaseUrl!.trim();
    }
    if (envBackendUrl.isNotEmpty) {
      return envBackendUrl.trim();
    }
    // Nếu là bản build phát hành (APK Release) -> dùng link Render deploy
    if (kReleaseMode) {
      return productionRenderUrl;
    }
    // Môi trường dev cục bộ trên máy
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  static const String authSync = '/auth/sync';
  static const String authMe = '/auth/me';
  static const String userProfile = '/users/profile';
  static const String userAchievements = '/users/achievements';
  static const String health = '/health';

  // Cultivation & Campaigns
  static const String cultivationProfile = '/cultivation/profile';
  static const String cultivationAddExp = '/cultivation/add-exp';
  static const String cultivationAddStones = '/cultivation/add-stones';
  static const String cultivationPenalize = '/cultivation/penalize';
  static const String campaignsAiGenerate = '/campaigns/ai-generate';
  static const String campaignsList = '/campaigns';
  static const String campaignsStatistics = '/campaigns/statistics';
  static String campaignQuestComplete(String questId) =>
      '/campaigns/quests/$questId/complete';
}

