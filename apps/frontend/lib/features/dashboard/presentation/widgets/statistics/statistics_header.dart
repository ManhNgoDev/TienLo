import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatisticsHeader extends StatelessWidget {
  final VoidCallback? onNotificationTap;

  const StatisticsHeader({super.key, this.onNotificationTap});

  @override
  Widget build(BuildContext context) {
    return Row(
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
        GestureDetector(
          onTap: onNotificationTap,
          child: ClipRRect(
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
        ),
      ],
    );
  }
}
