import 'dart:ui';
import 'package:flutter/material.dart';

class WeeklyIntelligenceCard extends StatelessWidget {
  final VoidCallback? onTap;

  const WeeklyIntelligenceCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
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
      ),
    );
  }
}
