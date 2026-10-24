import 'package:flutter/foundation.dart';

class ApiConstants {
  /// Tự động trỏ đúng URL máy chủ Backend khi chạy trên Mobile:
  /// - Android Emulator: 'http://10.0.2.2:3000/api' (kết nối trực tiếp tới localhost của máy tính)
  /// - iOS Simulator & Thiết bị khác: 'http://localhost:3000/api'
  static String get defaultBaseUrl {
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

