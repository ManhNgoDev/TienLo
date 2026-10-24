import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileHeaderCard extends StatelessWidget {
  final String displayName;
  final String username;
  final String? avatarUrl;
  final String joinedDate;
  final int streakDays;
  final int completedQuests;
  final int totalExp;
  final VoidCallback? onEditProfile;

  const ProfileHeaderCard({
    super.key,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    required this.joinedDate,
    required this.streakDays,
    required this.completedQuests,
    required this.totalExp,
    this.onEditProfile,
  });

  String _formatNumber(int value) {
    if (value >= 1000000000000000) {
      final v = value / 1000000000000000;
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)} Tr.Tỷ';
    }
    if (value >= 1000000000000) {
      final v = value / 1000000000000;
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)} Ngàn Tỷ';
    }
    if (value >= 1000000000) {
      final v = value / 1000000000;
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)} Tỷ';
    }
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Widget _buildStatCol(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFFFF6DF),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8BA5BA),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
          decoration: BoxDecoration(
            color: const Color(0xFF091726).withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFC59A44).withValues(alpha: 0.65),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Avatar with edit badge
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF142436),
                        border: Border.all(
                          color: const Color(0xFFE5B869),
                          width: 2.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE5B869).withValues(alpha: 0.35),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Center(
                        child: avatarUrl != null && avatarUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  avatarUrl!,
                                  width: 82,
                                  height: 82,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildAvatarText(initial),
                                ),
                              )
                            : _buildAvatarText(initial),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: onEditProfile,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C1929),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF2DD4BF),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Color(0xFF2DD4BF),
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Display Name
              Text(
                displayName,
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFFFF6DF),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 3),

              // 3. Username & joined date
              Text(
                '$username • $joinedDate',
                style: const TextStyle(
                  color: Color(0xFF8BA5BA),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),

              // 5. 3-column stats bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF071322).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    _buildStatCol('$streakDays', 'Chuỗi ngày'),
                    Container(width: 1, height: 26, color: const Color(0xFF1E2F40)),
                    _buildStatCol('$completedQuests', 'Nhiệm vụ'),
                    Container(width: 1, height: 26, color: const Color(0xFF1E2F40)),
                    _buildStatCol(_formatNumber(totalExp), 'Tổng Linh Lực'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarText(String initial) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF8B5E2B), Color(0xFFCA8A04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFFFF6DF),
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
