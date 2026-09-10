class AuthTokens {
  const AuthTokens({required this.access, required this.refresh});

  final String access;
  final String refresh;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final access = json['access'];
    final refresh = json['refresh'];

    if (access is! String ||
        access.trim().isEmpty ||
        refresh is! String ||
        refresh.trim().isEmpty) {
      throw const FormatException("로그인 응답에 유효한 토근이 없습니다.");
    }
    return AuthTokens(access: access, refresh: refresh);
  }
}
