import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../../features/auth/data/auth_repository.dart';

class FeedbackService {
  static const String _smtpHost = 'smtp.gmail.com';
  static const int _smtpPort = 465;
  static const String _systemGmailUser = 'shiinamizuha@gmail.com';
  static const String _systemGmailAppPass = 'sqrbgpxwzutbukdq';
  static const String _adminGmail = 'ngovanm691@gmail.com';

  final ApiClient _apiClient;
  final AuthRepository _authRepository;

  FeedbackService({
    ApiClient? apiClient,
    AuthRepository? authRepository,
  })  : _apiClient = apiClient ?? ApiClient(),
        _authRepository = authRepository ?? AuthRepository();

  /// Gửi báo cáo sự cố tự động từ Gmail hệ thống (shiinamizuha@gmail.com)
  /// thẳng tới Gmail Quản Trị Viên (ngovanm691@gmail.com) và lưu lên máy chủ.
  Future<Map<String, dynamic>> sendBugReport({
    required String title,
    required String description,
    String category = 'GENERAL',
    String screen = 'UNKNOWN_SCREEN',
    String? stackTrace,
  }) async {
    try {
      final savedUser = await _authRepository.getSavedUser();
      final token = await _authRepository.getSavedToken();

      String effectiveUserAccount = 'Khách (Chưa đăng nhập)';
      if (savedUser != null) {
        final uname = savedUser.displayName.trim();
        final uemail = savedUser.email.trim();
        if (uname.isNotEmpty && uemail.isNotEmpty) {
          effectiveUserAccount = '$uname ($uemail)';
        } else if (uemail.isNotEmpty) {
          effectiveUserAccount = uemail;
        } else if (uname.isNotEmpty) {
          effectiveUserAccount = uname;
        }
      }

      final effectiveUserId = savedUser?.id ?? 'anonymous';

      String deviceInfo = 'Unknown Device';
      try {
        if (!kIsWeb) {
          deviceInfo = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
        } else {
          deviceInfo = 'Web Browser';
        }
      } catch (_) {}

      final cleanTitle = title.trim();
      final cleanDesc = description.trim();
      final cleanTrace = (stackTrace != null && stackTrace.trim().isNotEmpty)
          ? stackTrace.trim()
          : null;

      // 1. Gửi trực tiếp qua cổng Gmail SMTPS (465) từ Gmail hệ thống tới ngovanm691@gmail.com
      // (Vượt qua giới hạn chặn cổng SMTP trên gói Render Cloud Free)
      bool sentDirectOk = false;
      if (!kIsWeb) {
        sentDirectOk = await _sendDirectGmailSmtp(
          title: cleanTitle,
          description: cleanDesc,
          category: category,
          screen: screen,
          userAccount: effectiveUserAccount,
          userId: effectiveUserId,
          deviceInfo: deviceInfo,
          stackTrace: cleanTrace,
        );
      }

      final payload = <String, dynamic>{
        'title': cleanTitle,
        'description': cleanDesc,
        'category': category,
        'screen': screen,
        'userEmail': effectiveUserAccount,
        'userId': effectiveUserId,
        'deviceInfo': deviceInfo,
        'appVersion': '1.1.2',
        'sentByClient': sentDirectOk,
      };
      if (cleanTrace != null) {
        payload['stackTrace'] = cleanTrace;
      }

      // 2. Nếu đã gửi thẳng tới Gmail Admin thành công, đồng bộ ngầm về Backend để lưu lịch sử
      if (sentDirectOk) {
        unawaited(
          _apiClient
              .post(
                ApiConstants.feedbackReport,
                token: token,
                body: payload,
                timeout: const Duration(seconds: 12),
              )
              .catchError((_) => null),
        );

        return {
          'success': true,
          'message':
              'Đã gửi báo cáo sự cố từ hệ thống tới Gmail Quản Trị Viên ($_adminGmail)!',
        };
      }

      // 3. Dự phòng: Nếu thiết bị không kết nối trực tiếp được cổng 465, gửi qua Backend xử lý
      final response = await _apiClient.post(
        ApiConstants.feedbackReport,
        token: token,
        body: payload,
        timeout: const Duration(seconds: 15),
      );

      if (response is Map<String, dynamic>) {
        return response;
      }

      return {
        'success': true,
        'message': 'Báo cáo sự cố đã được gửi thành công tới Quản Trị Viên ($_adminGmail)!',
      };
    } catch (e) {
      debugPrint('Lỗi gửi feedback report: $e');
      final isTimeout = e.toString().contains('TimeoutException');
      return {
        'success': false,
        'message': isTimeout
            ? 'Kết nối máy chủ quá thời gian chờ. Vui lòng kiểm tra mạng hoặc thử lại sau.'
            : 'Không thể kết nối để gửi báo cáo: $e',
      };
    }
  }

