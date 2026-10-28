import 'dart:ui';
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback? onSparkleTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    this.onSparkleTap,
  });

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onIndexChanged(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? const Color(0xFFF3C766) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFF3C766) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLeaderboardSelected = currentIndex == 2;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(
        14,
        0,
        14,
        bottomInset > 0 ? (bottomInset + 8) : 14,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF091726).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: const Color(0xFFC59A44).withValues(alpha: 0.60),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(index: 0, icon: Icons.home_rounded, label: 'Hôm nay'),
                _buildNavItem(index: 1, icon: Icons.insights_rounded, label: 'Thống kê'),

                // Center Floating Leaderboard Button (Bảng Xếp Hạng Leo Top)
                GestureDetector(
                  onTap: () {
                    onIndexChanged(2);
                    onSparkleTap?.call();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isLeaderboardSelected
                                ? [const Color(0xFFFFFBEB), const Color(0xFFF59E0B)]
                                : [const Color(0xFFFDE68A), const Color(0xFFD97706)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: isLeaderboardSelected
                              ? Border.all(color: Colors.white, width: 2.0)
                              : Border.all(
                                  color: const Color(0xFFFDE68A).withValues(alpha: 0.7),
                                  width: 1.2,
                                ),
                          boxShadow: [
                            BoxShadow(
                              color: isLeaderboardSelected
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.85)
                                  : const Color(0xFFD97706).withValues(alpha: 0.45),
                              blurRadius: isLeaderboardSelected ? 16 : 10,
                              spreadRadius: isLeaderboardSelected ? 2 : 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.emoji_events_rounded,
                          color: isLeaderboardSelected
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF1E1B4B),
                          size: 23,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Xếp hạng',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: isLeaderboardSelected
                              ? FontWeight.w900
                              : FontWeight.w600,
                          color: isLeaderboardSelected
                              ? const Color(0xFFF3C766)
                              : const Color(0xFFE5B869),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildNavItem(index: 3, icon: Icons.bolt_rounded, label: 'Nhân vật'),
                _buildNavItem(index: 4, icon: Icons.person_outline_rounded, label: 'Cá nhân'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
