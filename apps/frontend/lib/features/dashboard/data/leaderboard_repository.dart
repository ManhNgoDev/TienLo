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
      final res = await _apiClient.get(endpoint, token: token);
      if (res != null && res is Map<String, dynamic>) {
        return LeaderboardResult.fromJson(res);
      }
    } catch (_) {}

    // Fallback nếu ngoại tuyến hoặc server chưa phản hồi kịp
    return _buildFallbackLeaderboard(sortBy);
  }

  LeaderboardResult _buildFallbackLeaderboard(String sortBy) {
    final fallbackItems = [
      LeaderboardItem(
        rank: 1,
        userId: 'npc-han-lap',
        displayName: 'Hàn Lập (Hàn Thỏ Đế)',
        avatarUrl: null,
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
        avatarUrl: null,
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
        avatarUrl: null,
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
        avatarUrl: null,
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
        avatarUrl: null,
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
        avatarUrl: null,
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
        avatarUrl: null,
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

    return LeaderboardResult(
      success: true,
      sortBy: sortBy,
      totalUsers: fallbackItems.length,
      items: fallbackItems,
    );
  }
}
