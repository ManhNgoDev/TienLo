import 'dart:ui';
import 'package:flutter/material.dart';

class WeeklyActivityChartCard extends StatelessWidget {
  final List<int>? weeklyActivity;

  const WeeklyActivityChartCard({
    super.key,
    this.weeklyActivity,
  });

  @override
  Widget build(BuildContext context) {
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final List<int> questValues = (weeklyActivity != null && weeklyActivity!.length == 7)
        ? weeklyActivity!
        : [3, 2, 3, 3, 2, 3, 1];

    final totalCompleted = questValues.fold<int>(0, (a, b) => a + b);

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
                    '$totalCompleted/21 nhiệm vụ',
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
}
