import 'package:flutter/material.dart';
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

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authRepository.signInWithGoogle();
      widget.onLoginSuccess(user);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDemoSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authRepository.signInWithDemo();
      widget.onLoginSuccess(user);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 460,
                        minHeight: constraints.maxHeight - 32,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // Top Header: Logo + Brand Name
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
                                const Column(
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
                                    ),
                                  ],
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
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7F1D1D).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFEF4444)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        color: Color(0xFFFCA5A5), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Color(0xFFFEE2E2),
                                          fontSize: 12,
                                        ),
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

                            // Dev Demo Mode Button (Convenient for development/instant testing)
                            TextButton.icon(
                              onPressed: _isLoading ? null : _handleDemoSignIn,
                              icon: const Icon(
                                Icons.bolt_rounded,
                                size: 16,
                                color: Color(0xFFE5B869),
                              ),
                              label: const Text(
                                'Khám phá thử nghiệm (Chế độ Dev Demo)',
                                style: TextStyle(
                                  color: Color(0xFFE5B869),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
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
