import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/user_model.dart';
import 'auth_service.dart';

class AuthRepository {
  final AuthService _authService;
  final ApiClient _apiClient;

  static const _keyToken = 'auth_token';
  static const _keyUser = 'auth_user';

  AuthRepository({
    AuthService? authService,
    ApiClient? apiClient,
  })  : _authService = authService ?? AuthService(),
        _apiClient = apiClient ?? ApiClient();

  /// Đăng nhập bằng Google và đồng bộ dữ liệu vào NestJS -> Supabase
  Future<UserModel> signInWithGoogle() async {
    final authResult = await _authService.signInWithGoogle();
    if (authResult == null) {
      throw Exception('Người dùng đã hủy đăng nhập');
    }

    return _syncAndSave(authResult);
  }

  /// Đăng nhập chế độ thử nghiệm (Demo)
  Future<UserModel> signInWithDemo() async {
    final authResult = await _authService.signInWithDemo();
    return _syncAndSave(authResult);
  }

  Future<UserModel> _syncAndSave(AuthResult authResult) async {
    // 1. Gửi request đồng bộ tới NestJS Backend kèm Bearer Token
    final response = await _apiClient.post(
      ApiConstants.authSync,
      token: authResult.idToken,
      body: {
        'displayName': authResult.displayName,
        'email': authResult.email,
        'photoUrl': authResult.photoUrl,
      },
    );

    // 2. Parse thông tin UserModel trả về từ Supabase (thông qua NestJS)
    final userData = response['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userData);

    // 3. Lưu vào SharedPreferences để duy trì phiên
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, authResult.idToken);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));

    return user;
  }

  /// Lấy thông tin người dùng đã lưu
  Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_keyUser);
    if (userJson != null) {
      try {
        return UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Lấy token đã lưu
  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Lấy token hợp lệ (tự động làm mới qua GoogleSignIn nếu cần)
  Future<String?> getValidToken() async {
    try {
      final freshToken = await _authService.getFreshIdToken();
      if (freshToken != null && freshToken.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, freshToken);
        return freshToken;
      }
    } catch (_) {}

    return getSavedToken();
  }

  /// Kiểm tra trạng thái đăng nhập
  Future<bool> isLoggedIn() async {
    final token = await getSavedToken();
    return token != null && token.isNotEmpty;
  }

  /// Đăng xuất
  Future<void> signOut() async {
    await _authService.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
