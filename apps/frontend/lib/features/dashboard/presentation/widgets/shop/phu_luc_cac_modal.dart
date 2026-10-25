import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../data/shop_repository.dart';
import '../../../domain/shop_item_model.dart';
import 'shop_category_chips.dart';
import 'shop_inventory_view.dart';
import 'shop_item_card.dart';
import 'shop_purchase_dialog.dart';

class PhuLucCacModal extends StatefulWidget {
  final int initialSpiritStones;
  final ValueChanged<int>? onBalanceUpdated;

  const PhuLucCacModal({
    super.key,
    required this.initialSpiritStones,
    this.onBalanceUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required int spiritStones,
    ValueChanged<int>? onBalanceUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PhuLucCacModal(
        initialSpiritStones: spiritStones,
        onBalanceUpdated: onBalanceUpdated,
      ),
    );
  }

  @override
  State<PhuLucCacModal> createState() => _PhuLucCacModalState();
}

class _PhuLucCacModalState extends State<PhuLucCacModal> with SingleTickerProviderStateMixin {
  final ShopRepository _shopRepository = ShopRepository();

  late int _spiritStones;
  late TabController _tabController;

  String _selectedCategory = 'all';
  List<ShopItemModel> _items = defaultShopItemsList;
  List<UserInventoryItemModel> _inventory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _spiritStones = widget.initialSpiritStones;
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final items = await _shopRepository.getShopItems();
      final inventory = await _shopRepository.getInventory();
      if (mounted) {
        setState(() {
          _items = items;
          _inventory = inventory;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<ShopItemModel> get _filteredItems {
    if (_selectedCategory == 'all') return _items;
    return _items.where((item) => item.category == _selectedCategory).toList();
  }

  void _onPurchaseItem(ShopItemModel item) {
    ShopPurchaseDialog.show(
      context,
      item: item,
      userSpiritStones: _spiritStones,
      onConfirm: (quantity) async {
        try {
          final res = await _shopRepository.purchaseItem(item.id, quantity: quantity);
          final int remaining = (res['remainingSpiritStones'] as num?)?.toInt() ??
              (_spiritStones - item.price * quantity);

          setState(() {
            _spiritStones = remaining;
          });
          widget.onBalanceUpdated?.call(remaining);

          // Tải lại inventory
          final inv = await _shopRepository.getInventory();
          if (mounted) {
            setState(() {
              _inventory = inv;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF064E3B),
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🎉 Chúc mừng đạo hữu đã đổi thành công ${quantity}x ${item.name}!',
                        style: const TextStyle(
                          color: Color(0xFFFDE68A),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        } catch (e) {
          final cleanMsg = e.toString().replaceAll('Exception: ', '').trim();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF7F1D1D),
                content: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFFCA5A5), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cleanMsg,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
          rethrow;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.88,
      decoration: BoxDecoration(
        color: const Color(0xFF07121E).withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: const Color(0xFFC59A44), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Drag Indicator
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF5A758D),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              // Header Row: Title + Balance Badge + Close Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    // Pavilion Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E2235),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFC59A44).withValues(alpha: 0.7),
                          width: 1.2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.token_rounded,
                          color: Color(0xFFF2C465),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Subtitle
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PHÙ LỤC CÁC',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Bách Bảo Phường · Bí cảnh đổi vật phẩm',
                            style: TextStyle(
                              color: Color(0xFF8BA5BA),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Balance Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF081C2D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.diamond_rounded, color: Color(0xFF38BDF8), size: 15),
                          const SizedBox(width: 4),
                          Text(
                            '$_spiritStones',
                            style: const TextStyle(
                              color: Color(0xFFFDE68A),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Close Button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Tab Bar: Cửa Hàng vs Túi Càn Khôn
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF061424).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1E3A52),
                    width: 1.0,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFFC59A44).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFF2C465),
                      width: 1.2,
                    ),
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: const Color(0xFFFDE68A),
                  unselectedLabelColor: const Color(0xFF8BA5BA),
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  tabs: [
                    const Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Cửa Hàng'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text('Túi Càn Khôn (${_inventory.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Cửa Hàng
                    _buildShopTab(),

                    // Tab 2: Túi Càn Khôn
                    ShopInventoryView(
                      inventory: _inventory,
                      onGoToShop: () {
                        _tabController.animateTo(0);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFF2C465),
          strokeWidth: 2.5,
        ),
      );
    }

    final filtered = _filteredItems;

    return Column(
      children: [
        // Category Chips
        ShopCategoryChips(
          selectedCategory: _selectedCategory,
          onSelected: (cat) => setState(() => _selectedCategory = cat),
        ),
        const SizedBox(height: 12),

        // Items Grid
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có vật phẩm trong danh mục này',
                    style: TextStyle(color: Color(0xFF8BA5BA), fontSize: 13),
                  ),
                )
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return ShopItemCard(
                      item: item,
                      userSpiritStones: _spiritStones,
                      onPurchaseTap: () => _onPurchaseItem(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
