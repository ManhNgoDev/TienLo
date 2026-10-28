import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/domain/user_model.dart';
import '../../data/cultivation_repository.dart';
import '../../data/leaderboard_repository.dart';
import '../../domain/leaderboard_item.dart';
import 'leaderboard/leaderboard_card.dart';
import 'leaderboard/leaderboard_podium.dart';
import 'leaderboard/leaderboard_sort_bar.dart';
import 'leaderboard/user_standing_card.dart';

class LeaderboardView extends StatefulWidget {
  final UserModel currentUser;
  final CultivationProfileModel? cultivationProfile;
  final int streakDays;
  final int completedCount;
  final VoidCallback? onRefreshParent;

  const LeaderboardView({
    super.key,
    required this.currentUser,
    this.cultivationProfile,
    required this.streakDays,
    required this.completedCount,
    this.onRefreshParent,
  });

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  final LeaderboardRepository _repository = LeaderboardRepository();

  String _selectedSort = 'default';
  bool _isLoading = true;
  LeaderboardResult? _leaderboardData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _repository.getLeaderboard(sortBy: _selectedSort);
      if (mounted) {
        setState(() {
          _leaderboardData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải bảng xếp hạng: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onSortChanged(String newSort) {
    if (_selectedSort == newSort) return;
    setState(() {
      _selectedSort = newSort;
    });
    _fetchLeaderboard();
  }

  int _calculateRank(int streak, int quests, CultivationProfileModel? profile) {
    final items = _leaderboardData?.items ?? [];
    if (items.isEmpty) return 1;

    final existingIdx = items.indexWhere((e) => e.isCurrentUser || e.userId == widget.currentUser.id);
    if (existingIdx != -1) return items[existingIdx].rank;

    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      if (_selectedSort == 'streak') {
        if (streak > it.streakDays) return i + 1;
      } else if (_selectedSort == 'quests') {
        if (quests > it.completedQuestsCount) return i + 1;
      } else if (_selectedSort == 'realm') {
        final pRealm = profile?.realmIndex ?? 0;
        final pSub = profile?.subRealm ?? 1;
        if (pRealm > it.realmIndex || (pRealm == it.realmIndex && pSub > it.subRealm)) {
          return i + 1;
        }
      } else {
        if (streak > it.streakDays) return i + 1;
      }
    }
    return items.length + 1;
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3C766).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF3C766).withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFF3C766),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BẢNG PHONG THẦN • LEO TOP',
                      style: TextStyle(
                        color: Color(0xFFE8B95E),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFFFF2D1),
                          Color(0xFFF6CE70),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'Thiên Kiêu Tiên Lộ',
                        style: GoogleFonts.dancingScript(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        widget.onRefreshParent?.call();
                        _fetchLeaderboard();
                      },
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFF3C766),
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFFF3C766),
                        size: 22,
                      ),
                tooltip: 'Đồng bộ bảng phong thần',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Chuỗi tu luyện ➔ Nhiệm vụ hoàn thành ➔ Cảnh giới',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: const Color(0xFF94A3B8).withValues(alpha: 0.9),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (ApiConstants.isLocal
                          ? const Color(0xFF10B981)
                          : const Color(0xFF38BDF8))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (ApiConstants.isLocal
                            ? const Color(0xFF10B981)
                            : const Color(0xFF38BDF8))
                        .withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  ApiConstants.isLocal ? '⚡ Local API' : '☁️ Cloud API',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: ApiConstants.isLocal
                        ? const Color(0xFF34D399)
                        : const Color(0xFF7DD3FC),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _leaderboardData?.items ?? [];
    final currentUserItem = _leaderboardData?.currentUser;
    final resolvedCurrentUser = currentUserItem ??
        LeaderboardItem(
          rank: _calculateRank(
            widget.streakDays,
            widget.completedCount,
            widget.cultivationProfile,
          ),
          userId: widget.currentUser.id,
          displayName: widget.currentUser.displayName,
          avatarUrl: widget.currentUser.photoUrl,
          streakDays: widget.streakDays,
          completedQuestsCount: widget.completedCount,
          realmIndex: widget.cultivationProfile?.realmIndex ?? 0,
          realmName: widget.cultivationProfile?.realmName ?? 'Phàm Nhân',
          subRealm: widget.cultivationProfile?.subRealm ?? 1,
          realmText: widget.cultivationProfile != null
              ? '${widget.cultivationProfile!.realmName} Tầng ${widget.cultivationProfile!.subRealm}'
              : 'Phàm Nhân',
          totalExp: widget.cultivationProfile?.totalExp ?? 0,
          isCurrentUser: true,
          isNpc: false,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 14),

        LeaderboardSortBar(
          selectedSort: _selectedSort,
          onSortChanged: _onSortChanged,
        ),
        const SizedBox(height: 16),

        UserStandingCard(currentUser: resolvedCurrentUser),

        if (_isLoading) ...[
          const SizedBox(height: 60),
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  color: Color(0xFFF3C766),
                  strokeWidth: 2.5,
                ),
                SizedBox(height: 14),
                Text(
                  'Đang thấu thị Tiên Bảng...',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
        ] else if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _fetchLeaderboard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3C766),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Thử Lại'),
                ),
              ],
            ),
          ),
        ] else if (items.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: const Text(
              'Chưa có dữ liệu bảng phong thần.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ),
        ] else ...[
          if (items.isNotEmpty) ...[
            LeaderboardPodium(items: items),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DANH SÁCH THIÊN KIÊU (${items.length})',
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF3C766),
                  letterSpacing: 1.4,
                ),
              ),
              const Text(
                'Đồng bộ tức thời',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ...items.map((item) => LeaderboardCard(item: item)),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
