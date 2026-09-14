import 'package:google_sign_in/google_sign_in.dart';

// 개발 화면에서만 사용하는 진단 문구입니다. 예외 전체나 토큰은 출력하지 않습니다.
String googleLoginDiagnostic(GoogleSignInException error) {
  final description = redactGoogleDiagnostic(error.description ?? '');
  return '오류 코드: ${error.code.name}\n상세: ${description.isEmpty ? 'SDK가 상세 설명을 제공하지 않았어요.' : description}';
}

String redactGoogleDiagnostic(String value) {
  var description = value.trim();
  description = description
      .replaceAll(RegExp(r'[\w.+-]+@[\w.-]+'), '[이메일 숨김]')
      .replaceAll(RegExp(r'Bearer\s+\S+', caseSensitive: false), '[토큰 숨김]')
      .replaceAll(RegExp(r'[A-Za-z0-9_\-./+=]{32,}'), '[식별값 숨김]');
  if (description.length > 600) description = description.substring(0, 600);
  return description;
}

class GoogleLoginService {
  static Future<void>? _initialization;

  Future<String> authenticate() async {
    // Android의 google-services.json에 등록된 웹 OAuth Client ID를 사용합니다.
    await (_initialization ??= GoogleSignIn.instance.initialize(
      serverClientId:
          '491343141234-tp3gm9gjl5embki9g67a5hilekp5n1iq.apps.googleusercontent.com',
    ));
    // 기존 Google 로그인 상태를 정리하고 계정 선택으로 새 인증을 시작합니다.
    await GoogleSignIn.instance.signOut();
    final account = await GoogleSignIn.instance.authenticate();
    final token = account.authentication.idToken;
    if (token == null || token.trim().isEmpty) {
      throw const FormatException('구글 ID 토큰을 받지 못했습니다.');
    }
    return token;
  }
}
