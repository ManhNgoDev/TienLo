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
import '../widgets/profile_modal.dart';
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
  int _streakDays = 1;
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
    return 'CHƯƠNG $roman • NGÀY THỨ $_streakDays';
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
      await prefs.setString('daily_quests_cache', jsonEncode(listJson));
    } catch (_) {}
  }

  Future<void> _loadCultivationProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _activeCampaignTitle = prefs.getString('active_camp_title');
      _campaignTotalDays = prefs.getInt('active_camp_duration') ?? 14;
      _campaignStartDate = prefs.getString('active_camp_start_date');

      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final lastDate = prefs.getString('active_camp_last_date');

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

      // 1. Tải danh sách nhiệm vụ đã lưu trong SharedPreferences (nếu có)
      final cachedJsonStr = prefs.getString('daily_quests_cache');
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
      final bool isNewDay = lastDate != null && lastDate != todayStr;
      if (isNewDay) {
        if (_activeCampaignTitle != null) {
          loadedQuests.clear();
          loadedQuests.addAll(GoalAnalyzerService.analyzeGoalAndCreateQuests(_activeCampaignTitle!));
        }
        for (final q in loadedQuests) {
          q.isCompleted = false;
          q.isXpClaimed = false;
        }
        await prefs.setString('active_camp_last_date', todayStr);
      } else if (lastDate == null) {
        await prefs.setString('active_camp_last_date', todayStr);
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
    final previousCompleted = quest.isCompleted;
    setState(() {
      quest.isCompleted = !quest.isCompleted;
      quest.isXpClaimed = quest.isCompleted;
      if (quest.isCompleted) {
        _currentExp += quest.xp;
        _spiritStones += quest.spiritStones;
      } else {
        _currentExp = (_currentExp - quest.xp).clamp(0, 100000);
        _spiritStones = (_spiritStones - quest.spiritStones).clamp(0, 100000);
      }
    });
    _saveLocalQuests();

    if (!previousCompleted) {
      try {
        final res = await _cultivationRepository.completeQuest(quest.id);
        if (res != null) {
          await _loadCultivationProfile();
          _loadStatistics();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1E293B),
              content: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFF3C766), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hoàn thành tu luyện! +${quest.xp} EXP, +${quest.spiritStones} Nguyên Thạch',
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
      } catch (_) {}
    }
  }

  void _addCampaign() async {
    final text = _campaignController.text.trim();
    if (text.isEmpty || _isGeneratingAi) return;

    final duration = GoalAnalyzerService.extractDurationDays(text);
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    setState(() {
      _isGeneratingAi = true;
      _activeCampaignTitle = text;
      _campaignTotalDays = duration;
      _campaignCurrentDay = 1;
      _campaignStartDate = todayStr;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_camp_title', text);
    await prefs.setInt('active_camp_duration', duration);
    await prefs.setString('active_camp_start_date', todayStr);
    await prefs.setString('active_camp_last_date', todayStr);

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

  void _showProfileModal() {
    ProfileModal.show(
      context,
      user: widget.user,
      onSignOut: () async {
        await _authRepository.signOut();
        widget.onLogout();
      },
    );
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
                            // Avatar Icon
                            GestureDetector(
                              onTap: _showProfileModal,
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
                if (index == 3) {
                  _showProfileModal();
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
