import 'package:shared_preferences/shared_preferences.dart';

enum BackendEnvType {
  emulator(
    'Local Android Emulator',
    'http://10.0.2.2:3000/api',
    'Dành cho máy ảo Android Studio (10.0.2.2)',
  ),
  localhost(
    'Localhost (PC / Web)',
    'http://localhost:3000/api',
    'Dành cho Windows App, Web hoặc chạy qua adb reverse',
  ),
  lan(
    'Mạng Cục Bộ (Wi-Fi LAN)',
    'http://192.168.1.100:3000/api',
    'Dành cho điện thoại thật kết nối cùng mạng Wi-Fi',
  ),
  production(
    'Production (Render Cloud)',
    'https://tienlo.onrender.com/api',
    'Máy chủ Cloud đã deploy trên Render',
  );

  final String title;
  final String defaultUrl;
  final String description;

  const BackendEnvType(this.title, this.defaultUrl, this.description);
}

class ApiConstants {
  static const String prefKeyCustomBackendUrl = 'custom_backend_url';
  static const String prefKeyEnvType = 'active_backend_env_type';

  static String? customBaseUrl;
  static BackendEnvType currentEnvType = BackendEnvType.production;

  /// Đường dẫn máy chủ Backend đã deploy trên Render
  static String productionRenderUrl = 'https://tienlo.onrender.com/api';

  /// Nhận biến môi trường khi build: flutter build apk --dart-define=BACKEND_URL=https://...
  static const String envBackendUrl = String.fromEnvironment('BACKEND_URL', defaultValue: '');

  /// Tự động lấy URL máy chủ hiện hành
  static String get defaultBaseUrl {
    if (customBaseUrl != null && customBaseUrl!.trim().isNotEmpty) {
      return customBaseUrl!.trim();
    }
    if (envBackendUrl.isNotEmpty) {
      return envBackendUrl.trim();
    }
    return productionRenderUrl;
  }

  /// Kiểm tra xem hiện tại đang ở môi trường cục bộ (Local) hay không
  static bool get isLocal {
    final url = defaultBaseUrl.toLowerCase();
    return url.contains('localhost') ||
        url.contains('10.0.2.2') ||
        url.contains('127.0.0.1') ||
        url.contains('192.168.') ||
        url.contains(':3000');
  }

  /// Tên nhãn hiển thị trực quan cho môi trường hiện tại
  static String get activeEnvironmentLabel {
    if (isLocal) {
      if (defaultBaseUrl.contains('10.0.2.2')) {
        return 'Local Emulator (10.0.2.2:3000)';
      } else if (defaultBaseUrl.contains('localhost') || defaultBaseUrl.contains('127.0.0.1')) {
        return 'Localhost (3000)';
      } else {
        return 'Local Dev ($defaultBaseUrl)';
      }
    }
    return 'Production (Render Cloud)';
  }

  /// Khởi tạo và đọc cấu hình đã lưu
  static Future<void> loadSavedEnvironment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(prefKeyCustomBackendUrl);
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        customBaseUrl = savedUrl.trim();
      }

      final savedTypeName = prefs.getString(prefKeyEnvType);
      if (savedTypeName != null) {
        currentEnvType = BackendEnvType.values.firstWhere(
          (e) => e.name == savedTypeName,
          orElse: () => isLocal ? BackendEnvType.emulator : BackendEnvType.production,
        );
      } else if (isLocal) {
        currentEnvType = defaultBaseUrl.contains('10.0.2.2')
            ? BackendEnvType.emulator
            : BackendEnvType.localhost;
      }
    } catch (_) {}
  }

  /// Đặt môi trường mới và lưu vào máy
  static Future<void> setEnvironment(BackendEnvType type, [String? customUrl]) async {
    currentEnvType = type;
    final targetUrl = (customUrl != null && customUrl.trim().isNotEmpty)
        ? customUrl.trim()
        : type.defaultUrl;

    customBaseUrl = targetUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKeyCustomBackendUrl, targetUrl);
    await prefs.setString(prefKeyEnvType, type.name);
  }

  /// Khôi phục về Production (Render)
  static Future<void> resetToProduction() async {
    await setEnvironment(BackendEnvType.production, productionRenderUrl);
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
  static const String campaignsGenerateExtra = '/campaigns/quests/generate-extra';
  static const String campaignsList = '/campaigns';
  static const String campaignsStatistics = '/campaigns/statistics';
  static String campaignQuestComplete(String questId) =>
      '/campaigns/quests/$questId/complete';

  // Leaderboard
  static const String leaderboard = '/leaderboard';

  // Shop / Phù Lục Các
  static const String shopItems = '/shop/items';
  static const String shopInventory = '/shop/inventory';
  static const String shopPurchase = '/shop/purchase';

  // App Self-Update
  static const String appVersion = '/app/version';
  static const String githubLatestReleaseApi =
      'https://api.github.com/repos/ManhNgoDev/TienLo/releases/latest';

  // Feedback & Bug Reporting
  static const String feedbackReport = '/feedback/report';
}