  /// Kết nối trực tiếp tới smtp.gmail.com:465 bằng Gmail hệ thống (shiinamizuha@gmail.com)
  /// và gửi email HTML tới Gmail Admin (ngovanm691@gmail.com).
  Future<bool> _sendDirectGmailSmtp({
    required String title,
    required String description,
    required String category,
    required String screen,
    required String userAccount,
    required String userId,
    required String deviceInfo,
    String? stackTrace,
  }) async {
    SecureSocket? socket;
    try {
      socket = await SecureSocket.connect(
        _smtpHost,
        _smtpPort,
        timeout: const Duration(seconds: 8),
      );

      final buffer = StringBuffer();
      Completer<String>? waiter;

      void evaluateBuffer() {
        if (waiter == null || waiter!.isCompleted) return;
        final current = buffer.toString();
        if (!current.endsWith('\r\n')) return;
        final lines = current.split('\r\n');
        if (lines.length < 2) return;
        final lastLine = lines[lines.length - 2];
        // Dòng cuối của phản hồi SMTP có dạng "250 ..." (3 chữ số + khoảng trắng)
        if (RegExp(r'^\d{3}(\s|$)').hasMatch(lastLine)) {
          buffer.clear();
          waiter!.complete(current);
        }
      }

      final sub = socket.listen(
        (data) {
          buffer.write(utf8.decode(data, allowMalformed: true));
          evaluateBuffer();
        },
        onError: (err) {
          if (waiter != null && !waiter!.isCompleted) {
            waiter!.completeError(err);
          }
        },
        onDone: () {
          if (waiter != null && !waiter!.isCompleted) {
            waiter!.complete(buffer.toString());
          }
        },
      );

      Future<String> expectResponse() {
        waiter = Completer<String>();
        evaluateBuffer();
        return waiter!.future.timeout(const Duration(seconds: 6));
      }

      Future<String> sendCommand(String cmd) async {
        waiter = Completer<String>();
        socket!.add(utf8.encode('$cmd\r\n'));
        await socket.flush();
        return waiter!.future.timeout(const Duration(seconds: 6));
      }

      // 1. Đợi lời chào 220 từ Gmail SMTP
      final greeting = await expectResponse();
      if (!greeting.startsWith('220')) {
        await sub.cancel();
        return false;
      }

      // 2. EHLO
      final ehlo = await sendCommand('EHLO tienlo.app');
      if (!ehlo.startsWith('250')) {
        await sub.cancel();
        return false;
      }

      // 3. AUTH LOGIN
      final authInit = await sendCommand('AUTH LOGIN');
      if (!authInit.startsWith('334')) {
        await sub.cancel();
        return false;
      }

      final userRes = await sendCommand(base64Encode(utf8.encode(_systemGmailUser)));
      if (!userRes.startsWith('334')) {
        await sub.cancel();
        return false;
      }

      final passRes = await sendCommand(base64Encode(utf8.encode(_systemGmailAppPass)));
      if (!passRes.startsWith('235')) {
        await sub.cancel();
        return false;
      }

      // 4. MAIL FROM & RCPT TO
      final mailFrom = await sendCommand('MAIL FROM:<$_systemGmailUser>');
      if (!mailFrom.startsWith('250')) {
        await sub.cancel();
        return false;
      }

      final rcptTo = await sendCommand('RCPT TO:<$_adminGmail>');
      if (!rcptTo.startsWith('250')) {
        await sub.cancel();
        return false;
      }

      // 5. DATA
      final dataCmd = await sendCommand('DATA');
      if (!dataCmd.startsWith('354')) {
        await sub.cancel();
        return false;
      }

      final htmlBody = _buildEmailHtml(
        title: title,
        description: description,
        category: category,
        screen: screen,
        userAccount: userAccount,
        userId: userId,
        deviceInfo: deviceInfo,
        stackTrace: stackTrace,
      );

      final fromNameB64 = base64Encode(utf8.encode('Hệ Thống Tiên Lộ'));
      final subjectB64 = base64Encode(
        utf8.encode('🚨 [TIÊN LỘ LỖI] [$category] $title'),
      );
      final htmlB64 = _chunkBase64(base64Encode(utf8.encode(htmlBody)));

      final mimeData = StringBuffer()
        ..write('From: =?UTF-8?B?$fromNameB64?= <$_systemGmailUser>\r\n')
        ..write('To: <$_adminGmail>\r\n')
        ..write('Subject: =?UTF-8?B?$subjectB64?=\r\n')
        ..write('MIME-Version: 1.0\r\n')
        ..write('Content-Type: text/html; charset=UTF-8\r\n')
        ..write('Content-Transfer-Encoding: base64\r\n')
        ..write('\r\n')
        ..write(htmlB64)
        ..write('\r\n.');

      final sendDataRes = await sendCommand(mimeData.toString());
      await sendCommand('QUIT').catchError((_) => '');
      await sub.cancel();

      return sendDataRes.startsWith('250');
    } catch (e) {
      debugPrint('Direct Gmail SMTP error: $e');
      return false;
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
    }
  }

