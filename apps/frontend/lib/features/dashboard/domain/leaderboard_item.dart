class LeaderboardItem {
  final int rank;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int streakDays;
  final int completedQuestsCount;
  final int realmIndex;
  final String realmName;
  final int subRealm;
  final String realmText;
  final int totalExp;
  final bool isCurrentUser;
  final bool isNpc;

  LeaderboardItem({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.streakDays,
    required this.completedQuestsCount,
    required this.realmIndex,
    required this.realmName,
    required this.subRealm,
    required this.realmText,
    required this.totalExp,
    this.isCurrentUser = false,
    this.isNpc = false,
  });

  factory LeaderboardItem.fromJson(Map<String, dynamic> json) {
    return LeaderboardItem(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? 'Đạo Hữu Tiên Lộ',
      avatarUrl: json['avatarUrl'],
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      completedQuestsCount: (json['completedQuestsCount'] as num?)?.toInt() ?? 0,
      realmIndex: (json['realmIndex'] as num?)?.toInt() ?? 0,
      realmName: json['realmName'] ?? 'Phàm Nhân',
      subRealm: (json['subRealm'] as num?)?.toInt() ?? 1,
      realmText: json['realmText'] ?? 'Phàm Nhân',
      totalExp: (json['totalExp'] as num?)?.toInt() ?? 0,
      isCurrentUser: json['isCurrentUser'] ?? false,
      isNpc: json['isNpc'] ?? false,
    );
  }
}

class LeaderboardResult {
  final bool success;
  final String sortBy;
  final int totalUsers;
  final LeaderboardItem? currentUser;
  final List<LeaderboardItem> items;

  LeaderboardResult({
    required this.success,
    required this.sortBy,
    required this.totalUsers,
    this.currentUser,
    required this.items,
  });

  factory LeaderboardResult.fromJson(Map<String, dynamic> json) {
    final rawList = json['leaderboard'] ?? json['items'] ?? json['data'];
    final list = (rawList as List<dynamic>?)
            ?.map((e) => LeaderboardItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    LeaderboardItem? current;
    if (json['currentUser'] != null && json['currentUser'] is Map<String, dynamic>) {
      current = LeaderboardItem.fromJson(json['currentUser'] as Map<String, dynamic>);
    } else {
      try {
        current = list.firstWhere((e) => e.isCurrentUser);
      } catch (_) {
        current = null;
      }
    }

    return LeaderboardResult(
      success: json['success'] ?? true,
      sortBy: json['sortBy'] ?? 'default',
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? list.length,
      currentUser: current,
      items: list,
    );
  }
}
