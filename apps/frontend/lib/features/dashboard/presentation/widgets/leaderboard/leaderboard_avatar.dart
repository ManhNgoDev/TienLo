import 'package:flutter/material.dart';
import '../../../domain/leaderboard_item.dart';
import 'leaderboard_constants.dart';

class LeaderboardAvatar extends StatelessWidget {
  final LeaderboardItem item;
  final double size;

  const LeaderboardAvatar({
    super.key,
    required this.item,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValidUrl = item.avatarUrl != null &&
        item.avatarUrl!.isNotEmpty &&
        !item.avatarUrl!.contains('unsplash');

    final String initial = item.displayName.isNotEmpty
        ? item.displayName.trim()[0].toUpperCase()
        : 'Đ';

    Color borderColor;
    if (item.rank == 1) {
      borderColor = const Color(0xFFFFD700);
    } else if (item.rank == 2) {
      borderColor = const Color(0xFFE2E8F0);
    } else if (item.rank == 3) {
      borderColor = const Color(0xFFCD7F32);
    } else {
      borderColor = getRealmColor(item.realmIndex).withValues(alpha: 0.65);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: item.rank <= 3 ? 2.0 : 1.4),
        boxShadow: item.rank <= 3
            ? [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: hasValidUrl
            ? Image.network(
                item.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallbackInitial(initial, size),
              )
            : _buildFallbackInitial(initial, size),
      ),
    );
  }

  static Widget _buildFallbackInitial(String initial, double size) {
    return Container(
      color: const Color(0xFF1A2A3D),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: const Color(0xFFF3C766),
          fontWeight: FontWeight.bold,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}
