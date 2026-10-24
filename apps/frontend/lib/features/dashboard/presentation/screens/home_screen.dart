import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/user_model.dart';
import '../../data/cultivation_repository.dart';
import '../widgets/cultivation_realms_modal.dart';

class QuestItem {
  final String id;
  final String title;
  final String subtitle;
  final int xp;
  final int spiritStones;
  final String difficulty; // 'EASY', 'MEDIUM', 'HARD', 'BREAKTHROUGH'
  final IconData icon;
  final Color iconColor;
  bool isCompleted;
  bool isXpClaimed;

  QuestItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.xp,
    this.spiritStones = 15,
    this.difficulty = 'MEDIUM',
    required this.icon,
    required this.iconColor,
    this.isCompleted = false,
    this.isXpClaimed = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'xp': xp,
    'spiritStones': spiritStones,
    'difficulty': difficulty,
    'iconCode': icon.codePoint,
    'iconColor': iconColor.toARGB32(),
    'isCompleted': isCompleted,
    'isXpClaimed': isXpClaimed,
  };

  static IconData iconFromCode(int? code) {
    if (code == null) return Icons.fitness_center_rounded;
    if (code == Icons.restaurant_rounded.codePoint) return Icons.restaurant_rounded;
    if (code == Icons.fitness_center_rounded.codePoint) return Icons.fitness_center_rounded;
    if (code == Icons.bedtime_rounded.codePoint) return Icons.bedtime_rounded;
    if (code == Icons.water_drop_outlined.codePoint) return Icons.water_drop_outlined;
    if (code == Icons.directions_walk_rounded.codePoint) return Icons.directions_walk_rounded;
    if (code == Icons.auto_awesome.codePoint) return Icons.auto_awesome;
    if (code == Icons.military_tech_rounded.codePoint) return Icons.military_tech_rounded;
    if (code == Icons.track_changes_rounded.codePoint) return Icons.track_changes_rounded;
    // ignore: non_const_argument_for_const_parameter
    return IconData(code, fontFamily: 'MaterialIcons');
  }

  factory QuestItem.fromJson(Map<String, dynamic> json) => QuestItem(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    subtitle: json['subtitle']?.toString() ?? '',
    xp: (json['xp'] as num?)?.toInt() ?? 100,
    spiritStones: (json['spiritStones'] as num?)?.toInt() ?? 15,
    difficulty: json['difficulty']?.toString() ?? 'MEDIUM',
    icon: iconFromCode(json['iconCode'] as int?),
    iconColor: json['iconColor'] != null
        ? Color(json['iconColor'] as int)
        : const Color(0xFFF2C465),
    isCompleted: json['isCompleted'] == true,
    isXpClaimed: json['isXpClaimed'] == true,
  );
}

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
  final int _streakDays = 1;
  int _spiritStones = 50;
  CultivationProfileModel? _cultivationProfile;
  bool _isGeneratingAi = false;

  String? _activeCampaignTitle;
  int _campaignTotalDays = 14;
  int _campaignCurrentDay = 1;
  String? _campaignStartDate;

  final List<QuestItem> _quests = [];

  int get _completedCount => _quests.where((q) => q.isCompleted || q.isXpClaimed).length;

  @override
  void initState() {
    super.initState();
    _loadCultivationProfile();
  }

  int _extractDurationDays(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('nửa tháng') || lower.contains('nua thang')) return 15;
    if (lower.contains('một tháng') || lower.contains('mot thang')) return 30;
    if (lower.contains('hai tháng') || lower.contains('hai thang')) return 60;
    if (lower.contains('ba tháng') || lower.contains('ba thang')) return 90;
    if (lower.contains('một tuần') || lower.contains('mot tuan')) return 7;
    if (lower.contains('hai tuần') || lower.contains('hai tuan')) return 14;
    if (lower.contains('ba tuần') || lower.contains('ba tuan')) return 21;
    if (lower.contains('bốn tuần') || lower.contains('bon tuan')) return 28;

    final weekMatch = RegExp(r'(\d+)\s*(tuần|tuan)').firstMatch(lower);
    if (weekMatch != null) {
      return int.parse(weekMatch.group(1)!) * 7;
    }
    final monthMatch = RegExp(r'(\d+)\s*(tháng|thang)').firstMatch(lower);
    if (monthMatch != null) {
      return int.parse(monthMatch.group(1)!) * 30;
    }
    final dayMatch = RegExp(r'(\d+)\s*(ngày|ngay|ng)').firstMatch(lower);
    if (dayMatch != null) {
      return int.parse(dayMatch.group(1)!);
    }
    return 14;
  }

  Map<String, dynamic> _getDifficultyInfo(String diff) {
    final upper = diff.toUpperCase().trim();
    if (upper == 'EASY' || upper.contains('DỄ') || upper.contains('LUYỆN THỂ')) {
      return {
        'label': 'DỄ',
        'color': const Color(0xFF10B981),
        'bgColor': const Color(0xFF10B981).withValues(alpha: 0.15),
      };
    } else if (upper == 'HARD' || upper.contains('KHÓ') || upper.contains('NGƯNG ĐAN')) {
      return {
        'label': 'KHÓ',
        'color': const Color(0xFFF97316),
        'bgColor': const Color(0xFFF97316).withValues(alpha: 0.15),
      };
    } else if (upper == 'BREAKTHROUGH' || upper.contains('ĐỘT PHÁ') || upper.contains('THIÊN KIẾP')) {
      return {
        'label': 'ĐỘT PHÁ',
        'color': const Color(0xFFA855F7),
        'bgColor': const Color(0xFFA855F7).withValues(alpha: 0.18),
      };
    } else {
      return {
        'label': 'VỪA',
        'color': const Color(0xFFF59E0B),
        'bgColor': const Color(0xFFF59E0B).withValues(alpha: 0.15),
      };
    }
  }

  QuestItem _mapToQuestItem(dynamic q) {
    IconData icon = Icons.fitness_center_rounded;
    Color iconColor = const Color(0xFFF2C465);
    final iconType = q['iconType']?.toString().toLowerCase();
    if (iconType == 'water') {
      icon = Icons.water_drop_outlined;
      iconColor = const Color(0xFF38BDF8);
    } else if (iconType == 'walk') {
      icon = Icons.directions_walk_rounded;
      iconColor = const Color(0xFF34D399);
    } else if (iconType == 'meditation' || iconType == 'study') {
      icon = Icons.auto_awesome;
      iconColor = const Color(0xFFA78BFA);
    } else if (iconType == 'medal') {
      icon = Icons.military_tech_rounded;
      iconColor = const Color(0xFFFBBF24);
    }

    final diff = q['difficulty']?.toString().toUpperCase() ?? 'MEDIUM';
    final xp = (q['expReward'] as num?)?.toInt() ?? (q['xp'] as num?)?.toInt() ?? 150;
    final stones = (q['stoneReward'] as num?)?.toInt() ?? (q['spiritStones'] as num?)?.toInt() ?? 20;

    String subtitle = q['subtitle']?.toString() ?? 'Rèn luyện hàng ngày';
    subtitle = subtitle
        .replaceAll('Chiến dịch tu tiên mới · Hàng ngày', '')
        .replaceAll('Chiến dịch tu tiên mới', '')
        .replaceAll(RegExp(r'^(Luyện Thể|Trúc Cơ|Ngưng Đan|Thiên Kiếp|Đột Phá|Dễ|Vừa|Khó)\s*·\s*', caseSensitive: false), '')
        .trim();
    if (subtitle.isEmpty) {
      subtitle = 'Mục tiêu rèn luyện hàng ngày';
    }

    return QuestItem(
      id: q['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: q['title']?.toString() ?? 'Nhiệm vụ tu tiên',
      subtitle: subtitle,
      xp: xp,
      spiritStones: stones,
      difficulty: diff,
      icon: icon,
      iconColor: iconColor,
      isCompleted: q['isCompleted'] == true,
      isXpClaimed: q['isXpClaimed'] == true,
    );
  }

  List<QuestItem> _analyzeGoalAndCreateQuests(String prompt) {
    final lower = prompt.toLowerCase();
    final bool isWeightGain = RegExp(r'tăng\s*(thêm)?\s*(\d+)?\s*(cân|kg|ký)|bulk|tăng\s*cân').hasMatch(lower);
    final bool isFitness = RegExp(r'cơ|bụng|múi|gym|chạy|thể dục|cân|nặng|workout|mỡ|giảm').hasMatch(lower);
    final bool isStudy = RegExp(r'học|đọc|sách|code|lập trình|thi|tiếng anh|nghiên cứu').hasMatch(lower);

    final now = DateTime.now().millisecondsSinceEpoch;

    if (isWeightGain) {
      return [
        QuestItem(
          id: 'q-$now-1',
          title: 'Nạp 4-5 bữa ăn giàu dinh dưỡng',
          subtitle: 'Bổ sung thặng dư calo, protein và tinh bột tốt suốt cả ngày',
          xp: 100,
          spiritStones: 15,
          difficulty: 'EASY',
          icon: Icons.restaurant_rounded,
          iconColor: const Color(0xFF10B981),
        ),
        QuestItem(
          id: 'q-$now-2',
          title: 'Tập tạ kích thích cơ bắp 30 phút',
          subtitle: 'Tập các bài Compound (Squat, Deadlift) gia tăng đồng hóa',
          xp: 220,
          spiritStones: 25,
          difficulty: 'MEDIUM',
          icon: Icons.fitness_center_rounded,
          iconColor: const Color(0xFFF2C465),
        ),
        QuestItem(
          id: 'q-$now-3',
          title: 'Uống sinh tố dinh dưỡng & ngủ đủ 8 tiếng',
          subtitle: 'Tối ưu quá trình hấp thu và tái tạo cơ bắp ban đêm',
          xp: 350,
          spiritStones: 40,
          difficulty: 'HARD',
          icon: Icons.bedtime_rounded,
          iconColor: const Color(0xFFF97316),
        ),
      ];
    }

    if (isFitness) {
      return [
        QuestItem(
          id: 'q-$now-1',
          title: 'Uống đủ 2L nước lọc & hạn chế tối đa đường',
          subtitle: 'Thanh lọc cơ thể, hỗ trợ chuyển hóa mỡ thừa',
          xp: 80,
          spiritStones: 10,
          difficulty: 'EASY',
          icon: Icons.water_drop_outlined,
          iconColor: const Color(0xFF38BDF8),
        ),
        QuestItem(
          id: 'q-$now-2',
          title: 'Tập gập bụng & Plank 15 phút',
          subtitle: '3 hiệp Plank & Crunch kích hoạt cơ múi bụng',
          xp: 200,
          spiritStones: 25,
          difficulty: 'MEDIUM',
          icon: Icons.fitness_center_rounded,
          iconColor: const Color(0xFFF2C465),
        ),
        QuestItem(
          id: 'q-$now-3',
          title: 'Cardio hoặc chạy bộ 20 phút đốt mỡ',
          subtitle: 'Duy trì nhịp tim đốt calo thâm hụt sau buổi tập',
          xp: 350,
          spiritStones: 40,
          difficulty: 'HARD',
          icon: Icons.directions_walk_rounded,
          iconColor: const Color(0xFFF97316),
        ),
      ];
    }

    if (isStudy) {
      return [
        QuestItem(
          id: 'q-$now-1',
          title: 'Đọc sách hoặc tài liệu 20 phút',
          subtitle: 'Khởi động tư duy mỗi sáng bằng tri thức mới',
          xp: 80,
          spiritStones: 10,
          difficulty: 'EASY',
          icon: Icons.menu_book_rounded,
          iconColor: const Color(0xFF38BDF8),
        ),
        QuestItem(
          id: 'q-$now-2',
          title: 'Tập trung học sâu 45 phút Pomodoro',
          subtitle: 'Tuyệt đối không lướt mạng xã hội, tập trung cao độ',
          xp: 200,
          spiritStones: 25,
          difficulty: 'MEDIUM',
          icon: Icons.auto_awesome,
          iconColor: const Color(0xFFF59E0B),
        ),
        QuestItem(
          id: 'q-$now-3',
          title: 'Thực hành làm bài tập hoặc viết code 30 phút',
          subtitle: 'Ứng dụng trực tiếp kiến thức vừa học vào thực tế',
          xp: 350,
          spiritStones: 40,
          difficulty: 'HARD',
          icon: Icons.code_rounded,
          iconColor: const Color(0xFFF97316),
        ),
      ];
    }

    return [
      QuestItem(
        id: 'q-$now-1',
        title: 'Hành động nhỏ khởi đầu ngày mới',
        subtitle: 'Dành 20 phút hành động kiên trì cho mục tiêu',
        xp: 80,
        spiritStones: 10,
        difficulty: 'EASY',
        icon: Icons.auto_awesome,
        iconColor: const Color(0xFF10B981),
      ),
      QuestItem(
        id: 'q-$now-2',
        title: 'Thực hiện cam kết rèn luyện hôm nay',
        subtitle: 'Tập trung hoàn thành chỉ tiêu đề ra',
        xp: 200,
        spiritStones: 25,
        difficulty: 'MEDIUM',
        icon: Icons.track_changes_rounded,
        iconColor: const Color(0xFFF2C465),
      ),
      QuestItem(
        id: 'q-$now-3',
        title: 'Thử thách bứt phá giới hạn',
        subtitle: 'Nâng cao cường độ rèn luyện trong ngày',
        xp: 350,
        spiritStones: 40,
        difficulty: 'HARD',
        icon: Icons.military_tech_rounded,
        iconColor: const Color(0xFFF97316),
      ),
    ];
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
              loadedQuests.add(_mapToQuestItem(q));
            }
          }
        }
      }

      // 3. Nếu vẫn rỗng nhưng đang có chiến dịch, phân tích tạo 3 nhiệm vụ
      if (loadedQuests.isEmpty && _activeCampaignTitle != null) {
        loadedQuests.addAll(_analyzeGoalAndCreateQuests(_activeCampaignTitle!));
      }

      // 4. Kiểm tra chuyển sang ngày mới:
      // Khi sang ngày hôm sau (todayStr != lastDate):
      // - Tự động làm mới/tạo mới 3 nhiệm vụ cho ngày hôm nay và reset trạng thái chưa hoàn thành
      final bool isNewDay = lastDate != null && lastDate != todayStr;
      if (isNewDay) {
        if (_activeCampaignTitle != null) {
          loadedQuests.clear();
          loadedQuests.addAll(_analyzeGoalAndCreateQuests(_activeCampaignTitle!));
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
          if (loadedQuests.isNotEmpty) {
            _quests.clear();
            _quests.addAll(loadedQuests.take(3));
          }
        });
        if (isNewDay && _quests.isNotEmpty) {
          _saveLocalQuests();
        }
      }
    } catch (_) {}
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
      } catch (_) {}
    }
  }

  void _addCampaign() async {
    final text = _campaignController.text.trim();
    if (text.isEmpty || _isGeneratingAi) return;

    final duration = _extractDurationDays(text);
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
          newQuests.add(_mapToQuestItem(q));
        }
      }
    } catch (_) {}

    // Nếu API mạng chưa khả dụng, dùng bộ suy diễn thông minh nội bộ (đúng 3 nhiệm vụ mỗi ngày)
    if (newQuests.isEmpty) {
      newQuests = _analyzeGoalAndCreateQuests(text);
    }

    if (mounted) {
      setState(() {
        _isGeneratingAi = false;
        _campaignController.clear();
        _quests.clear();
        _quests.addAll(newQuests.take(3));
      });
      _saveLocalQuests();

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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1B2B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF1E2E42),
                  backgroundImage: widget.user.photoUrl != null
                      ? NetworkImage(widget.user.photoUrl!)
                      : null,
                  child: widget.user.photoUrl == null
                      ? const Icon(Icons.person_rounded, size: 36, color: Color(0xFFE5B869))
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.user.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.user.email,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text('Đăng xuất tài khoản', style: TextStyle(color: AppColors.error)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _authRepository.signOut();
                    widget.onLogout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _campaignController.dispose();
    super.dispose();
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

          // 2. Dark Ambient Overlays
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF070B12).withValues(alpha: 0.7),
                    const Color(0xFF0B1424).withValues(alpha: 0.8),
                    const Color(0xFF070B12).withValues(alpha: 0.95),
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
                      // Top Header: Title & Avatar
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CHƯƠNG I • NGÀY THỨ 12',
                                  style: TextStyle(
                                    color: Color(0xFFE8B95E),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
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
                                  child: const Text(
                                    'Phàm Nhân Bắt Đầu\nTu Tiên',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontStyle: FontStyle.italic,
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
                      _buildCharacterCard(),
                      const SizedBox(height: 16),

                      // Card 2: Tạo chiến dịch mới
                      _buildCampaignCard(),
                      const SizedBox(height: 24),

                      // Section 3: DAILY QUESTS
                      _buildDailyQuestsSection(),
                      const SizedBox(height: 24),

                      // Section 4: HOẠT ĐỘNG NHANH
                      _buildQuickActionsSection(),
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
            child: _buildBottomNavBar(),
          ),
        ],
      ),
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

  String _formatExp(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // Card: Nhân Vật Của Bạn
  Widget _buildCharacterCard() {
    final expPercent = (_currentExp / _maxExp).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        if (_cultivationProfile != null) {
          CultivationRealmsModal.show(context, _cultivationProfile!);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF07121E).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFC59A44),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3.5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF091422).withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFC59A44).withValues(alpha: 0.75),
                  width: 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Lotus Badge
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0A1422),
                      border: Border.all(
                        color: const Color(0xFFC59A44),
                        width: 1.3,
                      ),
                    ),
                    child: const Center(
                      child: CustomPaint(
                        size: Size(26, 26),
                        painter: LotusFlowerPainter(
                          color: Color(0xFFF2C465),
                          strokeWidth: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // 2. Character Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'NHÂN VẬT CỦA BẠN',
                          style: TextStyle(
                            color: Color(0xFF70BFE6),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _cultivationProfile != null
                              ? (_cultivationProfile!.realmIndex == 0
                                  ? 'Phàm Nhân'
                                  : '${_cultivationProfile!.realmName} • Tầng ${_cultivationProfile!.subRealm}')
                              : 'Phàm Nhân',
                          style: const TextStyle(
                            fontFamily: 'serif',
                            color: Color(0xFFFFF6DF),
                            fontSize: 17.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Progress Bar
                        Container(
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C1624),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children: [
                                  Container(
                                    width: constraints.maxWidth * expPercent,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2C465),
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFF2C465).withValues(alpha: 0.45),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_formatExp(_currentExp)} / ${_formatExp(_maxExp)} Linh Lực',
                          style: const TextStyle(
                            color: Color(0xFF8BA5BA),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // 3. Streak Days (Flame + Days + Stones)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$_streakDays',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'ngày',
                        style: TextStyle(
                          color: Color(0xFF8BA5BA),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.diamond_outlined, color: Color(0xFF38BDF8), size: 12),
                          const SizedBox(width: 3),
                          Text(
                            '$_spiritStones',
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Card: Tạo chiến dịch mới
  Widget _buildCampaignCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF07121E).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFC59A44),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon + Texts
              Row(
                children: [
                  // Double Border Sparkle Icon Box
                  Container(
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1422),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFC59A44),
                        width: 1.3,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF08111D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFC59A44).withValues(alpha: 0.75),
                          width: 1.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFF2C465),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tạo chiến dịch mới',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'AI biến mục tiêu lớn thành nhiệm vụ vừa sức.',
                          style: TextStyle(
                            color: Color(0xFF8BA5BA),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bottom Input Bar with Arrow Button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF07101B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFC59A44),
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.only(left: 16, right: 5, top: 4, bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _campaignController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Ví dụ: Chạy được 5km sau 8 tuần...',
                          hintStyle: TextStyle(
                            color: Color(0xFF7E98AE),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _addCampaign(),
                      ),
                    ),
                    GestureDetector(
                      onTap: _addCampaign,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1522),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFC59A44),
                            width: 1.2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFFF2C465),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Section 3: Daily Quests
  Widget _buildDailyQuestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'DAILY QUESTS',
                      style: TextStyle(
                        color: Color(0xFFE8B95E),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                      ),
                    ),
                    if (_activeCampaignTitle != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC59A44).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFC59A44).withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Ngày $_campaignCurrentDay/$_campaignTotalDays',
                          style: const TextStyle(
                            color: Color(0xFFF2C465),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  '3 Nhiệm vụ tu tiên hôm nay',
                  style: TextStyle(
                    color: Color(0xFFFFF2D1),
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_quests.isNotEmpty)
              Text(
                '$_completedCount/${_quests.length} đã hoàn thành',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11.5,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // List of Quests or Cultivation Empty State
        if (_quests.isEmpty)
          _buildEmptyQuestsCard()
        else
          ..._quests.map((quest) => _buildQuestCard(quest)),
      ],
    );
  }

  Widget _buildEmptyQuestsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
          decoration: BoxDecoration(
            color: const Color(0xFF07121E).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFC59A44).withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0B1726),
                  border: Border.all(
                    color: const Color(0xFFF2C465).withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFF2C465),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Chưa có nhiệm vụ tu luyện',
                style: TextStyle(
                  fontFamily: 'serif',
                  color: Color(0xFFFFF6DF),
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hãy nhập mục tiêu vào "Tạo chiến dịch mới" phía trên để Thiên Đạo AI diễn toán và ban bố nhiệm vụ tu chân cho đạo hữu!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8BA5BA),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestCard(QuestItem quest) {
    final bool hasStrikethrough = quest.isXpClaimed || quest.isCompleted;
    final diffInfo = _getDifficultyInfo(quest.difficulty);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF07121E).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: quest.isCompleted
                  ? const Color(0xFFC59A44).withValues(alpha: 0.4)
                  : const Color(0xFFC59A44),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Left: Icon Box
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1422),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: quest.iconColor,
                    width: 1.3,
                  ),
                ),
                child: Center(
                  child: _buildQuestIcon(quest),
                ),
              ),
              const SizedBox(width: 12),

              // 2. Middle: Difficulty Badge + Title + Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Difficulty Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: diffInfo['bgColor'],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (diffInfo['color'] as Color).withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        diffInfo['label'],
                        style: TextStyle(
                          color: diffInfo['color'],
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Title
                    Text(
                      quest.title,
                      style: TextStyle(
                        color: hasStrikethrough ? const Color(0xFF8BA5BA) : Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                        decoration: hasStrikethrough ? TextDecoration.lineThrough : null,
                        decorationColor: const Color(0xFF8BA5BA),
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Subtitle
                    Text(
                      quest.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7E98AE),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // 3. Right: Rewards (EXP + Spirit Stones) & Checkbox
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // EXP Reward
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFFF2C465), size: 12),
                      const SizedBox(width: 3),
                      Text(
                        '+${quest.xp} EXP',
                        style: TextStyle(
                          color: const Color(0xFFF2C465),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          decoration: hasStrikethrough
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: const Color(0xFFF2C465),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Spirit Stones Reward (Nguyên Thạch)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.diamond_outlined, color: Color(0xFF38BDF8), size: 12),
                      const SizedBox(width: 3),
                      Text(
                        '+${quest.spiritStones} Nguyên Thạch',
                        style: TextStyle(
                          color: const Color(0xFF38BDF8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          decoration: hasStrikethrough
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: const Color(0xFF38BDF8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Checkbox Circle
                  GestureDetector(
                    onTap: () => _toggleQuest(quest),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: quest.isCompleted
                            ? const Color(0xFFF2C465).withValues(alpha: 0.15)
                            : Colors.transparent,
                        border: Border.all(
                          color: quest.isCompleted
                              ? const Color(0xFFF2C465)
                              : const Color(0xFF5A758D),
                          width: 1.6,
                        ),
                      ),
                      child: quest.isCompleted
                          ? const Center(
                              child: Icon(
                                Icons.check_rounded,
                                color: Color(0xFFF2C465),
                                size: 18,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestIcon(QuestItem quest) {
    if (quest.id == '1') {
      return CustomPaint(
        size: const Size(26, 26),
        painter: BarbellIconPainter(color: quest.iconColor),
      );
    } else if (quest.id == '2') {
      return Icon(
        Icons.water_drop_outlined,
        color: quest.iconColor,
        size: 24,
      );
    } else if (quest.id == '3') {
      return CustomPaint(
        size: const Size(24, 24),
        painter: FootprintIconPainter(color: quest.iconColor),
      );
    }
    return Icon(quest.icon, color: quest.iconColor, size: 22);
  }

  // Section 4: Quick Actions
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'HOẠT ĐỘNG NHANH',
              style: TextStyle(
                color: Color(0xFFE8B95E),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A3D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF3C766).withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Text(
                    '1.260',
                    style: TextStyle(
                      color: Color(0xFFFDE68A),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.monetization_on_rounded, color: Color(0xFFF59E0B), size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Horizontal Row of Action Cards
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.emoji_events_rounded,
                iconColor: const Color(0xFFF87171),
                title: 'Rương ngày',
                subtitle: 'Phần thưởng',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionCard(
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFFFBBF24),
                title: 'Thiền định',
                subtitle: '15 phút',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionCard(
                icon: Icons.edit_note_rounded,
                iconColor: const Color(0xFF34D399),
                title: 'Nhật ký',
                subtitle: 'Ghi chép',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E2E).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF283B4F).withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // Floating Bottom Navigation Bar
  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A121D).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF2A3D54).withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(index: 0, icon: Icons.home_rounded, label: 'Hôm nay'),
          _buildNavItem(index: 1, icon: Icons.explore_outlined, label: 'Bản đồ'),

          // Center Floating Celestial Sparkle Button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Khai mở Thần Thông • Tính năng đang phát triển!'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFDE68A), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withValues(alpha: 0.6),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFF111827),
                size: 22,
              ),
            ),
          ),

          _buildNavItem(index: 2, icon: Icons.bolt_rounded, label: 'Nhân vật'),
          _buildNavItem(index: 3, icon: Icons.person_outline_rounded, label: 'Cá nhân'),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentNavIndex = index;
        });
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? const Color(0xFFF3C766) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFF3C766) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LotusFlowerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const LotusFlowerPainter({
    required this.color,
    this.strokeWidth = 1.6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // 1. Center upright almond/lotus petal
    final centerPetal = Path();
    centerPetal.moveTo(cx, h * 0.16);
    centerPetal.cubicTo(cx + w * 0.16, h * 0.38, cx + w * 0.16, h * 0.65, cx, h * 0.80);
    centerPetal.cubicTo(cx - w * 0.16, h * 0.65, cx - w * 0.16, h * 0.38, cx, h * 0.16);
    canvas.drawPath(centerPetal, paint);

    // 2. Left petal: flares outwards and up, meeting center at bottom join
    final leftPetal = Path();
    leftPetal.moveTo(cx, h * 0.80);
    leftPetal.cubicTo(cx - w * 0.18, h * 0.82, cx - w * 0.46, h * 0.64, cx - w * 0.40, h * 0.38);
    leftPetal.cubicTo(cx - w * 0.28, h * 0.48, cx - w * 0.16, h * 0.66, cx, h * 0.80);
    canvas.drawPath(leftPetal, paint);

    // 3. Right petal: flares outwards and up symmetrically
    final rightPetal = Path();
    rightPetal.moveTo(cx, h * 0.80);
    rightPetal.cubicTo(cx + w * 0.18, h * 0.82, cx + w * 0.46, h * 0.64, cx + w * 0.40, h * 0.38);
    rightPetal.cubicTo(cx + w * 0.28, h * 0.48, cx + w * 0.16, h * 0.66, cx, h * 0.80);
    canvas.drawPath(rightPetal, paint);
  }

  @override
  bool shouldRepaint(covariant LotusFlowerPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

class BarbellIconPainter extends CustomPainter {
  final Color color;

  const BarbellIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cy = h / 2;

    // Horizontal bar
    paint.strokeWidth = 2.4;
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.16, cy), Offset(w * 0.84, cy), paint);

    // Left outer plate
    paint.strokeWidth = 3.2;
    canvas.drawLine(Offset(w * 0.22, cy - h * 0.28), Offset(w * 0.22, cy + h * 0.28), paint);

    // Left inner plate
    paint.strokeWidth = 2.4;
    canvas.drawLine(Offset(w * 0.32, cy - h * 0.20), Offset(w * 0.32, cy + h * 0.20), paint);

    // Right inner plate
    canvas.drawLine(Offset(w * 0.68, cy - h * 0.20), Offset(w * 0.68, cy + h * 0.20), paint);

    // Right outer plate
    paint.strokeWidth = 3.2;
    canvas.drawLine(Offset(w * 0.78, cy - h * 0.28), Offset(w * 0.78, cy + h * 0.28), paint);
  }

  @override
  bool shouldRepaint(covariant BarbellIconPainter oldDelegate) => oldDelegate.color != color;
}

class FootprintIconPainter extends CustomPainter {
  final Color color;

  const FootprintIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-0.35); // tilt ~20 degrees

    final path = Path();
    // Top loop (toe area)
    path.moveTo(0, -h * 0.32);
    path.cubicTo(w * 0.20, -h * 0.32, w * 0.22, -h * 0.08, w * 0.08, 0);
    // Waist curve
    path.cubicTo(w * 0.04, h * 0.04, w * 0.22, h * 0.12, w * 0.20, h * 0.30);
    // Bottom heel curve
    path.cubicTo(w * 0.18, h * 0.38, -w * 0.18, h * 0.38, -w * 0.20, h * 0.30);
    // Waist curve back
    path.cubicTo(-w * 0.22, h * 0.12, -w * 0.04, h * 0.04, -w * 0.08, 0);
    // Top curve back
    path.cubicTo(-w * 0.22, -h * 0.08, -w * 0.20, -h * 0.32, 0, -h * 0.32);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FootprintIconPainter oldDelegate) => oldDelegate.color != color;
}
