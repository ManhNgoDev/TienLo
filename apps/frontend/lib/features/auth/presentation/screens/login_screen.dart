import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../dashboard/presentation/widgets/bug_report_dialog.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_model.dart';

class LoginScreen extends StatefulWidget {
  final Function(UserModel user) onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthRepository _authRepository = AuthRepository();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPlatformError = false;

  void _processAuthError(dynamic e) {
    final errorStr = e.toString();
    debugPrint('Chi tiết lỗi đăng nhập: $errorStr');

    if (errorStr.contains('ApiException: 10') ||
        errorStr.contains('sign_in_failed') ||
        errorStr.contains('PlatformException') ||
        errorStr.contains('channel-error') ||
        errorStr.contains('MissingPluginException')) {
      _isPlatformError = true;
      _errorMessage =
          'Google Sign-In lỗi nền tảng (ApiException 10):\n'
          '• Nguyên nhân: Chưa gán mã SHA-1 vào Firebase Console hoặc file google-services.json chưa cập nhật.\n'
          '• Giải pháp: Bạn có thể chọn "Vào bằng Local Dev" bên dưới để test mọi tính năng game ngay!';
    } else if (errorStr.contains('SocketException') ||
        errorStr.contains('Connection refused') ||
        errorStr.contains('Failed host lookup') ||
        errorStr.contains('ClientException')) {
      _isPlatformError = false;
      _errorMessage =
          'Không thể kết nối máy chủ (${ApiConstants.defaultBaseUrl}).\n'
          'Vui lòng kiểm tra server Backend đã chạy chưa hoặc bấm vào nút Môi trường ở góc trên để chọn lại.';
    } else {
      _isPlatformError = false;
      _errorMessage = errorStr.replaceFirst('Exception: ', '');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isPlatformError = false;
    });

