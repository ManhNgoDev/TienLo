import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthResult {
  final String idToken;
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  AuthResult({
    required this.idToken,
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });
}

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '827303035345-tdskj058ijr5qjk2iha54ov2jt9ps6vq.apps.googleusercontent.com',
  );


  /// Đăng nhập bằng Google thực tế thông qua GoogleSignIn SDK
  Future<AuthResult?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // Người dùng hủy đăng nhập
        return null;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      return AuthResult(
        idToken: idToken ?? 'demo-token-${account.id}',
        uid: account.id,
        email: account.email,
        displayName: account.displayName ?? 'Người dùng Google',
        photoUrl: account.photoUrl,
      );
    } catch (e) {
      debugPrint('Lỗi đăng nhập Google: $e');
      rethrow;
    }
  }

  /// Đăng nhập chế độ giả lập (Dành cho Dev khi chưa thiết lập Google Cloud OAuth / Firebase)
  Future<AuthResult> signInWithDemo() async {
    // Giả lập network delay nhẹ
    await Future.delayed(const Duration(milliseconds: 600));

    return AuthResult(
      idToken: 'demo-token-${DateTime.now().millisecondsSinceEpoch}',
      uid: 'demo-google-uid-123456',
      email: 'manh.ngo@tienlo.app',
      displayName: 'Mạnh Ngô (Dev)',
      photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    );
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
