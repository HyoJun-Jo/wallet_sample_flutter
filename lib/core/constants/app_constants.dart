import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application-wide constants loaded from environment files
class AppConstants {
  AppConstants._();

  static const String appName = 'Wallet Base';
  static const String appVersion = '1.0.0';

  /// API Base URL - WaaS API
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';

  /// Client ID
  static String get clientId => dotenv.env['CLIENT_ID'] ?? '';

  /// Client Secret
  static String get clientSecret => dotenv.env['CLIENT_SECRET'] ?? '';

  /// Google Server Client ID (Web)
  static String get googleServerClientId => dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';

  /// Kakao Native App Key
  static String get kakaoNativeAppKey => dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';

  /// Environment
  static bool get isDev => dotenv.env['ENV'] == 'dev';

  /// BTC Network (testnet for dev, mainnet for prod)
  static String get btcNetwork => isDev ? 'testnet' : 'mainnet';

  /// Token Audience
  static const String tokenAudience = 'https://mw.myabcwallet.com';

  /// User Agent Platform
  static String get userAgentPlatform {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iPhone';
    return 'unknown';
  }
}
