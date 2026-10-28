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
    // Kiểm tra xem người dùng có chiến dịch / session nào đang hoạt động không
    final rawStatsTitle = statisticsData?['activeCampaignTitle'] as String?;
    final bool isStatsTitleValid = rawStatsTitle != null &&
        rawStatsTitle.trim().isNotEmpty &&
        rawStatsTitle.trim() != '[HỆ THỐNG] Tôi Luyện Thể Chất & Đột Phá Giới Hạn';

    final bool isPropTitleValid = activeCampaignTitle != null &&
        activeCampaignTitle!.trim().isNotEmpty &&
        activeCampaignTitle!.trim() != '[HỆ THỐNG] Tôi Luyện Thể Chất & Đột Phá Giới Hạn';

    final bool hasActiveCamp = (statisticsData?['hasActiveCampaign'] == true) ||
        isPropTitleValid ||
        isStatsTitleValid;

    final String title = hasActiveCamp
        ? (isPropTitleValid
            ? activeCampaignTitle!.trim()
            : (isStatsTitleValid ? rawStatsTitle.trim() : 'Chiến Dịch Tu Luyện'))
        : 'Chưa có chiến dịch nào';

    final int resolvedCurrentDay = hasActiveCamp
        ? ((statisticsData?['campaignCurrentDay'] as num?)?.toInt() ??
            (campaignCurrentDay > 0 ? campaignCurrentDay : 1))
        : 0;

    final int resolvedTotalDays = hasActiveCamp
        ? ((statisticsData?['campaignTotalDays'] as num?)?.toInt() ??
            (campaignTotalDays > 0 ? campaignTotalDays : 14))
        : 0;

    final int calculatedWeek = hasActiveCamp
        ? (resolvedCurrentDay > 0 ? (((resolvedCurrentDay - 1) ~/ 7) + 1) : 1)
        : 0;
    final int currentWeek = hasActiveCamp
        ? ((statisticsData?['currentWeek'] as num?)?.toInt() ?? calculatedWeek)
        : 0;

    final int calculatedTotalWeeks = hasActiveCamp
        ? (resolvedTotalDays / 7).ceil().clamp(1, 52)
        : 0;
    final int totalWeeks = hasActiveCamp
        ? ((statisticsData?['totalWeeks'] as num?)?.toInt() ?? calculatedTotalWeeks)
        : 0;

    final int calculatedCompletedQuests = hasActiveCamp ? completedCount : 0;
    final int completedQuests = hasActiveCamp
        ? ((statisticsData?['completedQuests'] as num?)?.toInt() ?? calculatedCompletedQuests)
        : 0;

    final int totalPlannedQuests = hasActiveCamp
        ? ((statisticsData?['totalPlannedQuests'] as num?)?.toInt() ??
            (resolvedTotalDays * (totalQuestsCount > 0 ? totalQuestsCount : 5)))
        : 0;

    // Tiến độ được tính dựa trên số nhiệm vụ thực tế đã hoàn thành, tuyệt đối không mặc định 7% khi chưa làm gì
    final double calculatedProgress = (hasActiveCamp && totalPlannedQuests > 0 && completedQuests > 0)
        ? (completedQuests / totalPlannedQuests).clamp(0.0, 1.0)
        : 0.0;
    final double campaignProgress = hasActiveCamp
        ? ((statisticsData?['campaignProgress'] as num?)?.toDouble() ?? calculatedProgress)
        : 0.0;

    final int calculatedRate = totalQuestsCount > 0
        ? ((completedCount / totalQuestsCount) * 100).toInt()
        : 0;
    final int completionRate = (statisticsData?['completionRate'] as num?)?.toInt() ?? calculatedRate;

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
          hasActiveCampaign: hasActiveCamp,
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
          hasActiveCampaign: hasActiveCamp,
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
