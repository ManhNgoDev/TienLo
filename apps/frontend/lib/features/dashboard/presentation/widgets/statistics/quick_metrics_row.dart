import 'dart:ui';
import 'package:flutter/material.dart';

class QuickMetricsRow extends StatelessWidget {
  final int streakDays;
  final int currentExp;
  final int completionRate;

  const QuickMetricsRow({
    super.key,
    required this.streakDays,
    required this.currentExp,
    required this.completionRate,
  });

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
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

  @override
  Widget build(BuildContext context) {
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
}
