import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final ScrollController _scrollController = ScrollController();

  String _selectedSort = 'default';
  bool _isLoading = true;
  LeaderboardResult? _leaderboardData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
              Column(
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
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Trật tự sắp xếp: Chuỗi ngày tu luyện ➔ Nhiệm vụ hoàn thành ➔ Cảnh giới tầng X',
            style: TextStyle(
              fontSize: 11.5,
              color: const Color(0xFF94A3B8).withValues(alpha: 0.9),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _leaderboardData?.items ?? [];
    final currentUserItem = _leaderboardData?.currentUser;

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefreshParent?.call();
        await _fetchLeaderboard();
      },
      color: const Color(0xFFF3C766),
      backgroundColor: const Color(0xFF0F1B2C),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 14),

            LeaderboardSortBar(
              selectedSort: _selectedSort,
              onSortChanged: _onSortChanged,
            ),
            const SizedBox(height: 16),

            if (currentUserItem != null) ...[
              UserStandingCard(currentUser: currentUserItem),
            ],

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
              if (items.length >= 3) ...[
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

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return LeaderboardCard(item: items[index]);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
