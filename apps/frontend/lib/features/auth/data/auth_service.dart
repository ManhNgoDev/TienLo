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
  static const String envServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: envServerClientId.isNotEmpty ? envServerClientId : null,
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

  /// Đăng nhập chế độ giả lập (Dành cho Dev khi test local hoặc chưa thiết lập Firebase)
  Future<AuthResult> signInWithDemo({
    String uid = 'demo-google-uid-123456',
    String displayName = 'Mạnh Ngô (Dev)',
    String email = 'manh.ngo@tienlo.app',
    String? photoUrl,
  }) async {
    // Giả lập network delay nhẹ
    await Future.delayed(const Duration(milliseconds: 300));

    return AuthResult(
      idToken: 'demo-token-$uid',
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  Future<String?> getFreshIdToken() async {
    try {
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();
      if (account != null) {
        final auth = await account.authentication;
        if (auth.idToken != null && auth.idToken!.isNotEmpty) {
          return auth.idToken;
        }
      }
    } catch (e) {
      debugPrint('Lỗi tự động làm mới Google ID token: $e');
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
