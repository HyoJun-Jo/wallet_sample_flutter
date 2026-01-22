import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  final envFile = AppConfig.isDev ? '.env.dev' : '.env.prod';
  await dotenv.load(fileName: envFile);

  // Initialize Kakao SDK
  final kakaoAppKey = dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';
  if (kakaoAppKey.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: kakaoAppKey);
  }

  // Initialize dependency injection
  await di.init();

  runApp(const WalletSampleApp());
}
