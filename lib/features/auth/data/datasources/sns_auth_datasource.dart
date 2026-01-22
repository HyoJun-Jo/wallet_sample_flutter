import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/sns_auth_result_model.dart';

abstract class SnsAuthDataSource {
  Future<SnsAuthResultModel?> signInWithGoogle();
  Future<SnsAuthResultModel?> signInWithApple();
  Future<SnsAuthResultModel?> signInWithKakao();
  Future<void> signOut();
  bool get isAppleSignInAvailable;
}

class SnsAuthDataSourceImpl implements SnsAuthDataSource {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: AppConstants.googleServerClientId,
  );

  @override
  bool get isAppleSignInAvailable => Platform.isIOS;

  @override
  Future<SnsAuthResultModel?> signInWithGoogle() async {
    await _googleSignIn.signOut();

    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final authentication = await account.authentication;
    final idToken = authentication.idToken;
    if (idToken == null) return null;

    return SnsAuthResultModel(token: idToken, email: account.email);
  }

  @override
  Future<SnsAuthResultModel?> signInWithApple() async {
    if (!Platform.isIOS) {
      throw UnsupportedError('Apple Sign-In is only available on iOS');
    }

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

    return SnsAuthResultModel(token: identityToken, email: credential.email);
  }

  @override
  Future<SnsAuthResultModel?> signInWithKakao() async {
    final isInstalled = await isKakaoTalkInstalled();

    OAuthToken token;
    if (isInstalled) {
      token = await UserApi.instance.loginWithKakaoTalk();
    } else {
      token = await UserApi.instance.loginWithKakaoAccount();
    }

    String? email;
    try {
      final user = await UserApi.instance.me();
      email = user.kakaoAccount?.email;
    } catch (_) {}

    return SnsAuthResultModel(token: token.accessToken, email: email);
  }

  @override
  Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      try {
        await UserApi.instance.logout();
      } catch (_) {}
    } catch (_) {}
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
