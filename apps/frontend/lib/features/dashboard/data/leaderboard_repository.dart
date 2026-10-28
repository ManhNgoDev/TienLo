import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/leaderboard_item.dart';

class LeaderboardRepository {
  final ApiClient _apiClient;

  LeaderboardRepository({ApiClient? apiClient})
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

  Future<LeaderboardResult> getLeaderboard({
    String sortBy = 'default',
    int limit = 50,
  }) async {
    final token = await _getToken();
    try {
      final endpoint = '${ApiConstants.leaderboard}?sortBy=$sortBy&limit=$limit';
      debugPrint('LeaderboardRepository: Fetching $endpoint on ${_apiClient.baseUrl}...');
      final res = await _apiClient.get(endpoint, token: token);
      if (res != null && res is Map<String, dynamic>) {
        final result = LeaderboardResult.fromJson(res);
        debugPrint('LeaderboardRepository: Successfully loaded ${result.items.length} items from API (currentUser: ${result.currentUser?.displayName}, rank: ${result.currentUser?.rank}).');
        return result;
      }
    } catch (e, stack) {
      debugPrint('LeaderboardRepository: API call failed ($e)\n$stack');
    }

    // Fallback nếu ngoại tuyến hoặc server chưa phản hồi kịp
    debugPrint('LeaderboardRepository: Using local fallback leaderboard sorted by $sortBy');
    return _buildFallbackLeaderboard(sortBy);
  }

  LeaderboardResult _buildFallbackLeaderboard(String sortBy) {
    final fallbackItems = [
      LeaderboardItem(
        rank: 1,
        userId: 'npc-han-lap',
        displayName: 'Hàn Lập (Hàn Thỏ Đế)',
        avatarUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=120',
        streakDays: 15,
        completedQuestsCount: 42,
        realmIndex: 2,
        realmName: 'Kết Đan',
        subRealm: 2,
        realmText: 'Kết Đan Tầng 2',
        totalExp: 18500,
        isNpc: true,
      ),
      LeaderboardItem(
        rank: 2,
        userId: 'npc-tieu-viem',
        displayName: 'Tiêu Viêm (Viêm Đế)',
        avatarUrl: 'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=120',
        streakDays: 12,
        completedQuestsCount: 36,
        realmIndex: 1,
        realmName: 'Luyện Khí',
        subRealm: 9,
        realmText: 'Luyện Khí Tầng 9',
        totalExp: 12400,
        isNpc: true,
      ),
      LeaderboardItem(
        rank: 3,
        userId: 'npc-bach-tieu-thuan',
        displayName: 'Bạch Tiểu Thuần',
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
        streakDays: 10,
        completedQuestsCount: 29,
        realmIndex: 1,
        realmName: 'Luyện Khí',
        subRealm: 7,
        realmText: 'Luyện Khí Tầng 7',
        totalExp: 8900,
        isNpc: true,
      ),
      LeaderboardItem(
        rank: 4,
        userId: 'npc-lam-dong',
        displayName: 'Lâm Động (Vũ Tổ)',
        avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=120',
        streakDays: 7,
        completedQuestsCount: 21,
        realmIndex: 1,
        realmName: 'Luyện Khí',
        subRealm: 5,
        realmText: 'Luyện Khí Tầng 5',
        totalExp: 5400,
        isNpc: true,
      ),
      LeaderboardItem(
        rank: 5,
        userId: 'npc-diep-pham',
        displayName: 'Diệp Phàm (Diệp Thiên Đế)',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120',
        streakDays: 5,
        completedQuestsCount: 16,
        realmIndex: 1,
        realmName: 'Luyện Khí',
        subRealm: 4,
        realmText: 'Luyện Khí Tầng 4',
        totalExp: 3800,
        isNpc: true,
      ),
      LeaderboardItem(
        rank: 6,
        userId: 'npc-thach-hao',
        displayName: 'Thạch Hạo (Hoang Thiên Đế)',
        avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=120',
        streakDays: 4,
        completedQuestsCount: 12,
        realmIndex: 1,
        realmName: 'Luyện Khí',
        subRealm: 3,
        realmText: 'Luyện Khí Tầng 3',
        totalExp: 2600,
        isNpc: true,
      ),
      LeaderboardItem(
        rank: 7,
        userId: 'npc-muc-tran',
        displayName: 'Mục Trần (Mục Chủ)',
        avatarUrl: 'https://images.unsplash.com/photo-1628157582853-a796fa650a6a?w=120',
        streakDays: 2,
        completedQuestsCount: 7,
        realmIndex: 1,
        realmName: 'Luyện Khí',
        subRealm: 2,
        realmText: 'Luyện Khí Tầng 2',
        totalExp: 1500,
        isNpc: true,
      ),
    ];

    if (sortBy == 'streak') {
      fallbackItems.sort((a, b) => b.streakDays.compareTo(a.streakDays));
    } else if (sortBy == 'quests') {
      fallbackItems.sort((a, b) => b.completedQuestsCount.compareTo(a.completedQuestsCount));
    } else if (sortBy == 'realm') {
      fallbackItems.sort((a, b) {
        final realmComp = b.realmIndex.compareTo(a.realmIndex);
        if (realmComp != 0) return realmComp;
        final subComp = b.subRealm.compareTo(a.subRealm);
        if (subComp != 0) return subComp;
        return b.totalExp.compareTo(a.totalExp);
      });
    }

    final reRanked = List<LeaderboardItem>.generate(fallbackItems.length, (i) {
      final item = fallbackItems[i];
      return LeaderboardItem(
        rank: i + 1,
        userId: item.userId,
        displayName: item.displayName,
        avatarUrl: item.avatarUrl,
        streakDays: item.streakDays,
        completedQuestsCount: item.completedQuestsCount,
        realmIndex: item.realmIndex,
        realmName: item.realmName,
        subRealm: item.subRealm,
        realmText: item.realmText,
        totalExp: item.totalExp,
        isCurrentUser: item.isCurrentUser,
        isNpc: item.isNpc,
      );
    });

    return LeaderboardResult(
      success: true,
      sortBy: sortBy,
      totalUsers: reRanked.length,
      items: reRanked,
    );
  }
}
