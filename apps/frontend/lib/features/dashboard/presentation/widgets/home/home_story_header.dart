import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../auth/domain/user_model.dart';
import '../../../data/cultivation_repository.dart';

class HomeStoryHeader extends StatelessWidget {
  final UserModel user;
  final CultivationProfileModel? cultivationProfile;
  final int streakDays;
  final VoidCallback onAvatarTap;

  const HomeStoryHeader({
    super.key,
    required this.user,
    required this.cultivationProfile,
    required this.streakDays,
    required this.onAvatarTap,
  });

  static String toRoman(int number) {
    const romanMap = {
      1: 'I',
      2: 'II',
      3: 'III',
      4: 'IV',
      5: 'V',
      6: 'VI',
      7: 'VII',
      8: 'VIII',
      9: 'IX',
      10: 'X',
    };
    return romanMap[number] ?? '$number';
  }

  String get chapterText {
    final realmIdx = cultivationProfile?.realmIndex ?? 0;
    final roman = toRoman(realmIdx + 1);
    if (streakDays == 0) {
      return 'CHƯƠNG $roman • KHỞI ĐẦU TU TIÊN';
    }
    return 'CHƯƠNG $roman • CHUỖI NGÀY: $streakDays';
  }

  String get storyTitle {
    final realmName = cultivationProfile?.realmName ?? 'Phàm Nhân';
    if (realmName == 'Phàm Nhân') {
      return 'Phàm Nhân Bắt Đầu\nTu Tiên';
    }
    return '$realmName Tầng ${cultivationProfile?.subRealm ?? 1}\nTu Tiên Lộ';
  }

  Widget _buildAvatarText() {
    final name = user.displayName.trim();
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Text(
      letter,
      style: const TextStyle(
        color: Color(0xFFF3C766),
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValidPhoto = user.photoUrl != null &&
        user.photoUrl!.isNotEmpty &&
        !user.photoUrl!.contains('unsplash');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chapterText,
                style: const TextStyle(
                  color: Color(0xFFE8B95E),
                  fontSize: 10.5,
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
                  storyTitle,
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
        ),
        GestureDetector(
          onTap: onAvatarTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF141F30),
              border: Border.all(
                color: const Color(0xFFE5B869),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE5B869).withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: hasValidPhoto
                  ? ClipOval(
                      child: Image.network(
                        user.photoUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildAvatarText(),
                      ),
                    )
                  : _buildAvatarText(),
            ),
          ),
        ),
      ],
    );
  }
}
