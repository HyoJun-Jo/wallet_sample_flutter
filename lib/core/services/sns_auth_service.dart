import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../constants/app_constants.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// SNS Authentication Result containing token and email
class SnsAuthResult {
  final String token;
  final String? email;

  const SnsAuthResult({required this.token, this.email});
}

/// SNS Authentication Service Interface
abstract class SnsAuthService {
  /// Sign in with Google and return ID Token + Email
  Future<SnsAuthResult?> signInWithGoogle();

  /// Sign in with Apple and return Identity Token + Email (iOS only)
  Future<SnsAuthResult?> signInWithApple();

  /// Sign in with Kakao and return Access Token + Email
  Future<SnsAuthResult?> signInWithKakao();

  /// Sign out from all SNS providers
  Future<void> signOut();

  /// Check if Apple Sign-In is available (iOS only)
  bool get isAppleSignInAvailable;
}

/// SNS Authentication Service Implementation
class SnsAuthServiceImpl implements SnsAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: AppConstants.googleServerClientId,
  );

  @override
  bool get isAppleSignInAvailable => Platform.isIOS;

  @override
  Future<SnsAuthResult?> signInWithGoogle() async {
    try {
      // Sign out first to ensure account picker is shown
      await _googleSignIn.signOut();

      final account = await _googleSignIn.signIn();
      if (account == null) {
        return null;
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null) return null;

      return SnsAuthResult(token: idToken, email: account.email);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<SnsAuthResult?> signInWithApple() async {
    if (!Platform.isIOS) {
      throw UnsupportedError('Apple Sign-In is only available on iOS');
    }

    try {
      // Generate nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) return null;

      return SnsAuthResult(token: identityToken, email: credential.email);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<SnsAuthResult?> signInWithKakao() async {
    try {
      final isInstalled = await isKakaoTalkInstalled();

      OAuthToken token;
      if (isInstalled) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      // Fetch user info to get email
      String? email;
      try {
        final user = await UserApi.instance.me();
        email = user.kakaoAccount?.email;
      } catch (_) {
        // Ignore if failed to get user info
      }

      return SnsAuthResult(token: token.accessToken, email: email);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Google sign out
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Kakao sign out
      try {
        await UserApi.instance.logout();
      } catch (_) {
        // Ignore if not logged in
      }
    } catch (e) {
      // Ignore sign out errors
    }
  }

  /// Generate a random nonce string
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Generate SHA256 hash of a string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
