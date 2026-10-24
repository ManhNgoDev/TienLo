import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';

class CultivationRealmModel {
  final int index;
  final String name;
  final int subRealms;
  final int expPerSubRealm;
  final int minExp;
  final int maxExp;
  final String title;

  CultivationRealmModel({
    required this.index,
    required this.name,
    required this.subRealms,
    required this.expPerSubRealm,
    required this.minExp,
    required this.maxExp,
    required this.title,
  });

  factory CultivationRealmModel.fromJson(Map<String, dynamic> json) {
    return CultivationRealmModel(
      index: json['index'] ?? 0,
      name: json['name'] ?? '',
      subRealms: json['subRealms'] ?? 10,
      expPerSubRealm: json['expPerSubRealm'] ?? 1000,
      minExp: json['minExp'] ?? json['expPerSubRealm'] ?? 1000,
      maxExp: json['maxExp'] ?? json['expPerSubRealm'] ?? 1000,
      title: json['title'] ?? '',
    );
  }
}

class CultivationProfileModel {
  final String userId;
  final int realmIndex;
  final String realmName;
  final int subRealm;
  final int currentExp;
  final int maxExp;
  final int totalExp;
  final int spiritStones;
  final int streakDays;
  final String title;
  final List<CultivationRealmModel> allRealms;

  CultivationProfileModel({
    required this.userId,
    required this.realmIndex,
    required this.realmName,
    required this.subRealm,
    required this.currentExp,
    required this.maxExp,
    required this.totalExp,
    required this.spiritStones,
    required this.streakDays,
    required this.title,
    required this.allRealms,
  });

  factory CultivationProfileModel.fromJson(Map<String, dynamic> json) {
    final realmsList = (json['allRealms'] as List<dynamic>? ?? [])
        .map((r) => CultivationRealmModel.fromJson(r as Map<String, dynamic>))
        .toList();

    return CultivationProfileModel(
      userId: json['userId'] ?? '',
      realmIndex: json['realmIndex'] ?? 0,
      realmName: json['realmName'] ?? 'Phàm Nhân',
      subRealm: json['subRealm'] ?? 1,
      currentExp: json['currentExp'] ?? 0,
      maxExp: json['maxExp'] ?? 1000,
      totalExp: json['totalExp'] ?? 0,
      spiritStones: json['spiritStones'] ?? 50,
      streakDays: json['streakDays'] ?? 1,
      title: json['title'] ?? 'Phàm Thai Chưa Tỉnh',
      allRealms: realmsList.isNotEmpty ? realmsList : _defaultRealms,
    );
  }

  static final List<CultivationRealmModel> _defaultRealms = [
    CultivationRealmModel(index: 0, name: 'Phàm Nhân', subRealms: 1, expPerSubRealm: 1000, minExp: 1000, maxExp: 1000, title: 'Phàm Thai Chưa Tỉnh'),
    CultivationRealmModel(index: 1, name: 'Luyện Khí', subRealms: 10, expPerSubRealm: 1000, minExp: 1000, maxExp: 33550, title: 'Luyện Khí Kỳ Tu Sĩ'),
    CultivationRealmModel(index: 2, name: 'Kết Đan', subRealms: 10, expPerSubRealm: 35000, minExp: 35000, maxExp: 1173050, title: 'Kim Đan Đại Sư'),
    CultivationRealmModel(index: 3, name: 'Nguyên Anh', subRealms: 10, expPerSubRealm: 1250000, minExp: 1250000, maxExp: 41902700, title: 'Nguyên Anh Lão Tổ'),
    CultivationRealmModel(index: 4, name: 'Hóa Thần', subRealms: 10, expPerSubRealm: 45000000, minExp: 45000000, maxExp: 1508495800, title: 'Hóa Thần Chân Quân'),
    CultivationRealmModel(index: 5, name: 'Luyện Hư', subRealms: 10, expPerSubRealm: 1600000000, minExp: 1600000000, maxExp: 53635405800, title: 'Luyện Hư Chí Tôn'),
    CultivationRealmModel(index: 6, name: 'Đại Thừa', subRealms: 10, expPerSubRealm: 55000000000, minExp: 55000000000, maxExp: 1843717075200, title: 'Đại Thừa Cường Giả'),
    CultivationRealmModel(index: 7, name: 'Hợp Thể', subRealms: 10, expPerSubRealm: 2000000000000, minExp: 2000000000000, maxExp: 67044257280000, title: 'Hợp Thể Tiên Tôn'),
    CultivationRealmModel(index: 8, name: 'Độ Kiếp', subRealms: 10, expPerSubRealm: 70000000000000, minExp: 70000000000000, maxExp: 2346549004800000, title: 'Chuẩn Tiên Thiên Kiếp'),
    CultivationRealmModel(index: 9, name: 'Phi Tiên', subRealms: 1, expPerSubRealm: 0, minExp: 0, maxExp: 0, title: 'Chân Tiên Phi Thăng'),
  ];
}

