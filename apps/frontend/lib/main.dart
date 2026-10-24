import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/user_model.dart';
import 'features/auth/presentation/screens/login_screen.dart';
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
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    final savedUser = await _authRepository.getSavedUser();
    setState(() {
      _currentUser = savedUser;
      _isCheckingAuth = false;
    });
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
    return MaterialApp(
      title: 'TienLo App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isCheckingAuth
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : _currentUser != null
              ? HomeScreen(
                  user: _currentUser!,
                  onLogout: _onLogout,
                )
              : LoginScreen(
                  onLoginSuccess: _onLoginSuccess,
                ),
    );
  }
}
