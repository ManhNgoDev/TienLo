import 'package:flutter/material.dart';

class LeaderboardSortBar extends StatelessWidget {
  final String selectedSort;
  final ValueChanged<String> onSortChanged;

  const LeaderboardSortBar({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  Widget _buildChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = selectedSort == value;
    return GestureDetector(
      onTap: () => onSortChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF3C766).withValues(alpha: 0.22)
              : const Color(0xFF132235).withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF3C766)
                : const Color(0xFF2A3D54),
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF3C766).withValues(alpha: 0.25),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? const Color(0xFFF3C766)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFFFDE68A)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(
            label: 'Tổng Hợp (Quy Tắc)',
            value: 'default',
            icon: Icons.auto_awesome_rounded,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Chuỗi Ngày',
            value: 'streak',
            icon: Icons.local_fire_department_rounded,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Nhiệm Vụ',
            value: 'quests',
            icon: Icons.task_alt_rounded,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Cảnh Giới',
            value: 'realm',
            icon: Icons.bolt_rounded,
          ),
        ],
      ),
    );
  }
}
