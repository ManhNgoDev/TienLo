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
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      title: json['title'] ?? 'Phàm Thai Chưa Tỉnh',
      allRealms: realmsList.isNotEmpty ? realmsList : _defaultRealms,
    );
  }

  static final List<CultivationRealmModel> _defaultRealms = [
    CultivationRealmModel(index: 0, name: 'Phàm Nhân', subRealms: 1, expPerSubRealm: 1000, minExp: 1000, maxExp: 1000, title: 'Phàm Thai Chưa Tỉnh'),
    CultivationRealmModel(index: 1, name: 'Luyện Khí', subRealms: 10, expPerSubRealm: 1000, minExp: 1000, maxExp: 6050, title: 'Luyện Khí Kỳ Tu Sĩ'),
    CultivationRealmModel(index: 2, name: 'Kết Đan', subRealms: 10, expPerSubRealm: 7500, minExp: 7500, maxExp: 44150, title: 'Kim Đan Đại Sư'),
    CultivationRealmModel(index: 3, name: 'Nguyên Anh', subRealms: 10, expPerSubRealm: 55000, minExp: 55000, maxExp: 323350, title: 'Nguyên Anh Lão Tổ'),
    CultivationRealmModel(index: 4, name: 'Hóa Thần', subRealms: 10, expPerSubRealm: 400000, minExp: 400000, maxExp: 2351900, title: 'Hóa Thần Chân Quân'),
    CultivationRealmModel(index: 5, name: 'Luyện Hư', subRealms: 10, expPerSubRealm: 3000000, minExp: 3000000, maxExp: 17638150, title: 'Luyện Hư Chí Tôn'),
    CultivationRealmModel(index: 6, name: 'Đại Thừa', subRealms: 10, expPerSubRealm: 22000000, minExp: 22000000, maxExp: 129346400, title: 'Đại Thừa Cường Giả'),
    CultivationRealmModel(index: 7, name: 'Hợp Thể', subRealms: 10, expPerSubRealm: 160000000, minExp: 160000000, maxExp: 940701800, title: 'Hợp Thể Tiên Tôn'),
    CultivationRealmModel(index: 8, name: 'Độ Kiếp', subRealms: 10, expPerSubRealm: 1200000000, minExp: 1200000000, maxExp: 7055263300, title: 'Chuẩn Tiên Thiên Kiếp'),
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
      streakDays: 0,
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
      rethrow;
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

  Future<Map<String, dynamic>?> addExp(int amount) async {
    final token = await _getToken();
    try {
      final res = await _apiClient.post(
        ApiConstants.cultivationAddExp,
        token: token,
        body: {'amount': amount},
      );
      return res as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> addSpiritStones(int amount, String description) async {
    final token = await _getToken();
    try {
      final res = await _apiClient.post(
        ApiConstants.cultivationAddStones,
        token: token,
        body: {
          'amount': amount,
          'description': description,
        },
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

  static int calculateSubRealmExp(int realmIndex, int tier) {
    if (realmIndex == 0) return 1000;
    if (realmIndex >= 9) return 99999999999;

    const baseExps = {
      1: 1000,
      2: 7500,
      3: 55000,
      4: 400000,
      5: 3000000,
      6: 22000000,
      7: 160000000,
      8: 1200000000,
    };

    final base = baseExps[realmIndex] ?? 1000;
    final targetTier = tier.clamp(1, 10);
    if (targetTier <= 1) return base;

    double exp = base.toDouble();
    for (int t = 2; t <= targetTier; t++) {
      final factor = (1.0 + 0.10 + (t - 2) * 0.03).clamp(1.0, 1.35);
      exp = ((exp * factor) / 50).round() * 50.0;
    }
    return exp.toInt();
  }

  Future<Map<String, dynamic>> penalizeExp({
    required int uncompletedCount,
    int? customPenalty,
    String? reason,
  }) async {
    final token = await _getToken();
    try {
      final body = <String, dynamic>{
        'uncompletedCount': uncompletedCount,
      };
      if (customPenalty != null) body['customPenalty'] = customPenalty;
      if (reason != null) body['reason'] = reason;

      final res = await _apiClient.post(
        ApiConstants.cultivationPenalize,
        token: token,
        body: body,
      );
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (e) {
      debugPrint('Error penalizeExp backend: $e');
    }

    // Local fallback nếu backend offline hoặc lỗi:
    final currentProfile = await getProfile();
    int realmIndex = currentProfile.realmIndex;
    int subRealm = currentProfile.subRealm;
    int currentExp = currentProfile.currentExp;
    int totalExp = currentProfile.totalExp;
    final prevRealmName = currentProfile.realmName;
    final prevSubRealm = subRealm;

    final penaltyExp = customPenalty != null && customPenalty > 0
        ? customPenalty.clamp(10, 300)
        : (uncompletedCount * 80).clamp(50, 300);

    final actualReason = reason ??
        'Chưa hoàn thành $uncompletedCount nhiệm vụ hôm qua (phạt $penaltyExp Linh Lực)';

    currentExp -= penaltyExp;
    totalExp = (totalExp - penaltyExp).clamp(0, 999999999999);
    bool demotedLevel = false;
    bool demotedRealm = false;

    while (currentExp < 0) {
      if (realmIndex == 1 && subRealm == 1) {
        currentExp = 0;
        break;
      }
      if (realmIndex == 0) {
        currentExp = 0;
        break;
      }

      if (subRealm > 1) {
        subRealm -= 1;
        final maxExp = calculateSubRealmExp(realmIndex, subRealm);
        currentExp = maxExp + currentExp;
        demotedLevel = true;
      } else {
        realmIndex -= 1;
        subRealm = 10;
        final maxExp = calculateSubRealmExp(realmIndex, 10);
        currentExp = maxExp + currentExp;
        demotedLevel = true;
        demotedRealm = true;
      }
    }

    final realmConfig = CultivationProfileModel._defaultRealms.firstWhere(
      (r) => r.index == realmIndex,
      orElse: () => CultivationProfileModel._defaultRealms[1],
    );

    return {
      'profile': {
        'userId': currentProfile.userId,
        'realmIndex': realmIndex,
        'realmName': realmConfig.name,
        'subRealm': subRealm,
        'currentExp': currentExp,
        'maxExp': calculateSubRealmExp(realmIndex, subRealm),
        'totalExp': totalExp,
        'spiritStones': currentProfile.spiritStones,
        'streakDays': currentProfile.streakDays,
        'title': realmConfig.title,
      },
      'penaltyExp': penaltyExp,
      'uncompletedCount': uncompletedCount,
      'reason': actualReason,
      'demotedLevel': demotedLevel,
      'demotedRealm': demotedRealm,
      'previousRealmName': prevRealmName,
      'previousSubRealm': prevSubRealm,
      'currentRealmName': realmConfig.name,
      'currentSubRealm': subRealm,
    };
  }
}
