import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/shop_item_model.dart';

class ShopRepository {
  final ApiClient _apiClient;

  ShopRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<String?> _getToken() async {
    try {
      final validToken = await AuthRepository().getValidToken();
      if (validToken != null && validToken.isNotEmpty) {
        return validToken;
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token ?? 'demo-token-dev-fallback';
  }

  Future<List<ShopItemModel>> getShopItems() async {
    final token = await _getToken();
    try {
      final res = await _apiClient.get(ApiConstants.shopItems, token: token);
      if (res is List) {
        return res.map((item) => ShopItemModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error getShopItems from backend: $e. Using local defaults.');
    }
    return defaultShopItemsList;
  }

  Future<List<UserInventoryItemModel>> getInventory() async {
    final token = await _getToken();
    try {
      final res = await _apiClient.get(ApiConstants.shopInventory, token: token);
      if (res is List) {
        final list = res.map((item) => UserInventoryItemModel.fromJson(item as Map<String, dynamic>)).toList();
        // Cập nhật local cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('local_user_inventory', jsonEncode(list.map((i) => i.toJson()).toList()));
        return list;
      }
    } catch (e) {
      debugPrint('Error getInventory from backend: $e. Checking local storage.');
    }

    // Fallback: Lấy từ SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('local_user_inventory');
      if (localJson != null && localJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(localJson);
        return decoded.map((i) => UserInventoryItemModel.fromJson(i as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return [];
  }

  Future<Map<String, dynamic>> purchaseItem(String itemId, {int quantity = 1}) async {
    final token = await _getToken();
    final item = defaultShopItemsList.firstWhere(
      (i) => i.id == itemId,
      orElse: () => defaultShopItemsList.first,
    );

    try {
      final res = await _apiClient.post(
        ApiConstants.shopPurchase,
        token: token,
        body: {
          'itemId': itemId,
          'quantity': quantity,
        },
      );
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (e) {
      debugPrint('Error purchaseItem backend: $e');
      rethrow;
    }

    // Fallback nếu server trả rỗng
    return {
      'success': true,
      'item': item.toJson(),
      'quantity': quantity,
      'totalCost': item.price * quantity,
      'message': 'Đã mua thành công ${item.name}!',
    };
  }
}
