import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
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
  Timer? _secondTimer;

  int _elapsedSeconds = 0;
  bool _isChecking = false;
  bool _isSuccess = false;
  String _statusMessage = 'Đang phóng phi kiếm thức tỉnh máy chủ...';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _startTimers();
  }

  void _startTimers() {
    // Đếm giây hiển thị cho đạo hữu
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isSuccess) return;
      setState(() {
        _elapsedSeconds++;
        if (_elapsedSeconds < 15) {
          _statusMessage = 'Đang phóng phi kiếm thức tỉnh máy chủ...';
        } else if (_elapsedSeconds < 35) {
          _statusMessage = 'Máy chủ Render đang nạp tài nguyên và khởi động...';
        } else if (_elapsedSeconds < 65) {
          _statusMessage = 'Đang thiết lập linh mạch kết nối Tiên Giới...';
        } else {
          _statusMessage = 'Sắp hoàn tất khởi động, xin kiên nhẫn một chút...';
        }
      });
    });

    // Thử ping ngay lần đầu
    _checkServer();

    // Lặp lại ping mỗi 3.5 giây
    _pingTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (!mounted || _isSuccess) return;
      _checkServer();
    });
  }

  Future<void> _checkServer() async {
    if (_isChecking || _isSuccess) return;
    setState(() => _isChecking = true);

    try {
      final uri = Uri.parse('${ApiConstants.defaultBaseUrl}${ApiConstants.health}');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!mounted) return;
        setState(() {
          _isSuccess = true;
          _statusMessage = 'Máy chủ Tiên Giới đã khởi chạy thành công! Đang tiến nhập...';
        });

        // Chờ 1 giây để đạo hữu kịp ngắm thông báo thành công
        await Future.delayed(const Duration(milliseconds: 1100));
        if (mounted) {
          widget.onServerReady();
        }
        return;
      }
    } catch (_) {
      // Server chưa khởi động xong (cold start), tiếp tục chờ
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _animController.dispose();
    _pingTimer?.cancel();
    _secondTimer?.cancel();
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

          // 2. Cinematic Dark Mist & Vignette Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    const Color(0xFF070B12).withValues(alpha: 0.70),
                    const Color(0xFF070B12).withValues(alpha: 0.94),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Nút Đóng (khi đang ở chế độ Xem Trước / Thử Nghiệm)
          if (widget.isTestingPreview)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 18,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141F30).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5B869).withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close_rounded, color: Color(0xFFFDE68A), size: 16),
                      SizedBox(width: 4),
                      Text('Đóng xem trước', style: TextStyle(color: Color(0xFFFDE68A), fontSize: 11.5)),
                    ],
                  ),
                ),
              ),
            ),

          // 4. Foreground Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141F30).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE5B869).withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE5B869).withValues(alpha: 0.25),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, color: Color(0xFFF2C465), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'TIÊN GIỚI KHỞI ĐỘNG',
                              style: TextStyle(
                                color: Color(0xFFFDE68A),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Animated Rotating Mandala Aura
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
                                          _isSuccess ? 'ĐÃ KẾT NỐI' : 'ĐANG THỨC TỈNH...',
                                          style: TextStyle(
                                            color: _isSuccess ? const Color(0xFF6EE7B7) : const Color(0xFFFBBF24),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _formatTimer(_elapsedSeconds),
                                      style: GoogleFonts.robotoMono(
                                        color: const Color(0xFFFDE68A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                  '💡 Render Free Tier sẽ tự động tạm ngủ khi không có truy cập. Khi có đạo hữu vào, máy chủ mất khoảng 30s - 1.5 phút để khởi động lại.',
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