class CultivationRepository {
  final ApiClient _apiClient;

  CultivationRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<String?> _getToken() async {
    try {
      final validToken = await AuthRepository().getValidToken();
      if (validToken != null && validToken.isNotEmpty) {
        return validToken;
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      return 'demo-token-dev-fallback';
    }
    return token;
  }

  Future<CultivationProfileModel> getProfile() async {
    final token = await _getToken();
    try {
      final res = await _apiClient.get(
        ApiConstants.cultivationProfile,
        token: token,
      );
      if (res != null) {
        return CultivationProfileModel.fromJson(res);
      }
    } catch (_) {}

    // Fallback mặc định: Phàm Nhân, 0 Linh Lực, 0 Nguyên Thạch
    return CultivationProfileModel(
      userId: 'local-user',
      realmIndex: 0,
      realmName: 'Phàm Nhân',
      subRealm: 1,
      currentExp: 0,
      maxExp: 1000,
      totalExp: 0,
      spiritStones: 0,
      streakDays: 1,
      title: 'Phàm Thai Chưa Tỉnh',
      allRealms: CultivationProfileModel._defaultRealms,
    );
  }

  Future<List<Map<String, dynamic>>> getUserCampaigns() async {
    final token = await _getToken();
    try {
      final res = await _apiClient.get(
        ApiConstants.campaignsList,
        token: token,
      );
      if (res is List) {
        return res.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> generateAiCampaign(
    String goalPrompt, {
    int durationDays = 30,
  }) async {
    final token = await _getToken();
    try {
      final res = await _apiClient.post(
        ApiConstants.campaignsAiGenerate,
        token: token,
        body: {
          'goalPrompt': goalPrompt,
          'durationDays': durationDays,
        },
      );
      return res as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error generateAiCampaign: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> completeQuest(String questId) async {
    final token = await _getToken();
    try {
      final res = await _apiClient.post(
        ApiConstants.campaignQuestComplete(questId),
        token: token,
      );
      return res as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getStatistics() async {
    final token = await _getToken();
    try {
      final res = await _apiClient.get(
        ApiConstants.campaignsStatistics,
        token: token,
      );
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (e) {
      debugPrint('Error getStatistics: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getFullUserProfile() async {
    final token = await _getToken();
    try {
      final res = await _apiClient.get(
        ApiConstants.userProfile,
        token: token,
      );
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (e) {
      debugPrint('Error getFullUserProfile: $e');
    }
    return null;
  }

  Future<bool> updateUserProfile({String? displayName, String? username, String? avatarUrl}) async {
    final token = await _getToken();
    try {
      final body = <String, dynamic>{};
      if (displayName != null) body['displayName'] = displayName;
      if (username != null) body['username'] = username;
      if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

      final res = await _apiClient.put(
        ApiConstants.userProfile,
        token: token,
        body: body,
      );
      return res != null;
    } catch (e) {
      debugPrint('Error updateUserProfile: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserAchievements() async {
    final token = await _getToken();
    try {
      final res = await _apiClient.get(
        ApiConstants.userAchievements,
        token: token,
      );
      if (res is List) {
        return res.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error getUserAchievements: $e');
    }
    return [];
  }
}
