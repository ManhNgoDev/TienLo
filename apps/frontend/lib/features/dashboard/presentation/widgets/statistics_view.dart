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

    final int completedQuests = (completedCount + (campaignCurrentDay - 1) * 3).clamp(0, 999);
    final int totalPlannedQuests = campaignTotalDays * 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Header
        const StatisticsHeader(),
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

        // 5. Real Life Skill Tree Attributes
        const RealLifeSkillTreeCard(),
        const SizedBox(height: 22),

        // 6. 7-Day Activity Chart
        const WeeklyActivityChartCard(),
        const SizedBox(height: 22),

        // 7. Weekly AI Intelligence Card
        const WeeklyIntelligenceCard(),
        const SizedBox(height: 20),
      ],
    );
  }
}
