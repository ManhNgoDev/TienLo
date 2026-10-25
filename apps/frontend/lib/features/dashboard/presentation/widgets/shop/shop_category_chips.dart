import 'package:flutter/material.dart';

class ShopCategoryChips extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const ShopCategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  static const List<Map<String, String>> categories = [
    {'id': 'all', 'label': 'Tất Cả'},
    {'id': 'talisman', 'label': 'Phù Lục'},
    {'id': 'pill', 'label': 'Đan Dược'},
    {'id': 'treasure', 'label': 'Pháp Bảo'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(cat['id']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFC59A44).withValues(alpha: 0.25)
                      : const Color(0xFF0D1E30).withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFF2C465)
                        : const Color(0xFF1E3A52),
                    width: isSelected ? 1.4 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFF2C465).withValues(alpha: 0.20),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  cat['label']!,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFFDE68A) : const Color(0xFF8BA5BA),
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
