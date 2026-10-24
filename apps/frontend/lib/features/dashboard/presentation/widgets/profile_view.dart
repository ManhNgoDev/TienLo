import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/domain/user_model.dart';
import '../../data/cultivation_repository.dart';
import 'cultivation_realms_modal.dart';
import 'profile/account_settings_card.dart';
import 'profile/cultivation_progress_card.dart';
import 'profile/profile_header_card.dart';

class ProfileView extends StatefulWidget {
  final UserModel user;
  final CultivationProfileModel? cultivationProfile;
  final VoidCallback onSignOut;

  const ProfileView({
    super.key,
    required this.user,
    required this.cultivationProfile,
    required this.onSignOut,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final CultivationRepository _cultivationRepository = CultivationRepository();

  Map<String, dynamic>? _apiProfileData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await _cultivationRepository.getFullUserProfile();
      if (mounted && data != null) {
        setState(() {
          _apiProfileData = data;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showEditProfileDialog(String currentName, String currentUsername) {
    final nameCtrl = TextEditingController(text: currentName);
    final userCtrl = TextEditingController(text: currentUsername.replaceAll('@', ''));

    showDialog(
      context: context,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AlertDialog(
            backgroundColor: const Color(0xFF091726),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFC59A44), width: 1.2),
            ),
            title: Text(
              'Chỉnh Sửa Hồ Sơ',
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFFFF6DF),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Tên hiển thị',
                    labelStyle: TextStyle(color: Color(0xFF8BA5BA)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF38BDF8))),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: userCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixText: '@',
                    labelStyle: TextStyle(color: Color(0xFF8BA5BA)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF38BDF8))),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: Color(0xFF8BA5BA))),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = nameCtrl.text.trim();
                  final newUser = userCtrl.text.trim();
                  Navigator.pop(ctx);
                  if (newName.isNotEmpty) {
                    await _cultivationRepository.updateUserProfile(
                      displayName: newName,
                      username: newUser,
                    );
                    _loadProfileData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A5F),
                  foregroundColor: const Color(0xFFFBBF24),
                ),
                child: const Text('Lưu'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF091726).withValues(alpha: 0.98),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              border: Border.all(color: const Color(0xFFC59A44), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A758D),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Cài Đặt Hệ Thống',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFFFF6DF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: const Color(0xFFF2C465),
                  title: const Text('Hiệu ứng âm thanh tu tiên', style: TextStyle(color: Colors.white, fontSize: 13.5)),
                  value: true,
                  onChanged: (val) {},
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: const Color(0xFFF2C465),
                  title: const Text('Thông báo nhắc nhở rèn luyện', style: TextStyle(color: Colors.white, fontSize: 13.5)),
                  value: true,
                  onChanged: (val) {},
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8BA5BA),
                      side: const BorderSide(color: Color(0xFF38BDF8)),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = _apiProfileData?['user'] as Map<String, dynamic>?;
    final statsData = _apiProfileData?['stats'] as Map<String, dynamic>?;
    final progressData = _apiProfileData?['cultivationProgress'] as Map<String, dynamic>?;

    final displayName = userData?['displayName']?.toString() ??
        (widget.user.displayName.isNotEmpty ? widget.user.displayName : 'Đạo Hữu Tiên Lộ');
    final emailPrefix = widget.user.email.isNotEmpty && widget.user.email.contains('@')
        ? widget.user.email.split('@')[0]
        : 'daohuu';
    final username = userData?['username']?.toString() ?? '@${emailPrefix.toLowerCase()}';
    final joinedDate = userData?['joinedDate']?.toString() ?? 'Người chơi từ 10/2026';

    final streakDays = (statsData?['streakDays'] as num?)?.toInt() ??
        widget.cultivationProfile?.streakDays ??
        1;
    final completedQuests = (statsData?['completedQuests'] as num?)?.toInt() ?? 3;
    final totalExp = (statsData?['totalExp'] as num?)?.toInt() ??
        widget.cultivationProfile?.totalExp ??
        widget.cultivationProfile?.currentExp ??
        300;

    final spiritStones = (statsData?['spiritStones'] as num?)?.toInt() ??
        widget.cultivationProfile?.spiritStones ??
        90;

    final nextTitle = progressData?['nextTitle']?.toString() ??
        (widget.cultivationProfile?.realmIndex == 0
            ? 'Luyện Khí Tầng 1 • Tiên Lộ Tu Sĩ'
            : (widget.cultivationProfile?.subRealm != null && widget.cultivationProfile!.subRealm >= 10
                ? 'Đột Phá Cảnh Giới Kế Tiếp'
                : '${widget.cultivationProfile?.realmName} Tầng ${(widget.cultivationProfile?.subRealm ?? 1) + 1}'));
    final currentExp = (progressData?['currentExp'] as num?)?.toInt() ??
        widget.cultivationProfile?.currentExp ??
        300;
    final maxExp = (progressData?['maxExp'] as num?)?.toInt() ??
        widget.cultivationProfile?.maxExp ??
        1000;
    final expNeeded = (progressData?['expNeeded'] as num?)?.toInt() ??
        (maxExp - currentExp).clamp(0, 9999999999999);
    final progressPercent = (progressData?['progressPercent'] as num?)?.toInt() ??
        (maxExp > 0 ? ((currentExp / maxExp) * 100).toInt() : 30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Bar: HỒ SƠ TU LUYỆN / CÁ NHÂN & Settings button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HỒ SƠ TU LUYỆN',
                  style: TextStyle(
                    color: Color(0xFFE8B95E),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'CÁ NHÂN',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFFFF6DF),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (_isLoading)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 18,
                    height: 18,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE5B869)),
                    ),
                  ),
                GestureDetector(
                  onTap: _showSettingsModal,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF091726).withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFC59A44).withValues(alpha: 0.65),
                        width: 1.2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.settings_outlined,
                        color: Color(0xFFFFF6DF),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 2. Main Profile Card (No rank)
        ProfileHeaderCard(
          displayName: displayName,
          username: username,
          avatarUrl: widget.user.photoUrl,
          joinedDate: joinedDate,
          streakDays: streakDays,
          completedQuests: completedQuests,
          totalExp: totalExp,
          onEditProfile: () => _showEditProfileDialog(displayName, username),
        ),
        const SizedBox(height: 20),

        // 3. Section: TIẾN ĐỘ TU LUYỆN (Click to open Realms modal)
        CultivationProgressCard(
          nextTitle: nextTitle,
          currentExp: currentExp,
          maxExp: maxExp,
          expNeeded: expNeeded,
          progressPercent: progressPercent,
          onTap: () {
            if (widget.cultivationProfile != null) {
              CultivationRealmsModal.show(context, widget.cultivationProfile!);
            }
          },
        ),
        const SizedBox(height: 20),

        // 4. Section: TÀI KHOẢN (Only Nguyên Thạch)
        AccountSettingsCard(
          spiritStones: spiritStones,
          onSignOut: widget.onSignOut,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
