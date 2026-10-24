import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';

class ServerWaitingScreen extends StatefulWidget {
  final VoidCallback onServerReady;
  final VoidCallback? onSkip;
  final bool isTestingPreview;

  const ServerWaitingScreen({
    super.key,
    required this.onServerReady,
    this.onSkip,
    this.isTestingPreview = false,
  });

  /// Helper tiện lợi để mở màn hình xem trước / thử nghiệm từ bất kỳ đâu
  static void showPreview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServerWaitingScreen(
          isTestingPreview: true,
          onServerReady: () => Navigator.of(context).pop(),
          onSkip: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  State<ServerWaitingScreen> createState() => _ServerWaitingScreenState();
}

class _ServerWaitingScreenState extends State<ServerWaitingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  Timer? _pingTimer;

  bool _isChecking = false;
  bool _isSuccess = false;
  int _attemptCount = 0;
  String _statusMessage = 'Đang phóng phi kiếm thức tỉnh máy chủ...';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _startHealthPolling();
  }

  void _startHealthPolling() {
    // 1. Thử ping ngay lập tức lần đầu
    _checkServer();

    // 2. Định kỳ lặp lại kiểm tra tín hiệu thực tế mỗi 2.5 giây
    // Không dùng đếm ngược vì Render cold-start khởi động không cố định thời gian
    _pingTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (!mounted || _isSuccess) return;
      _checkServer();
    });
  }

  /// Logic kiểm tra thực tế xem máy chủ đã mở hoàn tất hay chưa qua /api/health
  Future<void> _checkServer() async {
    if (_isChecking || _isSuccess) return;
    if (mounted) {
      setState(() {
        _isChecking = true;
        _attemptCount++;
        if (_attemptCount <= 3) {
          _statusMessage = 'Đang kết nối tới máy chủ Render...';
        } else if (_attemptCount <= 10) {
          _statusMessage = 'Máy chủ Render đang nạp tài nguyên và khởi động...';
        } else {
          _statusMessage = 'Đang thiết lập linh mạch, sắp hoàn tất khởi động...';
        }
      });
    }

    try {
      final uri = Uri.parse('${ApiConstants.defaultBaseUrl}${ApiConstants.health}');
      final res = await http.get(uri).timeout(const Duration(seconds: 3));

      // Máy chủ đã mở hoàn tất khi trả về HTTP 200 OK!
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!mounted) return;
        setState(() {
          _isSuccess = true;
          _statusMessage = 'Máy chủ Tiên Giới đã khởi chạy hoàn tất! Đang tiến nhập...';
        });

        _pingTimer?.cancel();

        // Chờ 600ms để hiệu ứng xanh lục báo thành công hiển thị trọn vẹn
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          widget.onServerReady();
        }
        return;
      }
    } catch (_) {
      // Máy chủ chưa mở xong (đang cold-start / thức tỉnh), tiếp tục chờ lần ping tiếp theo
    } finally {
      if (mounted && !_isSuccess) {
        setState(() => _isChecking = false);
      }
    }
  }

  void _showConfigureUrlDialog() {
    final textCtrl = TextEditingController(text: ApiConstants.defaultBaseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF091726),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFC59A44), width: 1.2),
        ),
        title: const Text(
          'Cấu Hình URL Render',
          style: TextStyle(color: Color(0xFFFFF6DF), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập đường dẫn Backend trên Render của bạn (kèm /api):',
              style: TextStyle(color: Color(0xFFBAC7D5), fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://tienlo-backend.onrender.com/api',
                hintStyle: const TextStyle(color: Color(0xFF5A758D)),
                filled: true,
                fillColor: const Color(0xFF060F1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFF2C465)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF8BA5BA))),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = textCtrl.text.trim();
              Navigator.pop(ctx);
              if (newUrl.isNotEmpty) {
                ApiConstants.customBaseUrl = newUrl;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('custom_backend_url', newUrl);
                _checkServer();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
            child: const Text('Lưu & Thử Lại'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _pingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B12),
      body: Stack(
        children: [
          // 1. Background Tiên Lộ Landscape
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_tienlo.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B1424), Color(0xFF04070D)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // 2. Dark fantasy mist overlays
          Positioned.fill(
            child: Container(
              color: const Color(0xFF040810).withValues(alpha: 0.82),
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF020408).withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),

          // 3. Main Center Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Celestial Mandala Animation Ring
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Vòng xoay huyền ảo bên ngoài
                          RotationTransition(
                            turns: _animController,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE5B869).withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF59E0B),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFDE68A),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Vòng hào quang ở giữa
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: _isSuccess
                                    ? [const Color(0xFF10B981), const Color(0xFF064E3B)]
                                    : [const Color(0xFFD97706), const Color(0xFF451A03)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isSuccess ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                                      .withValues(alpha: 0.45),
                                  blurRadius: 28,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                _isSuccess ? Icons.check_circle_rounded : Icons.auto_awesome,
                                color: Colors.white,
                                size: 42,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // TIÊU ĐỀ CHÍNH (Exact font dancingScript from Home Title)
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFFFF2D1),
                            Color(0xFFF6CE70),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          'Vui lòng đợi server khởi chạy...',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dancingScript(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // DÒNG THÔNG CẢM (Exact font dancingScript)
                      Text(
                        'Server free nên thông cảm nhé đạo hữu ☕',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dancingScript(
                          color: const Color(0xFFFDE68A),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Card Thông Tin Chi Tiết
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF091726).withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFC59A44).withValues(alpha: 0.5),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _isSuccess ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: (_isSuccess ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                                                    .withValues(alpha: 0.6),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isSuccess ? 'MÁY CHỦ SẴN SÀNG' : 'ĐANG KẾT NỐI MÁY CHỦ...',
                                          style: TextStyle(
                                            color: _isSuccess ? const Color(0xFF6EE7B7) : const Color(0xFFFBBF24),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        if (_isChecking && !_isSuccess)
                                          const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.6,
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
                                            ),
                                          )
                                        else
                                          Icon(
                                            _isSuccess ? Icons.check_circle_outline : Icons.wifi_tethering_rounded,
                                            size: 14,
                                            color: _isSuccess ? const Color(0xFF10B981) : const Color(0xFFFBBF24),
                                          ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _isSuccess ? '100% OK' : (_isChecking ? 'Kiểm tra...' : 'Tự động ping'),
                                          style: TextStyle(
                                            color: _isSuccess ? const Color(0xFF6EE7B7) : const Color(0xFFFDE68A),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Thanh tiến độ loading mượt mà
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: SizedBox(
                                    height: 5,
                                    child: _isSuccess
                                        ? Container(color: const Color(0xFF10B981))
                                        : const LinearProgressIndicator(
                                            backgroundColor: Color(0xFF0F1E2E),
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Text(
                                  _statusMessage,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFBAC7D5),
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '💡 Render Free Tier sẽ tự động tạm ngủ khi không có truy cập. Hệ thống đang liên tục kiểm tra tín hiệu thực tế; ngay khi máy chủ khởi động hoàn tất sẽ tự động tiến nhập ngay lập tức!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nút Kiểm Tra Lại Ngay
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isChecking ? null : _checkServer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: Color(0xFFFDE68A), width: 1.2),
                            ),
                          ),
                          child: _isChecking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.refresh_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Kiểm Tra Kết Nối Lại Ngay',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Nút Bỏ Qua & Vào App Chế Độ Offline
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () {
                            if (widget.onSkip != null) {
                              widget.onSkip!();
                            } else {
                              widget.onServerReady();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF8BA5BA),
                            side: BorderSide(
                              color: const Color(0xFF5A758D).withValues(alpha: 0.6),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.offline_bolt_outlined, size: 16),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Vào Chế Độ Ngoại Tuyến (Offline)',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Nút Cấu Hình URL Render
                      TextButton.icon(
                        onPressed: _showConfigureUrlDialog,
                        icon: const Icon(Icons.settings_ethernet_rounded, size: 16, color: Color(0xFF64748B)),
                        label: Text(
                          'Cấu hình URL Render (${ApiConstants.defaultBaseUrl})',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
