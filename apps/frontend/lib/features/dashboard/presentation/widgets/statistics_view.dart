import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/cultivation_repository.dart';

class StatisticsView extends StatelessWidget {
  final CultivationProfileModel? profile;
  final int currentExp;
  final int maxExp;
  final int streakDays;
  final int spiritStones;
  final String? activeCampaignTitle;
  final int campaignCurrentDay;
  final int campaignTotalDays;
  final int completedCount;
  final int totalQuestsCount;

  const StatisticsView({
    super.key,
    required this.profile,
    required this.currentExp,
    required this.maxExp,
    required this.streakDays,
    required this.spiritStones,
    required this.activeCampaignTitle,
    required this.campaignCurrentDay,
    required this.campaignTotalDays,
    required this.completedCount,
    required this.totalQuestsCount,
  });

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (activeCampaignTitle != null && activeCampaignTitle!.isNotEmpty)
        ? activeCampaignTitle!
        : 'Kiến Tạo Phiên Bản 2.0';

    final int currentWeek = ((campaignCurrentDay - 1) ~/ 7) + 1;
    final int totalWeeks = (campaignTotalDays / 7).ceil().clamp(1, 52);
    final double campaignProgress = (campaignCurrentDay / campaignTotalDays).clamp(0.0, 1.0);
    final int completionRate = totalQuestsCount > 0
        ? ((completedCount / totalQuestsCount) * 100).toInt()
        : 85;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Header: Tag + Title + Bell Icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BẢN ĐỒ CHIẾN DỊCH • THỐNG KÊ',
                  style: TextStyle(
                    color: Color(0xFFE8B95E),
                    fontSize: 11,
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
                    'Hành Trình Của Bạn',
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
            // Bell Notification Button (Frosted glass circle)
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF091726).withValues(alpha: 0.45),
                    border: Border.all(
                      color: const Color(0xFFC59A44).withValues(alpha: 0.65),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFFF2C465),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // 2. Card: Main Quest Progress Overview
        _buildMainQuestCard(
          title: title,
          currentWeek: currentWeek,
          totalWeeks: totalWeeks,
          progress: campaignProgress,
          completionRate: completionRate,
        ),
        const SizedBox(height: 14),

        // 3. Row of 3 Mini Metric Badges
        _buildThreeMetricsRow(completionRate: completionRate),
        const SizedBox(height: 22),

        // 4. Section: CHIẾN DỊCH ĐANG THỰC HIỆN & STAGES STEPPER
        _buildCampaignStageCard(title: title, progress: campaignProgress),
        const SizedBox(height: 22),

        // 5. Section: CĂN CỐT & ĐẠO HẠNH ĐỜI THỰC (Skill Tree Attributes)
        _buildSkillTreeCard(),
        const SizedBox(height: 22),

        // 6. Section: BIỂU ĐỒ 7 NGÀY TU LUYỆN
        _buildWeeklyActivityCard(),
        const SizedBox(height: 22),

