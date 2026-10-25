import 'dart:ui';
import 'package:flutter/material.dart';

class AccountSettingsCard extends StatelessWidget {
  final int spiritStones;
  final VoidCallback onSignOut;
  final VoidCallback? onRewardStoreTap;
  final VoidCallback? onPrivacyTap;

  const AccountSettingsCard({
    super.key,
    required this.spiritStones,
    required this.onSignOut,
    this.onRewardStoreTap,
    this.onPrivacyTap,
  });

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withValues(alpha: 0.4), width: 1),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? const Color(0xFFF87171) : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8BA5BA),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF5A758D), size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        const Text(
          'TÀI KHOẢN',
          style: TextStyle(
            color: Color(0xFFE8B95E),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 10),

        // Glass Card
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF091726).withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFC59A44).withValues(alpha: 0.65),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  _buildTile(
                    icon: Icons.token_rounded,
                    iconColor: const Color(0xFFF2C465),
                    title: 'Phù Lục Các',
                    subtitle: 'Bách bảo phường · ${_formatNumber(spiritStones)} Nguyên Thạch',
                    onTap: onRewardStoreTap ?? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Phù Lục Các • Đang cập nhật thêm vật phẩm tu tiên!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    height: 1,
                    color: const Color(0xFF1E2F40),
                  ),
                  _buildTile(
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFF38BDF8),
                    title: 'Quyền riêng tư & Bảo mật',
                    subtitle: 'Bảo mật đồng bộ dữ liệu đám mây',
                    onTap: onPrivacyTap ?? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dữ liệu tu luyện được mã hóa an toàn qua Firebase & Supabase!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    height: 1,
                    color: const Color(0xFF1E2F40),
                  ),
                  _buildTile(
                    icon: Icons.logout_rounded,
                    iconColor: const Color(0xFFF87171),
                    title: 'Đăng xuất tài khoản',
                    subtitle: 'Lưu tiến trình và thoát phiên làm việc',
                    isDestructive: true,
                    onTap: onSignOut,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
