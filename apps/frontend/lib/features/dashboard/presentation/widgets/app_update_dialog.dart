import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ota_update/ota_update.dart';
import '../../../../core/services/app_update_service.dart';

class AppUpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
  });

  static Future<void> show(BuildContext context, AppUpdateInfo updateInfo) {
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => AppUpdateDialog(updateInfo: updateInfo),
    );
  }

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';
  String? _errorMessage;
  StreamSubscription<OtaEvent>? _otaSubscription;

  @override
  void dispose() {
    _otaSubscription?.cancel();
    super.dispose();
  }

  void _startUpdate() {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _errorMessage = null;
      _statusText = 'Đang kết nối tải linh chương APK...';
    });

    try {
      final stream = AppUpdateService().startOtaUpdate(widget.updateInfo.downloadUrl);
      _otaSubscription = stream.listen(
        (OtaEvent event) {
          if (!mounted) return;
          setState(() {
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                final intVal = int.tryParse(event.value ?? '0') ?? 0;
                _progress = (intVal / 100.0).clamp(0.0, 1.0);
                _statusText = 'Đang tải bản cập nhật: $intVal%';
                break;
              case OtaStatus.INSTALLING:
                _progress = 1.0;
                _statusText = 'Tải hoàn tất! Đang mở trình cài đặt hệ thống...';
                break;
              case OtaStatus.INSTALLATION_DONE:
                _progress = 1.0;
                _statusText = 'Cài đặt hoàn tất!';
                _isDownloading = false;
                break;
              case OtaStatus.ALREADY_RUNNING_ERROR:
                _errorMessage = 'Quá trình tải đang diễn ra trong nền.';
                _isDownloading = false;
                break;
              case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                _errorMessage = 'Thiếu quyền cài đặt ứng dụng từ nguồn không xác định. Vui lòng cấp quyền trong Cài đặt thiết bị.';
                _isDownloading = false;
                break;
              case OtaStatus.DOWNLOAD_ERROR:
                _errorMessage = 'Tải bản cập nhật thất bại: ${event.value ?? 'Lỗi tải tệp'}.';
                _isDownloading = false;
                break;
              case OtaStatus.CHECKSUM_ERROR:
                _errorMessage = 'Tệp cài đặt APK không toàn vẹn (Lỗi mã kiểm tra).';
                _isDownloading = false;
                break;
              case OtaStatus.INSTALLATION_ERROR:
                _errorMessage = 'Không thể mở trình cài đặt: ${event.value ?? 'Lỗi cài đặt'}.';
                _isDownloading = false;
                break;
              case OtaStatus.CANCELED:
                _statusText = 'Đã hủy tải bản cập nhật.';
                _isDownloading = false;
                break;
              case OtaStatus.INTERNAL_ERROR:
                _errorMessage = 'Không thể cập nhật: ${event.value ?? 'Lỗi không xác định'}.';
                _isDownloading = false;
                break;
            }
          });
        },
        onError: (err) {
          if (!mounted) return;
          setState(() {
            _isDownloading = false;
            _errorMessage = 'Lỗi kết nối khi tải: $err';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _errorMessage = 'Lỗi khởi động tiến trình: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.updateInfo;

    return PopScope(
      canPop: !info.forceUpdate && !_isDownloading,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1929).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFC59A44).withValues(alpha: 0.75),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                      blurRadius: 32,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Badge Header
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8B95E).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE8B95E).withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, color: Color(0xFFFBBF24), size: 14),
                              SizedBox(width: 6),
                              Text(
                                'THIÊN ĐẠO NÂNG CẤP',
                                style: TextStyle(
                                  color: Color(0xFFE8B95E),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        'Khai Mở Bản Mới v${info.latestVersion}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFFFF6DF),
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Version transition row
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF132235),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF334E68)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'v${info.currentVersion}',
                                style: const TextStyle(
                                  color: Color(0xFF8BA5BA),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward_rounded, color: Color(0xFFFBBF24), size: 14),
                              ),
                              Text(
                                'v${info.latestVersion}',
                                style: const TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Release notes section
                      const Text(
                        'Chi tiết nâng cấp:',
                        style: TextStyle(
                          color: Color(0xFFBAC7D5),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 140),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF08121E).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF8BA5BA).withValues(alpha: 0.2),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            info.releaseNotes.isNotEmpty
                                ? info.releaseNotes
                                : '• Tối ưu hóa tính năng và sửa các lỗi tu vi đã biết.\n• Nâng cấp độ mượt và ổn định toàn hệ thống.',
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Progress or error state
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ] else if (_isDownloading) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _statusText,
                                  style: const TextStyle(color: Color(0xFFBAC7D5), fontSize: 12),
                                ),
                                Text(
                                  '${(_progress * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Color(0xFFFBBF24),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight: 7,
                                backgroundColor: const Color(0xFF132235),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Sau khi tải xong, hệ thống sẽ tự động mở bảng cài đặt đè.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF8BA5BA), fontSize: 10.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Action Buttons
                      if (!_isDownloading)
                        Row(
                          children: [
                            if (!info.forceUpdate) ...[
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    foregroundColor: const Color(0xFF8BA5BA),
                                  ),
                                  child: const Text('Để sau', style: TextStyle(fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _startUpdate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(color: Color(0xFFFBBF24), width: 1.2),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.system_update_alt, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Cập nhật ngay',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
