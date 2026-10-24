import 'package:flutter/material.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

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

  @override
  Widget build(BuildContext context) {
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
}
