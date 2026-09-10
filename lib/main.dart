import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await KakaoSdk.init(
    nativeAppKey: '188c6aa577b570b211269ff40f2fafa1',
  );

  if (kDebugMode) {
    final keyHash = KakaoSdk.platformInfo.origin;
    debugPrint('KAKAO_KEY_HASH: $keyHash');
  }

  runApp(const MyApp());
}