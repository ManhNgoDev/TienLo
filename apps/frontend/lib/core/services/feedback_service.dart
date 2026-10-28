import 'dart:io';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../../features/auth/data/auth_repository.dart';

class FeedbackService {
  final ApiClient _apiClient;
  final AuthRepository _authRepository;

  FeedbackService({
    ApiClient? apiClient,
    AuthRepository? authRepository,
  })  : _apiClient = apiClient ?? ApiClient(),
        _authRepository = authRepository ?? AuthRepository();

  /// Gửi báo cáo sự cố / lỗi về máy chủ và chuyển tiếp tới Gmail của Admin
  Future<Map<String, dynamic>> sendBugReport({
    required String title,
    required String description,
    String category = 'GENERAL',
    String screen = 'UNKNOWN_SCREEN',
    String? userEmail,
    String? stackTrace,
  }) async {
    try {
      final savedUser = await _authRepository.getSavedUser();
      final token = await _authRepository.getSavedToken();

      String effectiveEmail = userEmail?.trim() ?? '';
      if (effectiveEmail.isEmpty && savedUser != null && savedUser.email.isNotEmpty) {
        effectiveEmail = savedUser.email;
      }
      if (effectiveEmail.isEmpty) {
        effectiveEmail = 'Người dùng ẩn danh';
      }

      String deviceInfo = 'Unknown Device';
      try {
        if (!kIsWeb) {
          deviceInfo = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
        } else {
          deviceInfo = 'Web Browser';
        }
      } catch (_) {}

      final payload = {
        'title': title.trim(),
        'description': description.trim(),
        'category': category,
        'screen': screen,
        'userEmail': effectiveEmail,
        'userId': savedUser?.id ?? 'anonymous',
        'deviceInfo': deviceInfo,
        'appVersion': '1.0.5',
        if (stackTrace != null && stackTrace.trim().isNotEmpty)
          'stackTrace': stackTrace.trim(),
      };

      final response = await _apiClient.post(
        ApiConstants.feedbackReport,
        token: token,
        body: payload,
      );

      if (response is Map<String, dynamic>) {
        return response;
      }

      return {
        'success': true,
        'message': 'Báo cáo sự cố đã được gửi thành công tới Quản Trị Viên!',
      };
    } catch (e) {
      debugPrint('Lỗi gửi feedback report: $e');
      return {
        'success': false,
        'message': 'Không thể kết nối máy chủ để gửi báo cáo: $e',
      };
    }
  }
}