    try {
      final user = await _authRepository.signInWithGoogle();
      widget.onLoginSuccess(user);
    } catch (e) {
      setState(() {
        _processAuthError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDemoSignIn({
    String uid = 'demo-google-uid-123456',
    String displayName = 'Mạnh Ngô (Dev)',
    String email = 'manh.ngo@tienlo.app',
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isPlatformError = false;
    });

    try {
      final user = await _authRepository.signInWithDemo(
        uid: uid,
        displayName: displayName,
        email: email,
      );
      widget.onLoginSuccess(user);
    } catch (e) {
      setState(() {
        _processAuthError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showCustomDevAccountDialog() async {
    final nameCtrl = TextEditingController(text: 'Đạo Hữu Tiêu Diêu');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5B869), width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Color(0xFFE5B869), size: 22),
            SizedBox(width: 8),
            Text(
              'Tạo Nhân Vật Test Local',
              style: TextStyle(
                color: Color(0xFFFDE68A),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập đạo hiệu nhân vật để test trên môi trường hiện tại:',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF070B12),
                hintText: 'Ví dụ: Hàn Lập, Tiêu Viêm...',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5B869)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                final cleanId = name
                    .toLowerCase()
                    .replaceAll(RegExp(r'[^a-z0-9]'), '')
                    .padRight(6, 'dev');
                _handleDemoSignIn(
                  uid: 'dev-custom-$cleanId',
                  displayName: name,
                  email: '$cleanId@tienlo.local',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Đăng Nhập Test'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEnvironmentSelectorDialog() async {
    BackendEnvType selectedType = ApiConstants.currentEnvType;
    final lanCtrl = TextEditingController(
      text: ApiConstants.customBaseUrl ?? 'http://192.168.1.100:3000/api',
    );
    String pingResult = '';
    bool isPinging = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xFF38BDF8), width: 1),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune_rounded, color: Color(0xFF38BDF8), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Cấu Hình Môi Trường Backend',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chọn môi trường để test local trước khi triển khai production:',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                const SizedBox(height: 16),

                // Option 1: Android Emulator
                _buildEnvOption(
                  ctx: ctx,
                  title: '📱 Máy Ảo Android (10.0.2.2:3000)',
                  subtitle: 'http://10.0.2.2:3000/api',
                  isSelected: selectedType == BackendEnvType.emulator,
                  onTap: () => setModalState(() => selectedType = BackendEnvType.emulator),
                ),
                const SizedBox(height: 8),

                // Option 2: Localhost PC
                _buildEnvOption(
                  ctx: ctx,
                  title: '💻 Máy Tính / Web (localhost:3000)',
                  subtitle: 'http://localhost:3000/api',
                  isSelected: selectedType == BackendEnvType.localhost,
                  onTap: () => setModalState(() => selectedType = BackendEnvType.localhost),
                ),
                const SizedBox(height: 8),

                // Option 3: LAN Wi-Fi
                _buildEnvOption(
                  ctx: ctx,
                  title: '📡 Mạng LAN Wi-Fi (Điện thoại thật)',
                  subtitle: selectedType == BackendEnvType.lan ? lanCtrl.text : 'Tuỳ chỉnh IP máy tính',
                  isSelected: selectedType == BackendEnvType.lan,
                  onTap: () => setModalState(() => selectedType = BackendEnvType.lan),
                ),
                if (selectedType == BackendEnvType.lan) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: lanCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'http://192.168.1.xxx:3000/api',
                      hintStyle: const TextStyle(color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFF070B12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                // Option 4: Production Render
                _buildEnvOption(
                  ctx: ctx,
                  title: '☁️ Production (Render Cloud)',
                  subtitle: ApiConstants.productionRenderUrl,
                  isSelected: selectedType == BackendEnvType.production,
                  onTap: () => setModalState(() => selectedType = BackendEnvType.production),
                ),
                const SizedBox(height: 14),

                // Ping Status
                if (pingResult.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: pingResult.contains('✅')
                          ? const Color(0xFF065F46).withValues(alpha: 0.6)
                          : const Color(0xFF7F1D1D).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      pingResult,
                      style: TextStyle(
                        color: pingResult.contains('✅')
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFFFCA5A5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isPinging
                            ? null
                            : () async {
                                setModalState(() {
                                  isPinging = true;
                                  pingResult = 'Đang kiểm tra kết nối...';
                                });
                                final testUrl = selectedType == BackendEnvType.lan
                                    ? lanCtrl.text.trim()
                                    : selectedType.defaultUrl;
                                final sw = Stopwatch()..start();
                                try {
                                  final uri = Uri.parse('$testUrl${ApiConstants.health}');
                                  final res = await http.get(uri).timeout(const Duration(seconds: 4));
                                  sw.stop();
                                  if (res.statusCode >= 200 && res.statusCode < 300) {
                                    setModalState(() {
                                      pingResult = '✅ Kết nối tốt! (${sw.elapsedMilliseconds}ms)';
                                      isPinging = false;
                                    });
                                  } else {
                                    setModalState(() {
                                      pingResult = '⚠️ Server phản hồi mã: ${res.statusCode}';
                                      isPinging = false;
                                    });
                                  }
                                } catch (err) {
                                  sw.stop();
                                  setModalState(() {
                                    pingResult = '❌ Không thể kết nối tới $testUrl (Kiểm tra lại IP hoặc server)';
                                    isPinging = false;
                                  });
                                }
                              },
                        icon: isPinging
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                              )
                            : const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF38BDF8)),
                        label: const Text('Kiểm Tra (Ping)', style: TextStyle(color: Color(0xFF38BDF8))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF38BDF8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final custom = selectedType == BackendEnvType.lan ? lanCtrl.text.trim() : null;
                          await ApiConstants.setEnvironment(selectedType, custom);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Áp Dụng'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnvOption({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0369A1).withValues(alpha: 0.3)
              : const Color(0xFF070B12).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF1E293B),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B12),
      body: Stack(
        children: [
          // 1. Background Image (Tiên Lộ Landscape)
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_tienlo.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF020617)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // 2. Cinematic Vignette & Ambient Gradient Overlays
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.55),
                    const Color(0xFF070B12).withValues(alpha: 0.96),
                  ],
                  stops: const [0.0, 0.25, 0.55, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Foreground Content with Scroll support
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minH = constraints.hasBoundedHeight
                    ? (constraints.maxHeight - 32).clamp(0.0, double.infinity)
                    : 0.0;
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 460,
                        minHeight: minH,
                      ),
                      child: IntrinsicHeight(

                        child: Column(
                          children: [
                            // Top Header: Logo + Brand Name + Environment Badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141F30).withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE5B869).withValues(alpha: 0.7),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE5B869).withValues(alpha: 0.25),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.spa_rounded,
                                    color: Color(0xFFE5B869),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'TIÊN LỘ',
                                        style: TextStyle(
                                          color: Color(0xFFFDE68A),
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                      Text(
                                        'BIẾN CUỘC SỐNG THÀNH CUỘC PHIÊU LƯU',
                                        style: TextStyle(
                                          color: Color(0xFFD4AF37),
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Interactive Environment Chip
                                InkWell(
                                  onTap: _showEnvironmentSelectorDialog,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: ApiConstants.isLocal
                                          ? const Color(0xFF065F46).withValues(alpha: 0.4)
                                          : const Color(0xFF0369A1).withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: ApiConstants.isLocal
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF38BDF8),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          ApiConstants.isLocal
                                              ? Icons.dns_rounded
                                              : Icons.cloud_done_rounded,
                                          size: 13,
                                          color: ApiConstants.isLocal
                                              ? const Color(0xFF34D399)
                                              : const Color(0xFF7DD3FC),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          ApiConstants.isLocal ? 'Local' : 'Prod',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: ApiConstants.isLocal
                                              ? const Color(0xFF6EE7B7)
                                              : const Color(0xFFBAE6FD),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 14,
                                          color: Colors.white70,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Bug Report Button
                                InkWell(
                                  onTap: () => showBugReportDialog(
                                    context,
                                    screenName: 'Màn hình Đăng nhập',
                                    initialCategory: 'LOGIN',
                                    initialError: _errorMessage,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.55),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.bug_report_rounded,
                                          size: 13,
                                          color: Color(0xFFF87171),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Báo lỗi',
                                          style: TextStyle(
                                            color: Color(0xFFFCA5A5),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(flex: 3),

                            // Celestial Center Emblem with Golden Glow
                            Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0F1E33).withValues(alpha: 0.4),
                                border: Border.all(
                                  color: const Color(0xFFE5B869).withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE5B869).withValues(alpha: 0.2),
                                    blurRadius: 28,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF26374D), Color(0xFF111A29)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFFF3C766),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE5B869).withValues(alpha: 0.3),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: Color(0xFFFFD572),
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Overline Tagline
                            const Text(
                              'CUỘC ĐỜI LÀ MỘT TRÒ CHƠI',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFE8B95E),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.8,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Main Heading
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFFFFFFF),
                                  Color(0xFFFFF1C5),
                                  Color(0xFFE8B95E),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ).createShader(bounds),
                              child: const Text(
                                'SẴN SÀNG NHẬP VAI?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Subtitle
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Biến mục tiêu thật thành nhiệm vụ, nâng cấp nhân vật bằng từng hành động và nhìn thấy chính xác bạn đang tiến bộ thế nào.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFCBD5E1).withValues(alpha: 0.9),
                                  fontSize: 12.5,
                                  height: 1.45,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Error Banner if needed
                            if (_errorMessage != null) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7F1D1D).withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFEF4444)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Icon(Icons.error_outline_rounded,
                                              color: Color(0xFFFCA5A5), size: 18),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(
                                              color: Color(0xFFFEE2E2),
                                              fontSize: 12,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_isPlatformError) ...[
                                      const SizedBox(height: 10),
                                      ElevatedButton.icon(
                                        onPressed: _isLoading ? null : () => _handleDemoSignIn(),
                                        icon: const Icon(Icons.bolt_rounded, size: 16),
                                        label: const Text(
                                          'Vào Ngay Bằng Local Dev (Mạnh Ngô)',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFD97706),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      onPressed: () => showBugReportDialog(
                                        context,
                                        screenName: 'Màn hình Đăng nhập (Sự cố xác thực)',
                                        initialCategory: 'LOGIN',
                                        initialError: _errorMessage,
                                        initialTitle: 'Lỗi đăng nhập: ${_errorMessage?.split('\n').first}',
                                      ),
                                      icon: const Icon(Icons.mark_email_read_rounded, size: 15, color: Color(0xFFFCA5A5)),
                                      label: const Text(
                                        'Gửi Chi Tiết Lỗi Này Tới Gmail Admin',
                                        style: TextStyle(
                                          color: Color(0xFFFEE2E2),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFFF87171), width: 1.1),
                                        backgroundColor: const Color(0xFF450A0A).withValues(alpha: 0.5),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Primary CTA: "Tạo nhân vật với Google"
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: _isLoading ? null : _handleGoogleSignIn,
                                borderRadius: BorderRadius.circular(16),
                                child: Ink(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFF6CE70),
                                        Color(0xFFE5A93C),
                                        Color(0xFFCE8720),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE5A93C).withValues(alpha: 0.45),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: _isLoading
                                      ? const Center(
                                          child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Color(0xFF1E1404),
                                            ),
                                          ),
                                        )
                                      : Row(
                                          children: [
                                            // Google Icon Container
                                            Container(
                                              width: 32,
                                              height: 32,
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                              child: Image.asset(
                                                'assets/images/google_icon.png',
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    const Icon(
                                                  Icons.account_circle,
                                                  color: Color(0xFF4285F4),
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            const Expanded(
                                              child: Text(
                                                'Tạo nhân vật với Google',
                                                style: TextStyle(
                                                  color: Color(0xFF1E1404),
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Color(0xFF1E1404),
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Secondary Feature Card: "Tiến trình được đồng bộ"
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F1E2E).withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF0369A1).withValues(alpha: 0.3),
                                      border: Border.all(
                                        color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.shield_outlined,
                                      color: Color(0xFF38BDF8),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tiến trình được đồng bộ',
                                          style: TextStyle(
                                            color: Color(0xFFF1F5F9),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Nhiệm vụ, chỉ số và hành trình của bạn luôn được lưu an toàn.',
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Local Dev Mode Testing Section
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141F30).withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE5B869).withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.developer_mode_rounded,
                                        size: 15,
                                        color: Color(0xFFE5B869),
                                      ),
                                      const SizedBox(width: 6),
                                      const Expanded(
                                        child: Text(
                                          'TEST LOCAL DEV',
                                          style: TextStyle(
                                            color: Color(0xFFE5B869),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.6,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        ApiConstants.isLocal ? '⚡ Local' : '☁️ Cloud',
                                        style: TextStyle(
                                          color: ApiConstants.isLocal
                                              ? const Color(0xFF34D399)
                                              : const Color(0xFF38BDF8),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : () => _handleDemoSignIn(
                                                    uid: 'demo-google-uid-123456',
                                                    displayName: 'Mạnh Ngô (Dev)',
                                                    email: 'manh.ngo@tienlo.app',
                                                  ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1E293B),
                                            foregroundColor: const Color(0xFFFDE68A),
                                            side: const BorderSide(color: Color(0xFFE5B869), width: 0.8),
                                            padding: const EdgeInsets.symmetric(vertical: 9),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text(
                                            '👤 Mạnh Ngô',
                                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : () => _handleDemoSignIn(
                                                    uid: 'demo-user-tanthu',
                                                    displayName: 'Tân Thủ Tiên Nhân',
                                                    email: 'tanthu@tienlo.app',
                                                  ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1E293B),
                                            foregroundColor: const Color(0xFF93C5FD),
                                            side: const BorderSide(color: Color(0xFF38BDF8), width: 0.8),
                                            padding: const EdgeInsets.symmetric(vertical: 9),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text(
                                            '⚔️ Tân Thủ',
                                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton.filledTonal(
                                        onPressed: _isLoading ? null : _showCustomDevAccountDialog,
                                        icon: const Icon(Icons.add_rounded, size: 18),
                                        tooltip: 'Tùy chỉnh nhân vật test...',
                                        style: IconButton.styleFrom(
                                          backgroundColor: const Color(0xFF334155),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(flex: 1),
                            const SizedBox(height: 10),

                            // Footer Terms & Privacy (Wrapping safely without flex overflow)
                            Text.rich(
                              TextSpan(
                                text: 'Bằng việc tiếp tục, bạn đồng ý với ',
                                style: TextStyle(
                                  color: const Color(0xFF94A3B8).withValues(alpha: 0.8),
                                  fontSize: 11,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Điều khoản',
                                    style: TextStyle(
                                      color: Color(0xFFE5B869),
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFFE5B869),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: ' và '),
                                  TextSpan(
                                    text: 'Chính sách bảo mật',
                                    style: TextStyle(
                                      color: Color(0xFFE5B869),
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFFE5B869),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: '.'),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            TextButton.icon(
                              onPressed: () => showBugReportDialog(
                                context,
                                screenName: 'Màn hình Đăng nhập',
                                initialCategory: 'LOGIN',
                                initialError: _errorMessage,
                              ),
                              icon: const Icon(Icons.help_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                              label: const Text(
                                'Gặp sự cố? Báo lỗi trực tiếp tới Admin qua Gmail',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
