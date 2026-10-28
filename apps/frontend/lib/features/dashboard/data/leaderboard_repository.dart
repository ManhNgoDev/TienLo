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
    // Không dùng danh sách NPC giả, trả về danh sách rỗng để bảo toàn dữ liệu người chơi thật từ database
    return LeaderboardResult(
      success: false,
      sortBy: sortBy,
      totalUsers: 0,
      items: const [],
    );
  }
}
