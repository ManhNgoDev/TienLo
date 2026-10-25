import 'package:flutter/material.dart';
import '../../data/cultivation_repository.dart';
import 'statistics/campaign_stage_card.dart';
import 'statistics/main_quest_progress_card.dart';
import 'statistics/quick_metrics_row.dart';
import 'statistics/real_life_skill_tree_card.dart';
import 'statistics/statistics_header.dart';
import 'statistics/weekly_activity_chart_card.dart';
import 'statistics/weekly_intelligence_card.dart';

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
  final Map<String, dynamic>? statisticsData;
  final bool isLoading;
  final VoidCallback? onRefresh;

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
    this.statisticsData,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final title = (statisticsData?['activeCampaignTitle'] != null &&
            (statisticsData!['activeCampaignTitle'] as String).isNotEmpty)
        ? statisticsData!['activeCampaignTitle'] as String
        : ((activeCampaignTitle != null && activeCampaignTitle!.isNotEmpty)
            ? activeCampaignTitle!
            : 'Kiến Tạo Phiên Bản 2.0');

    final int calculatedWeek = ((campaignCurrentDay - 1) ~/ 7) + 1;
    final int currentWeek = (statisticsData?['currentWeek'] as num?)?.toInt() ?? calculatedWeek;

    final int calculatedTotalWeeks = (campaignTotalDays / 7).ceil().clamp(1, 52);
    final int totalWeeks = (statisticsData?['totalWeeks'] as num?)?.toInt() ?? calculatedTotalWeeks;

    final double campaignProgress = (campaignCurrentDay / campaignTotalDays).clamp(0.0, 1.0);

    final int calculatedRate = totalQuestsCount > 0
        ? ((completedCount / totalQuestsCount) * 100).toInt()
        : 0;
    final int completionRate = (statisticsData?['completionRate'] as num?)?.toInt() ?? calculatedRate;

    final int calculatedCompletedQuests = completedCount;
    final int completedQuests = (statisticsData?['completedQuests'] as num?)?.toInt() ?? calculatedCompletedQuests;

    final int totalPlannedQuests = (statisticsData?['totalPlannedQuests'] as num?)?.toInt() ?? (campaignTotalDays * 3);

    final attributes = statisticsData?['attributes'] as Map<String, dynamic>?;
    final aiIntelligence = statisticsData?['aiIntelligence'] as Map<String, dynamic>?;
    final weeklyActivity = (statisticsData?['weeklyActivity'] as List?)
        ?.map((e) => (e as num).toInt())
        .toList();

    // Khởi tạo thuộc tính và nhịp độ từ dữ liệu thực tế nếu đang chờ API phản hồi
    final realmBonus = (profile?.realmIndex ?? 0) * 5;
    final streakBonus = streakDays * 3;
    final resolvedAttributes = attributes ?? {
      'physical': (10 + realmBonus + completedCount * 8).clamp(10, 99),
      'intellect': (10 + realmBonus).clamp(10, 99),
      'focus': (10 + realmBonus + streakBonus).clamp(10, 99),
      'social': (10 + realmBonus + completedCount * 2).clamp(10, 99),
    };

    final resolvedWeeklyActivity = weeklyActivity ??
        List.generate(7, (index) {
          final todayIndex = (DateTime.now().weekday - 1); // 0 = T2, ..., 6 = CN
          if (index == todayIndex) return completedCount.clamp(0, 3);
          return 0;
        });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Header with optional refresh indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: StatisticsHeader()),
            if (isLoading)
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 20,
                height: 20,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE5B869)),
                ),
              )
            else if (onRefresh != null)
              IconButton(
                padding: const EdgeInsets.only(top: 12),
                icon: const Icon(Icons.refresh, color: Color(0xFFE5B869), size: 20),
                onPressed: onRefresh,
                tooltip: 'Làm mới thống kê AI',
              ),
          ],
        ),
        const SizedBox(height: 22),

        // 2. Main Quest Progress Overview
        MainQuestProgressCard(
          title: title,
          currentWeek: currentWeek,
          totalWeeks: totalWeeks,
          progress: campaignProgress,
          completedQuests: completedQuests,
          totalPlannedQuests: totalPlannedQuests,
        ),
        const SizedBox(height: 14),

        // 3. Quick Metrics Row (Streak, Exp, Completion Rate)
        QuickMetricsRow(
          streakDays: streakDays,
          currentExp: currentExp,
          completionRate: completionRate,
        ),
        const SizedBox(height: 22),

        // 4. Campaign Stage Stepper Card
        CampaignStageCard(
          title: title,
          progress: campaignProgress,
        ),
        const SizedBox(height: 22),

        // 5. Real Life Skill Tree Attributes (Năng Lực Đời Thực AI)
        RealLifeSkillTreeCard(
          attributes: resolvedAttributes,
        ),
        const SizedBox(height: 22),

        // 6. 7-Day Activity Chart
        WeeklyActivityChartCard(
          weeklyActivity: resolvedWeeklyActivity,
        ),
        const SizedBox(height: 22),

        // 7. Weekly AI Intelligence Card (Thiên Đạo AI)
        WeeklyIntelligenceCard(
          aiIntelligence: aiIntelligence,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
