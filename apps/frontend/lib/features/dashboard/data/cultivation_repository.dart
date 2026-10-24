import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class CultivationRealmModel {
  final int index;
  final String name;
  final int subRealms;
  final int expPerSubRealm;
  final String title;

  CultivationRealmModel({
    required this.index,
    required this.name,
    required this.subRealms,
    required this.expPerSubRealm,
    required this.title,
  });

  factory CultivationRealmModel.fromJson(Map<String, dynamic> json) {
    return CultivationRealmModel(
      index: json['index'] ?? 0,
      name: json['name'] ?? '',
      subRealms: json['subRealms'] ?? 10,
      expPerSubRealm: json['expPerSubRealm'] ?? 1000,
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
      realmIndex: json['realmIndex'] ?? 1,
      realmName: json['realmName'] ?? 'Luyện Khí',
      subRealm: json['subRealm'] ?? 1,
      currentExp: json['currentExp'] ?? 0,
      maxExp: json['maxExp'] ?? 1000,
      totalExp: json['totalExp'] ?? 0,
      spiritStones: json['spiritStones'] ?? 50,
      streakDays: json['streakDays'] ?? 1,
      title: json['title'] ?? 'Luyện Khí Kỳ Tu Sĩ',
      allRealms: realmsList.isNotEmpty ? realmsList : _defaultRealms,
    );
  }

  static final List<CultivationRealmModel> _defaultRealms = [
    CultivationRealmModel(index: 0, name: 'Phàm Nhân', subRealms: 1, expPerSubRealm: 0, title: 'Phàm Thai Chưa Tỉnh'),
    CultivationRealmModel(index: 1, name: 'Luyện Khí', subRealms: 10, expPerSubRealm: 1000, title: 'Luyện Khí Kỳ Tu Sĩ'),
    CultivationRealmModel(index: 2, name: 'Kết Đan', subRealms: 10, expPerSubRealm: 2500, title: 'Kim Đan Đại Sư'),
    CultivationRealmModel(index: 3, name: 'Nguyên Anh', subRealms: 10, expPerSubRealm: 5000, title: 'Nguyên Anh Lão Tổ'),
    CultivationRealmModel(index: 4, name: 'Hóa Thần', subRealms: 10, expPerSubRealm: 10000, title: 'Hóa Thần Chân Quân'),
    CultivationRealmModel(index: 5, name: 'Luyện Hư', subRealms: 10, expPerSubRealm: 20000, title: 'Luyện Hư Chí Tôn'),
    CultivationRealmModel(index: 6, name: 'Đại Thừa', subRealms: 10, expPerSubRealm: 40000, title: 'Đại Thừa Cường Giả'),
    CultivationRealmModel(index: 7, name: 'Hợp Thể', subRealms: 10, expPerSubRealm: 80000, title: 'Hợp Thể Tiên Tôn'),
    CultivationRealmModel(index: 8, name: 'Độ Kiếp', subRealms: 10, expPerSubRealm: 150000, title: 'Chuẩn Tiên Thiên Kiếp'),
    CultivationRealmModel(index: 9, name: 'Phi Tiên', subRealms: 1, expPerSubRealm: 0, title: 'Chân Tiên Phi Thăng'),
  ];
}

class CultivationRepository {
  final ApiClient _apiClient;

  CultivationRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
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

    // Fallback mặc định
    return CultivationProfileModel(
      userId: 'local-user',
      realmIndex: 1,
      realmName: 'Luyện Khí',
      subRealm: 1,
      currentExp: 680,
      maxExp: 1000,
      totalExp: 680,
      spiritStones: 50,
      streakDays: 12,
      title: 'Luyện Khí Kỳ Tu Sĩ',
      allRealms: CultivationProfileModel._defaultRealms,
    );
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
      return null;
    }
  }

  Future<void> completeQuest(String questId) async {
    final token = await _getToken();
    try {
      await _apiClient.post(
        ApiConstants.campaignQuestComplete(questId),
        token: token,
      );
    } catch (_) {}
  }
}