  String _chunkBase64(String b64) {
    final sb = StringBuffer();
    for (int i = 0; i < b64.length; i += 76) {
      final end = (i + 76 < b64.length) ? i + 76 : b64.length;
      sb.write(b64.substring(i, end));
      if (end < b64.length) sb.write('\r\n');
    }
    return sb.toString();
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  String _buildEmailHtml({
    required String title,
    required String description,
    required String category,
    required String screen,
    required String userAccount,
    required String userId,
    required String deviceInfo,
    String? stackTrace,
  }) {
    final now = DateTime.now();
    final timeStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final traceHtml = (stackTrace != null && stackTrace.isNotEmpty)
        ? '''
      <div class="field">
        <div class="label">Log Lỗi Kỹ Thuật (Stack Trace)</div>
        <div class="trace-box">${_escapeHtml(stackTrace)}</div>
      </div>'''
        : '';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #0b0f19; color: #e2e8f0; margin: 0; padding: 24px; }
    .card { background-color: #111827; border: 1px solid #374151; border-radius: 12px; max-width: 650px; margin: 0 auto; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.5); }
    .header { background: linear-gradient(135deg, #7f1d1d 0%, #991b1b 50%, #450a0a 100%); padding: 20px 24px; border-bottom: 2px solid #ef4444; }
    .header h1 { margin: 0; font-size: 20px; color: #ffffff; }
    .badge { display: inline-block; padding: 4px 10px; border-radius: 6px; font-size: 12px; font-weight: 700; background-color: #ef4444; color: #ffffff; text-transform: uppercase; margin-top: 8px; }
    .content { padding: 24px; }
    .field { margin-bottom: 18px; }
    .label { font-size: 12px; text-transform: uppercase; letter-spacing: 0.05em; color: #9ca3af; margin-bottom: 6px; font-weight: 600; }
    .value { font-size: 15px; color: #f3f4f6; background-color: #1f2937; padding: 10px 14px; border-radius: 8px; border: 1px solid #374151; word-break: break-word; }
    .description-box { font-size: 15px; line-height: 1.6; color: #f9fafb; background-color: #1a2234; padding: 16px; border-radius: 8px; border-left: 4px solid #ef4444; white-space: pre-wrap; word-break: break-word; }
    .trace-box { font-family: 'Courier New', Courier, monospace; font-size: 12px; color: #fca5a5; background-color: #030712; padding: 12px; border-radius: 6px; overflow-x: auto; max-height: 250px; white-space: pre-wrap; border: 1px solid #7f1d1d; }
    .footer { padding: 16px 24px; background-color: #0b0f19; border-top: 1px solid #1f2937; text-align: center; font-size: 12px; color: #6b7280; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <h1>🚨 [TIÊN LỘ] Báo Cáo Sự Cố Mới</h1>
      <div class="badge">${_escapeHtml(category)} • ${_escapeHtml(screen)}</div>
    </div>
    <div class="content">
      <div class="field">
        <div class="label">Tiêu Đề Sự Cố</div>
        <div class="value" style="font-weight: 700; color: #f87171;">${_escapeHtml(title)}</div>
      </div>
      <div class="field">
        <div class="label">Mô Tả Chi Tiết</div>
        <div class="description-box">${_escapeHtml(description)}</div>
      </div>
      <div class="field">
        <div class="label">Tài Khoản Đang Sử Dụng (Tự Động Ghi Nhận)</div>
        <div class="value">
          <strong>Tài khoản:</strong> ${_escapeHtml(userAccount)}<br/>
          <strong>User ID:</strong> ${_escapeHtml(userId)}
        </div>
      </div>
      <div class="field">
        <div class="label">Vị Trí &amp; Thiết Bị</div>
        <div class="value">
          <strong>Màn hình:</strong> ${_escapeHtml(screen)}<br/>
          <strong>Phiên bản App:</strong> 1.1.2<br/>
          <strong>Thiết bị:</strong> ${_escapeHtml(deviceInfo)}
        </div>
      </div>
      $traceHtml
      <div class="field" style="margin-bottom: 0;">
        <div class="label">Thời Gian Ghi Nhận</div>
        <div class="value">$timeStr (Giờ Việt Nam)</div>
      </div>
    </div>
    <div class="footer">
      Gửi tự động từ Gmail Hệ Thống ($_systemGmailUser) tới Quản Trị Viên ($_adminGmail) • Tiên Lộ Tu Thân
    </div>
  </div>
</body>
</html>
''';
  }
}
