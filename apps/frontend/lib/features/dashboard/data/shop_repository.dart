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
    List<UserInventoryItemModel> backendItems = [];
    bool backendSuccess = false;

    try {
      final res = await _apiClient.get(ApiConstants.shopInventory, token: token);
      if (res is List) {
        backendItems = res.map((item) => UserInventoryItemModel.fromJson(item as Map<String, dynamic>)).toList();
        backendSuccess = true;
      }
    } catch (e) {
      debugPrint('Error getInventory from backend: $e. Checking local storage.');
    }

    final prefs = await SharedPreferences.getInstance();
    final localJson = prefs.getString('local_user_inventory');
    List<UserInventoryItemModel> localItems = [];

    if (localJson != null && localJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(localJson);
        localItems = decoded.map((i) => UserInventoryItemModel.fromJson(i as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    if (backendSuccess && backendItems.isNotEmpty) {
      // Backend có dữ liệu -> Cập nhật local cache
      await prefs.setString('local_user_inventory', jsonEncode(backendItems.map((i) => i.toJson()).toList()));
      return backendItems;
    } else if (backendSuccess && backendItems.isEmpty && localItems.isNotEmpty) {
      // Backend trả rỗng nhưng local có đồ -> Giữ lại local đồ, tránh mất đồ người dùng
      return localItems;
    } else if (backendItems.isNotEmpty) {
      return backendItems;
    }

    return localItems;
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
        // Cập nhật local inventory nếu có inventory trả về
        if (res['inventory'] is List) {
          final invList = (res['inventory'] as List)
              .map((i) => UserInventoryItemModel.fromJson(i as Map<String, dynamic>))
              .toList();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('local_user_inventory', jsonEncode(invList.map((i) => i.toJson()).toList()));
        }
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

  Future<Map<String, dynamic>> useItem(String itemId, {int quantity = 1}) async {
    final token = await _getToken();

    try {
      final res = await _apiClient.post(
        ApiConstants.shopUse,
        token: token,
        body: {
          'itemId': itemId,
          'quantity': quantity,
        },
      );
      if (res is Map<String, dynamic>) {
        if (res['inventory'] is List) {
          final invList = (res['inventory'] as List)
              .map((i) => UserInventoryItemModel.fromJson(i as Map<String, dynamic>))
              .toList();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('local_user_inventory', jsonEncode(invList.map((i) => i.toJson()).toList()));
        }
        return res;
      }
    } catch (e) {
      debugPrint('Error useItem backend: $e');
      rethrow;
    }

    return {
      'success': true,
      'message': 'Đã sử dụng vật phẩm thành công!',
    };
  }
}
