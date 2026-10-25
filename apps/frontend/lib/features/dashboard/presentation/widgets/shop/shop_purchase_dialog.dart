import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../domain/shop_item_model.dart';

class ShopPurchaseDialog extends StatefulWidget {
  final ShopItemModel item;
  final int userSpiritStones;
  final Future<void> Function(int quantity) onConfirm;

  const ShopPurchaseDialog({
    super.key,
    required this.item,
    required this.userSpiritStones,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required ShopItemModel item,
    required int userSpiritStones,
    required Future<void> Function(int quantity) onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => ShopPurchaseDialog(
        item: item,
        userSpiritStones: userSpiritStones,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<ShopPurchaseDialog> createState() => _ShopPurchaseDialogState();
}

class _ShopPurchaseDialogState extends State<ShopPurchaseDialog> {
  int _quantity = 1;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final int totalCost = widget.item.price * _quantity;
    final bool canAfford = widget.userSpiritStones >= totalCost;
    final int remaining = widget.userSpiritStones - totalCost;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF091726).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFC59A44).withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC59A44).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFF2C465).withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: const Text(
                      'BÁCH BẢO PHƯỜNG · GIAO DỊCH',
                      style: TextStyle(
                        color: Color(0xFFFDE68A),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Item Icon & Name
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1D2E),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: widget.item.rarityColor,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.item.rarityColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    widget.item.iconData,
                    color: widget.item.iconColor,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                widget.item.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),

              Text(
                widget.item.effect,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              // Quantity Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF061424).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF1E3A52),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Số lượng đổi:',
                      style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        _buildQtyBtn(
                          icon: Icons.remove,
                          enabled: _quantity > 1,
                          onTap: () {
                            if (_quantity > 1) {
                              setState(() => _quantity -= 1);
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _buildQtyBtn(
                          icon: Icons.add,
                          enabled: (widget.item.price * (_quantity + 1)) <= widget.userSpiritStones,
                          onTap: () {
                            setState(() => _quantity += 1);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Price & Balance Summary Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: canAfford
                      ? const Color(0xFF0A221C).withValues(alpha: 0.5)
                      : const Color(0xFF281116).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: canAfford ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    width: 0.9,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng Nguyên Thạch cần:',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.diamond_rounded, color: Color(0xFF38BDF8), size: 15),
                            const SizedBox(width: 4),
                            Text(
                              '$totalCost NT',
                              style: const TextStyle(
                                color: Color(0xFFFDE68A),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Số dư hiện có:',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                        ),
                        Text(
                          '${widget.userSpiritStones} NT',
                          style: TextStyle(
                            color: canAfford ? const Color(0xFF34D399) : const Color(0xFFF87171),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (canAfford) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Số dư sau đổi:',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                          ),
                          Text(
                            '$remaining NT',
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 6),
                      Text(
                        'Đạo hữu còn thiếu ${totalCost - widget.userSpiritStones} Nguyên Thạch!',
                        style: const TextStyle(
                          color: Color(0xFFFCA5A5),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF334155)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Hủy Bỏ',
                        style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (!canAfford || _isSubmitting)
                          ? null
                          : () async {
                              setState(() => _isSubmitting = true);
                              try {
                                await widget.onConfirm(_quantity);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (_) {
                                if (mounted) {
                                  setState(() => _isSubmitting = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC59A44),
                        disabledBackgroundColor: const Color(0xFF334155),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Xác Nhận Đổi',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQtyBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFFC59A44).withValues(alpha: 0.25)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? const Color(0xFFF2C465) : const Color(0xFF334155),
            width: 0.9,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 16,
            color: enabled ? const Color(0xFFFDE68A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
