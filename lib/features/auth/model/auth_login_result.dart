import 'auth_tokens.dart';

class AuthLoginResult {
  const AuthLoginResult({
    required this.tokens,
    required this.isNewAccount,
    required this.hasPatientLink,
  });

  final AuthTokens tokens;
  final bool isNewAccount;
  final bool hasPatientLink;

  factory AuthLoginResult.fromJson(Map<String, dynamic> json) {
    final isNew = json['is_new_account'];
    if (isNew is! bool || !json.containsKey('patient_link')) {
      throw const FormatException('로그인 응답의 계정 정보가 올바르지 않습니다.');
    }
    final link = json['patient_link'];
    if (link != null && link is! Map) {
      throw const FormatException('로그인 응답의 연결 정보가 올바르지 않습니다.');
    }
    return AuthLoginResult(
      tokens: AuthTokens.fromJson(json),
      isNewAccount: isNew,
      hasPatientLink: link != null,
    );
  }
}
