import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/user_model.dart';
import '../../data/cultivation_repository.dart';
import '../../data/goal_analyzer_service.dart';
import '../../domain/quest_item.dart';
import '../widgets/active_session_card.dart';
import '../widgets/character_card.dart';
import '../widgets/create_campaign_card.dart';
import '../widgets/cultivation_realms_modal.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/daily_quests_section.dart';
import '../widgets/penalty_dialog.dart';
import '../widgets/profile_view.dart';
import '../widgets/statistics_view.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final CultivationRepository _cultivationRepository = CultivationRepository();
  final TextEditingController _campaignController = TextEditingController();

  int _currentNavIndex = 0;
  int _currentExp = 0;
  int _maxExp = 1000;
  int _streakDays = 0;
  int _spiritStones = 0;
  CultivationProfileModel? _cultivationProfile;
  bool _isGeneratingAi = false;

  String? _activeCampaignTitle;
  int _campaignTotalDays = 14;
  int _campaignCurrentDay = 1;
  String? _campaignStartDate;

  final List<QuestItem> _quests = [];
  Map<String, dynamic>? _statisticsData;
  bool _isLoadingStats = false;

  int get _completedCount => _quests.where((q) => q.isCompleted || q.isXpClaimed).length;

  String _toRoman(int number) {
    const romanMap = {
      1: 'I',
      2: 'II',
      3: 'III',
      4: 'IV',
      5: 'V',
      6: 'VI',
      7: 'VII',
      8: 'VIII',
      9: 'IX',
      10: 'X',
    };
    return romanMap[number] ?? '$number';
  }

  String get _currentChapterText {
    final realmIdx = _cultivationProfile?.realmIndex ?? 0;
    final roman = _toRoman(realmIdx + 1);
    if (_streakDays == 0) {
      return 'CHƯƠNG $roman • KHỞI ĐẦU TU TIÊN';
    }
    return 'CHƯƠNG $roman • CHUỖI NGÀY: $_streakDays';
  }

  String get _currentStoryTitle {
    final realmName = _cultivationProfile?.realmName ?? 'Phàm Nhân';
    if (realmName == 'Phàm Nhân') {
      return 'Phàm Nhân Bắt Đầu\nTu Tiên';
    }
    return '$realmName Tầng ${_cultivationProfile?.subRealm ?? 1}\nTu Tiên Lộ';
  }

  @override
  void initState() {
    super.initState();
    _loadCultivationProfile();
  }

  @override
  void dispose() {
    _campaignController.dispose();
    super.dispose();
  }

  Future<void> _saveLocalQuests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = _quests.map((q) => q.toJson()).toList();
      final uid = widget.user.id;
      await prefs.setString('daily_quests_cache_$uid', jsonEncode(listJson));
    } catch (_) {}
  }

  Future<void> _loadCultivationProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = widget.user.id;

      // Dọn dẹp key cũ không có uid để tránh tài khoản mới nhận nhầm cache cũ
      await prefs.remove('daily_quests_cache');
      await prefs.remove('active_camp_title');
      await prefs.remove('active_camp_duration');
      await prefs.remove('active_camp_start_date');
      await prefs.remove('active_camp_last_date');

      _activeCampaignTitle = prefs.getString('active_camp_title_$uid');
      _campaignTotalDays = prefs.getInt('active_camp_duration_$uid') ?? 14;
      _campaignStartDate = prefs.getString('active_camp_start_date_$uid');

      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final lastDate = prefs.getString('active_camp_last_date_$uid');

      if (_campaignStartDate != null) {
        try {
          final start = DateTime.parse(_campaignStartDate!);
          final now = DateTime.now();
          final diff = DateTime(now.year, now.month, now.day)
              .difference(DateTime(start.year, start.month, start.day))
              .inDays;
          _campaignCurrentDay = (diff + 1).clamp(1, _campaignTotalDays);
        } catch (_) {}
      }

      // 1. Tải danh sách nhiệm vụ đã lưu trong SharedPreferences (theo uid của user hiện tại)
      final cachedJsonStr = prefs.getString('daily_quests_cache_$uid');
      final List<QuestItem> loadedQuests = [];
      if (cachedJsonStr != null && cachedJsonStr.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedJsonStr);
          for (final item in decoded) {
            loadedQuests.add(QuestItem.fromJson(item));
          }
        } catch (_) {}
      }

      // 2. Nếu chưa có local cache, thử lấy từ backend campaigns
      if (loadedQuests.isEmpty) {
        final campaigns = await _cultivationRepository.getUserCampaigns();
        if (campaigns.isNotEmpty) {
          final activeCamp = campaigns.first;
          if (_activeCampaignTitle == null) {
            _activeCampaignTitle = activeCamp['title'];
            _campaignTotalDays = activeCamp['durationDays'] ?? 14;
          }
          final rawQuests = activeCamp['quests'];
          if (rawQuests is List) {
            for (final q in rawQuests.take(3)) {
              loadedQuests.add(GoalAnalyzerService.mapToQuestItem(q));
            }
          }
        }
      }

      // 3. Nếu vẫn rỗng nhưng đang có chiến dịch, phân tích tạo 3 nhiệm vụ
      if (loadedQuests.isEmpty && _activeCampaignTitle != null) {
        loadedQuests.addAll(GoalAnalyzerService.analyzeGoalAndCreateQuests(_activeCampaignTitle!));
      }

      // 4. Kiểm tra chuyển sang ngày mới:
      Map<String, dynamic>? penaltyData;
      final bool isNewDay = lastDate != null && lastDate != todayStr;
      if (isNewDay) {
        // Kiểm tra xem hôm trước có nhiệm vụ nào chưa hoàn thành không
        final uncompletedYesterday = loadedQuests.where((q) => !q.isCompleted).toList();
        if (uncompletedYesterday.isNotEmpty) {
          // Tính điểm trừ theo số nhiệm vụ chưa làm và độ khó:
          int calculatedPenalty = 0;
          for (final q in uncompletedYesterday) {
            final diffStr = q.difficulty.toString().toUpperCase();
            if (diffStr.contains('HARD') || diffStr.contains('KHÓ')) {
              calculatedPenalty += 50;
            } else if (diffStr.contains('MEDIUM') || diffStr.contains('VỪA')) {
              calculatedPenalty += 80;
            } else {
              calculatedPenalty += 120;
            }
          }
          final finalPenaltyExp = calculatedPenalty.clamp(50, 300);

          try {
            penaltyData = await _cultivationRepository.penalizeExp(
              uncompletedCount: uncompletedYesterday.length,
              customPenalty: finalPenaltyExp,
              reason: 'Chưa hoàn thành ${uncompletedYesterday.length} nhiệm vụ hôm trước (phạt $finalPenaltyExp Linh Lực)',
            );
          } catch (_) {}
        }

        if (_activeCampaignTitle != null) {
          loadedQuests.clear();
          loadedQuests.addAll(GoalAnalyzerService.analyzeGoalAndCreateQuests(_activeCampaignTitle!));
        }
        for (final q in loadedQuests) {
          q.isCompleted = false;
          q.isXpClaimed = false;
        }
        await prefs.setString('active_camp_last_date_$uid', todayStr);
      } else if (lastDate == null) {
        await prefs.setString('active_camp_last_date_$uid', todayStr);
      }

      final profile = await _cultivationRepository.getProfile();

      if (mounted) {
        setState(() {
          _cultivationProfile = profile;
          _currentExp = profile.currentExp;
          _maxExp = profile.maxExp;
          _spiritStones = profile.spiritStones;
          _streakDays = profile.streakDays;
          if (loadedQuests.isNotEmpty) {
            _quests.clear();
            _quests.addAll(loadedQuests.take(3));
          }
        });
        if (isNewDay && _quests.isNotEmpty) {
          _saveLocalQuests();
        }

        // Nếu có hình phạt Thiên Đạo, giáng lâm dialog
        if (penaltyData != null) {
          final data = penaltyData;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            PenaltyDialog.show(
              context,
              uncompletedCount: (data['uncompletedCount'] as num?)?.toInt() ?? 1,
              penaltyExp: (data['penaltyExp'] as num?)?.toInt() ?? 150,
              reason: data['reason']?.toString() ?? 'Chưa hoàn thành nhiệm vụ ngày hôm trước',
              demotedLevel: data['demotedLevel'] == true,
              demotedRealm: data['demotedRealm'] == true,
              previousRealmName: data['previousRealmName']?.toString() ?? '',
              previousSubRealm: (data['previousSubRealm'] as num?)?.toInt() ?? 1,
              currentRealmName: data['currentRealmName']?.toString() ?? '',
              currentSubRealm: (data['currentSubRealm'] as num?)?.toInt() ?? 1,
              remainingExp: (data['profile']?['currentExp'] as num?)?.toInt(),
              maxExp: (data['profile']?['maxExp'] as num?)?.toInt(),
              onDismiss: () {
                _loadCultivationProfile();
                _loadStatistics();
              },
            );
          });
        }
      }
      _loadStatistics();
    } catch (_) {}
  }



  Future<void> _loadStatistics() async {
    if (_isLoadingStats) return;
    setState(() {
      _isLoadingStats = true;
    });
    try {
      final stats = await _cultivationRepository.getStatistics();
      if (mounted && stats != null) {
        setState(() {
          _statisticsData = stats;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  void _toggleQuest(QuestItem quest) async {
    // Nếu nhiệm vụ đã hoàn thành thì không cho ticks lần nữa
    if (quest.isCompleted) return;

    final bool allDoneBefore = _quests.isNotEmpty && _quests.every((q) => q.isCompleted);

    setState(() {
      quest.isCompleted = true;
      quest.isXpClaimed = true;
      _currentExp += quest.xp;
      _spiritStones += quest.spiritStones;
    });
    _saveLocalQuests();

    final bool allDoneAfter = _quests.isNotEmpty && _quests.every((q) => q.isCompleted);
    if (!allDoneBefore && allDoneAfter) {
      setState(() {
        _streakDays += 1;
      });
    }

    try {
      final res = await _cultivationRepository.completeQuest(quest.id);
      if (res != null) {
        await _loadCultivationProfile();
        _loadStatistics();
      } else {
        // Fallback ghi nhận trực tiếp vào database qua addExp và addSpiritStones
        await _cultivationRepository.addExp(quest.xp);
        await _cultivationRepository.addSpiritStones(
          quest.spiritStones,
          'Thưởng hoàn thành nhiệm vụ: ${quest.title}',
        );
        await _loadCultivationProfile();
        _loadStatistics();
      }

      if (mounted) {
        if (!allDoneBefore && allDoneAfter) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF064E3B),
              content: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Color(0xFFF97316), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🎉 Đạo hữu đã hoàn thành xuất sắc 3/3 nhiệm vụ hôm nay! Chuỗi ngày tu luyện tăng lên $_streakDays ngày!',
                      style: const TextStyle(
                        color: Color(0xFFFDE68A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1E293B),
              content: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFF3C766), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hoàn thành tu luyện! +${quest.xp} Linh Lực, +${quest.spiritStones} Nguyên Thạch',
                      style: const TextStyle(
                        color: Color(0xFFFDE68A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (_) {}
  }

  void _addCampaign() async {
    final text = _campaignController.text.trim();
    if (text.isEmpty || _isGeneratingAi) return;

    final duration = GoalAnalyzerService.extractDurationDays(text);
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final uid = widget.user.id;

    setState(() {
      _isGeneratingAi = true;
      _activeCampaignTitle = text;
      _campaignTotalDays = duration;
      _campaignCurrentDay = 1;
      _campaignStartDate = todayStr;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_camp_title_$uid', text);
    await prefs.setInt('active_camp_duration_$uid', duration);
    await prefs.setString('active_camp_start_date_$uid', todayStr);
    await prefs.setString('active_camp_last_date_$uid', todayStr);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF142436),
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF2C465)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Thiên Đạo AI đang phân tích chiến dịch $duration ngày và tạo 3 nhiệm vụ mỗi ngày...'),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );

    List<QuestItem> newQuests = [];
    try {
      final campaignData = await _cultivationRepository.generateAiCampaign(text, durationDays: duration);
      if (campaignData != null && campaignData['quests'] != null) {
        final List<dynamic> rawQuests = campaignData['quests'];
        for (var q in rawQuests.take(3)) {
          newQuests.add(GoalAnalyzerService.mapToQuestItem(q));
        }
      }
    } catch (_) {}

    if (newQuests.isEmpty) {
      newQuests = GoalAnalyzerService.analyzeGoalAndCreateQuests(text);
    }

    if (mounted) {
      setState(() {
        _isGeneratingAi = false;
        _campaignController.clear();
        _quests.clear();
        _quests.addAll(newQuests.take(3));
      });
      _saveLocalQuests();
      _loadStatistics();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F261C),
          content: Text('Thiên Đạo đã khởi tạo chiến dịch $duration ngày với 3 nhiệm vụ hôm nay!'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildAvatarText() {
    final name = widget.user.displayName.trim();
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'M';
    return Text(
      letter,
      style: const TextStyle(
        color: Color(0xFFFDE68A),
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B12),
      body: Stack(
        children: [
          // 1. Background Image (Tiên Lộ Landscape)
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_tienlo.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0B1320)),
            ),
          ),

          // 2. Lighter Ambient Overlays (Bright, fantasy, celestial view)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF070B12).withValues(alpha: 0.12),
                    const Color(0xFF0B1424).withValues(alpha: 0.25),
                    const Color(0xFF070B12).withValues(alpha: 0.45),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Main Scrollable Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_currentNavIndex == 1) ...[
                        // Tab 1: THỐNG KÊ & HÀNH TRÌNH
                        StatisticsView(
                          profile: _cultivationProfile,
                          currentExp: _currentExp,
                          maxExp: _maxExp,
                          streakDays: _streakDays,
                          spiritStones: _spiritStones,
                          activeCampaignTitle: _activeCampaignTitle,
                          campaignCurrentDay: _campaignCurrentDay,
                          campaignTotalDays: _campaignTotalDays,
                          completedCount: _completedCount,
                          totalQuestsCount: _quests.length,
                          statisticsData: _statisticsData,
                          isLoading: _isLoadingStats,
                          onRefresh: _loadStatistics,
                        ),
                      ] else if (_currentNavIndex == 3) ...[
                        // Tab 3: CÁ NHÂN (HỒ SƠ TU LUYỆN)
                        ProfileView(
                          user: widget.user,
                          cultivationProfile: _cultivationProfile,
                          onSignOut: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final uid = widget.user.id;
                            await prefs.remove('daily_quests_cache');
                            await prefs.remove('daily_quests_cache_$uid');
                            await prefs.remove('active_camp_title');
                            await prefs.remove('active_camp_title_$uid');
                            await prefs.remove('active_camp_duration');
                            await prefs.remove('active_camp_duration_$uid');
                            await prefs.remove('active_camp_start_date');
                            await prefs.remove('active_camp_start_date_$uid');
                            await prefs.remove('active_camp_last_date');
                            await prefs.remove('active_camp_last_date_$uid');
                            await _authRepository.signOut();
                            widget.onLogout();
                          },
                        ),
                      ] else ...[
                        // Tab 0: HÔM NAY (DASHBOARD)
                        // Top Header: Title & Avatar
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentChapterText,
                                    style: const TextStyle(
                                      color: Color(0xFFE8B95E),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.8,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
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
                                      _currentStoryTitle,
                                      style: GoogleFonts.dancingScript(
                                        color: Colors.white,
                                        fontSize: 34,
                                        fontWeight: FontWeight.bold,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Avatar Icon (Tap opens Profile Tab)
                            GestureDetector(
                              onTap: () => setState(() => _currentNavIndex = 3),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF141F30),
                                  border: Border.all(
                                    color: const Color(0xFFE5B869),
                                    width: 1.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE5B869).withValues(alpha: 0.35),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: widget.user.photoUrl != null
                                      ? ClipOval(
                                          child: Image.network(
                                            widget.user.photoUrl!,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => _buildAvatarText(),
                                          ),
                                        )
                                      : _buildAvatarText(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // Card 1: NHÂN VẬT CỦA BẠN
                        CharacterCard(
                          profile: _cultivationProfile,
                          currentExp: _currentExp,
                          maxExp: _maxExp,
                          streakDays: _streakDays,
                          spiritStones: _spiritStones,
                          onTap: () {
                            if (_cultivationProfile != null) {
                              CultivationRealmsModal.show(context, _cultivationProfile!);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Card: THẺ XÁC ĐỊNH SESSION (Chiến dịch đang thực hiện)
                        if (_activeCampaignTitle != null && _activeCampaignTitle!.isNotEmpty) ...[
                          ActiveSessionCard(
                            activeCampaignTitle: _activeCampaignTitle!,
                            campaignCurrentDay: _campaignCurrentDay,
                            campaignTotalDays: _campaignTotalDays,
                            completedCount: _completedCount,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Card 2: Tạo chiến dịch mới
                        CreateCampaignCard(
                          controller: _campaignController,
                          isGeneratingAi: _isGeneratingAi,
                          onSubmitted: _addCampaign,
                        ),
                        const SizedBox(height: 24),

                        // Section 3: DAILY QUESTS
                        DailyQuestsSection(
                          quests: _quests,
                          completedCount: _completedCount,
                          onToggleQuest: _toggleQuest,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Floating Modern Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavBar(
              currentIndex: _currentNavIndex,
              onIndexChanged: (index) {
                if (index == 2) {
                  if (_cultivationProfile != null) {
                    CultivationRealmsModal.show(context, _cultivationProfile!);
                  }
                  return;
                }
                setState(() {
                  _currentNavIndex = index;
                });
                if (index == 1) {
                  _loadStatistics();
                }
              },
              onSparkleTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Khai mở Thần Thông • Tính năng đang phát triển!'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
