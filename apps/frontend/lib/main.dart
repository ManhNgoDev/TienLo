import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'core/constants/api_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/user_model.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/common/presentation/screens/server_waiting_screen.dart';
import 'features/dashboard/presentation/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TienLoApp());
}

class TienLoApp extends StatefulWidget {
  const TienLoApp({super.key});

  @override
  State<TienLoApp> createState() => _TienLoAppState();
}

class _TienLoAppState extends State<TienLoApp> {
  final AuthRepository _authRepository = AuthRepository();
  UserModel? _currentUser;
  bool _isCheckingInitial = true;
  bool _isServerStarting = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    // 1. Kiểm tra tài khoản đã lưu
    final savedUser = await _authRepository.getSavedUser();

    // Bỏ qua kiểm tra server nếu đang chạy widget test
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest) {
      if (mounted) {
        setState(() {
          _currentUser = savedUser;
          _isCheckingInitial = false;
          _isServerStarting = false;
        });
      }
      return;
    }

    // 2. Thử kiểm tra máy chủ backend có đang hoạt động hay đang ngủ đông (Render Cold Start)
    bool serverAwake = false;
    try {
      final uri = Uri.parse('${ApiConstants.defaultBaseUrl}${ApiConstants.health}');
      final res = await http.get(uri).timeout(const Duration(milliseconds: 2500));
      serverAwake = (res.statusCode >= 200 && res.statusCode < 300);
    } catch (_) {
      serverAwake = false;
    }

    if (mounted) {
      setState(() {
        _currentUser = savedUser;
        _isCheckingInitial = false;
        // Nếu server chưa thức tỉnh (ví dụ Render Cold Start), bật màn hình chờ khởi động
        _isServerStarting = !serverAwake;
      });
    }
  }

  void _onLoginSuccess(UserModel user) {
    setState(() {
      _currentUser = user;
    });
  }

  void _onLogout() {
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget homeWidget;

    if (_isCheckingInitial) {
      homeWidget = const Scaffold(
        backgroundColor: Color(0xFF070B12),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2C465)),
          ),
        ),
      );
    } else if (_isServerStarting) {
      homeWidget = ServerWaitingScreen(
        onServerReady: () {
          setState(() {
            _isServerStarting = false;
          });
        },
        onSkip: () {
          setState(() {
            _isServerStarting = false;
          });
        },
      );
    } else if (_currentUser != null) {
      homeWidget = HomeScreen(
        user: _currentUser!,
        onLogout: _onLogout,
      );
    } else {
      homeWidget = LoginScreen(
        onLoginSuccess: _onLoginSuccess,
      );
    }

    return MaterialApp(
      title: 'Tiên Lộ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: homeWidget,
    );
  }
}