        // 7. Section: THIÊN ĐẠO TRÍ TUỆ (Weekly AI Intelligence)
        _buildWeeklyIntelligenceCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  // Card 1: Main Quest Progress Overview
  Widget _buildMainQuestCard({
    required String title,
    required int currentWeek,
    required int totalWeeks,
    required double progress,
    required int completionRate,
  }) {
    final int completedQuests = (completedCount + (campaignCurrentDay - 1) * 3).clamp(0, 999);
    final int totalPlannedQuests = campaignTotalDays * 3;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF091726).withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFC59A44).withValues(alpha: 0.65),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MAIN QUEST • TUẦN $currentWeek/$totalWeeks',
                style: const TextStyle(
                  color: Color(0xFFE8B95E),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFFFF6DF),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$completedQuests/$totalPlannedQuests nhiệm vụ chiến dịch đã hoàn thành',
                style: const TextStyle(
                  color: Color(0xFF8BA5BA),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 12),

              // Gold Progress Bar
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1624),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          width: constraints.maxWidth * progress,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE5B869), Color(0xFFF6CE70)],
                            ),
                            borderRadius: BorderRadius.circular(3),
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
            ],
          ),
        ),
      ),
    );
  }

  // Row of 3 Mini Metric Badges
  Widget _buildThreeMetricsRow({required int completionRate}) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFF59E0B),
            value: '$streakDays ngày',
            label: 'Độ kiên trì',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFF38BDF8),
            value: '+${_formatNumber(currentExp)}',
            label: 'Linh lực EXP',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF10B981),
            value: '$completionRate%',
            label: 'Tỉ lệ hoàn thành',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF091726).withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFC59A44).withValues(alpha: 0.55),
              width: 1.1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF8BA5BA),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card: CHIẾN DỊCH ĐANG THỰC HIỆN & 4 STAGES STEPPER
  Widget _buildCampaignStageCard({required String title, required double progress}) {
    final int stageIndex = (progress * 4).floor().clamp(0, 3);
    const stages = ['Khởi động', 'Nền tảng', 'Đột phá', 'Duy trì'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MAIN QUEST',
                  style: TextStyle(
                    color: Color(0xFFE8B95E),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chiến Dịch Đang Chơi',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFFFF6DF),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF091726).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFC59A44).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: const Text(
                'Giai đoạn hiện tại',
                style: TextStyle(
                  color: Color(0xFFF2C465),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF091726).withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFC59A44).withValues(alpha: 0.65),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF081626).withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFC59A44).withValues(alpha: 0.7),
                            width: 1.2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.fitness_center_rounded, color: Color(0xFFF2C465), size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Stage ${stageIndex + 1}/4 • ${stages[stageIndex]}',
                              style: const TextStyle(
                                color: Color(0xFF8BA5BA),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Color(0xFFF2C465),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C1624),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Container(
                              width: constraints.maxWidth * progress,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE5B869), Color(0xFFF6CE70)],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stepper 4 Labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(stages.length, (idx) {
                      final isCurrent = idx == stageIndex;
                      final isPassed = idx < stageIndex;
                      return Text(
                        stages[idx],
                        style: TextStyle(
                          color: isCurrent
                              ? const Color(0xFFF2C465)
                              : isPassed
                                  ? Colors.white70
                                  : const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w400,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Card: CĂN CỐT & ĐẠO HẠNH ĐỜI THỰC (Skill Tree Matrix)
  Widget _buildSkillTreeCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SKILL TREE',
                  style: TextStyle(
                    color: Color(0xFFE8B95E),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Năng Lực Đời Thực',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFFFF6DF),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Text(
              'Phân tích',
              style: TextStyle(
                color: Color(0xFFE8B95E),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF091726).withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFC59A44).withValues(alpha: 0.65),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  _buildSkillRow(
                    label: 'Thể chất',
                    percent: 0.82,
                    percentText: '82%',
                    gradientColors: [const Color(0xFFEA580C), const Color(0xFFFB923C)],
                  ),
                  const SizedBox(height: 14),
                  _buildSkillRow(
                    label: 'Trí thức',
                    percent: 0.64,
                    percentText: '64%',
                    gradientColors: [const Color(0xFFCA8A04), const Color(0xFFFDE047)],
                  ),
                  const SizedBox(height: 14),
                  _buildSkillRow(
                    label: 'Tập trung',
                    percent: 0.71,
                    percentText: '71%',
                    gradientColors: [const Color(0xFF0D9488), const Color(0xFF2DD4BF)],
                  ),
                  const SizedBox(height: 14),
                  _buildSkillRow(
                    label: 'Giao tiếp',
                    percent: 0.38,
                    percentText: '38%',
                    gradientColors: [const Color(0xFF7C3AED), const Color(0xFFA78BFA)],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillRow({
    required String label,
    required double percent,
    required String percentText,
    required List<Color> gradientColors,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFBAC7D5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFF0C1624),
              borderRadius: BorderRadius.circular(2.5),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      width: constraints.maxWidth * percent,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(2.5),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors.last.withValues(alpha: 0.4),
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
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 36,
          child: Text(
            percentText,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // Card: BIỂU ĐỒ 7 NGÀY TU LUYỆN
  Widget _buildWeeklyActivityCard() {
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    const questValues = [3, 2, 3, 3, 2, 3, 1]; // daily completed counts

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF091726).withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFC59A44).withValues(alpha: 0.65),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NHỊP ĐỘ TU LUYỆN 7 NGÀY',
                    style: TextStyle(
                      color: Color(0xFFE8B95E),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                  Text(
                    '${questValues.reduce((a, b) => a + b)}/21 nhiệm vụ',
                    style: const TextStyle(
                      color: Color(0xFF8BA5BA),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 7 Vertical Bars
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(days.length, (idx) {
                  final count = questValues[idx];
                  final double barHeight = (count / 3.0) * 54.0 + 10.0;
                  final isToday = idx == 6; // Sunday/Today

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$count',
                        style: TextStyle(
                          color: isToday ? const Color(0xFFF2C465) : const Color(0xFF7E98AE),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: 14,
                        height: barHeight,
                        decoration: BoxDecoration(
                          gradient: isToday
                              ? const LinearGradient(
                                  colors: [Color(0xFFE5B869), Color(0xFFF6CE70)],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                )
                              : LinearGradient(
                                  colors: [
                                    const Color(0xFF1E3A5F).withValues(alpha: 0.6),
                                    const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: isToday
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFF2C465).withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        days[idx],
                        style: TextStyle(
                          color: isToday ? const Color(0xFFF2C465) : const Color(0xFF8BA5BA),
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card: THIÊN ĐẠO TRÍ TUỆ (Weekly AI Intelligence)
  Widget _buildWeeklyIntelligenceCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF091726).withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFC59A44).withValues(alpha: 0.65),
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF281C10).withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.auto_awesome, color: Color(0xFFFBBF24), size: 20),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEEKLY INTELLIGENCE • THIÊN ĐẠO AI',
                      style: TextStyle(
                        color: Color(0xFFE8B95E),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Bạn làm quest tốt nhất lúc 6–8h sáng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Giao tiếp đang bị bỏ quên. EXP vẫn tăng đều, hãy bổ sung thêm các hành động kết nối để cân bằng ngũ hành căn cốt!',
                      style: TextStyle(
                        color: Color(0xFF8BA5BA),
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8BA5BA), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
