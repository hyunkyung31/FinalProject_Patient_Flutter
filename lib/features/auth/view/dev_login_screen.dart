import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../service/google_login_service.dart';
import 'session_gate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../repository/auth_repository.dart';

import '../../record_link/view/patient_link_required_screen.dart';

class DevLoginScreen extends StatefulWidget {
  const DevLoginScreen({
    super.key,
    this.repository,
    this.onAuthenticated,
    this.googleAuthenticate,
  });
  final AuthRepository? repository;
  final Future<void> Function()? onAuthenticated;
  final Future<String> Function()? googleAuthenticate;

  @override
  State<DevLoginScreen> createState() => _DevLoginScreenState();
}

class _DevLoginScreenState extends State<DevLoginScreen> {
  final _apiClient = ApiClient();

  late final AuthRepository _authRepository;

  bool _isLoading = false;
  bool _isSuccess = false;
  String? _message;

  @override
  void initState() {
    super.initState();

    _authRepository =
        widget.repository ??
        AuthRepository(apiClient: _apiClient, tokenStorage: TokenStorage());
  }

  Future<void> _loginWithKakao() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isSuccess = false;
      _message = null;
    });

    try {
      final useKakaoTalk = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '로그인 방법을 선택해 주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500),
                    foregroundColor: const Color(0xFF191919),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.pop(sheetContext, true),
                  child: const Text('카카오톡으로 로그인'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(sheetContext, false),
                  child: const Text('카카오계정으로 로그인'),
                ),
              ],
            ),
          ),
        ),
      );
      if (!mounted) return;
      if (useKakaoTalk == null) {
        setState(() => _message = '카카오 로그인을 취소했어요.');
        return;
      }

      final talkInstalled = useKakaoTalk && await isKakaoTalkInstalled();
      if (!mounted) return;

      final token = talkInstalled
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();
      if (!mounted) return;

      final idToken = token.idToken;
      if (idToken == null || idToken.trim().isEmpty) {
        setState(() {
          _message =
              '카카오 인증은 완료됐지만 ID 토큰이 없어요.\n'
              '카카오 Developers에서 OpenID Connect 설정을 확인해 주세요.';
        });
        return;
      }

      final result = await _authRepository.loginWithKakao(idToken);
      if (!mounted) return;
      if (widget.onAuthenticated != null) {
        await widget.onAuthenticated!();
        return;
      }

      if (!result.hasPatientLink) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const PatientLinkRequiredScreen(),
          ),
        );

        if (!mounted) return;
      }
      setState(() {
        _isSuccess = true;
        final accountMessage = result.isNewAccount
            ? '카카오 회원가입과 로그인에 성공했어요.'
            : '카카오 로그인에 성공했어요.';
        final linkMessage = result.hasPatientLink
            ? '연결된 병원기록이 있어요.'
            : '아직 연결된 병원기록이 없어요.';
        _message = '$accountMessage\n$linkMessage';
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        final status = error.response?.statusCode;
        _message = status == null
            ? '로그인 서버에 연결하지 못했어요. 다시 시도해 주세요.'
            : '서버 로그인에 실패했어요. (응답 코드: $status)';
      });
    } on KakaoClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.reason == ClientErrorCause.cancelled
            ? '카카오 로그인을 취소했어요.'
            : '카카오 로그인을 진행하지 못했어요. 다시 시도해 주세요.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = '카카오 로그인 처리 또는 토큰 저장에 실패했어요. 다시 시도해 주세요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _isSuccess = false;
      _message = null;
    });
    try {
      final idToken =
          await (widget.googleAuthenticate ??
              GoogleLoginService().authenticate)();
      if (!mounted) return;
      await _authRepository.loginWithGoogle(idToken);
      if (!mounted) return;
      if (widget.onAuthenticated != null) {
        await widget.onAuthenticated!();
      } else {
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute(builder: (_) => const SessionGate()),
        );
      }
    } on GoogleSignInException catch (e) {
      if (!mounted) return;
      setState(
        () => _message = switch (e.code) {
          GoogleSignInExceptionCode.canceled => '구글 로그인을 취소했어요.',
          GoogleSignInExceptionCode.clientConfigurationError =>
            '구글 로그인 설정을 확인해 주세요. OAuth 클라이언트와 앱 서명 설정이 필요해요.',
          _ =>
            kDebugMode
                ? '구글 인증을 진행하지 못했어요.\n${googleLoginDiagnostic(e)}'
                : '구글 인증을 진행하지 못했어요. 다시 시도해 주세요.',
        },
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final details = kDebugMode && data is Map
          ? [
              for (final field in ['code', 'detail'])
                if (data[field] is String)
                  '$field: ${redactGoogleDiagnostic(data[field] as String)}',
            ].join('\n')
          : '';
      setState(
        () => _message = e.response == null
            ? '로그인 서버에 연결하지 못했어요. 다시 시도해 주세요.'
            : '구글 서버 로그인에 실패했어요. (응답 코드: ${e.response?.statusCode})${details.isEmpty ? '' : '\n$details'}',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = '구글 로그인 처리 또는 토큰 저장에 실패했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _LoginBackdropPainter(dark: isDark)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 120, 45, 45),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/bomi/dugn_logo.png',
                        width: 218,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Text(
                          'DUGN',
                          style: textTheme.displaySmall?.copyWith(
                            color: const Color(0xFF12316A),
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 82),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '\uB0B4 '),
                            TextSpan(
                              text: '\uC2EC\uD608\uAD00 \uAC74\uAC15',
                              style: const TextStyle(color: Color(0xFFF05270)),
                            ),
                            TextSpan(text: '\uC744 \uD55C\uACF3\uC5D0\uC11C'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF153D87),
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '\uAC80\uC0AC \uACB0\uACFC\uBD80\uD130 \uC9C4\uB8CC \uC608\uC57D, \uAC74\uAC15\uAD00\uB9AC\uAE4C\uC9C0\n\uC548\uC804\uD558\uACE0 \uD3B8\uB9AC\uD558\uAC8C \uD655\uC778\uD558\uC138\uC694.',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF65748D),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 96),
                      const _LoginDivider(
                        label:
                            '\uAC04\uD3B8\uD558\uAC8C \uC2DC\uC791\uD558\uC138\uC694',
                      ),
                      const SizedBox(height: 26),
                      _SocialLoginButton(
                        label:
                            '\uCE74\uCE74\uC624\uB85C \uACC4\uC18D\uD558\uAE30',
                        backgroundColor: const Color(0xFFFFE500),
                        foregroundColor: const Color(0xFF241A00),
                        icon: const Icon(Icons.chat_bubble_rounded, size: 25),
                        onPressed: _isLoading ? null : _loginWithKakao,
                        loading: _isLoading,
                      ),
                      const SizedBox(height: 16),
                      _SocialLoginButton(
                        label: 'Google\uB85C \uACC4\uC18D\uD558\uAE30',
                        backgroundColor: Colors.white.withValues(alpha: 0.85),
                        foregroundColor: const Color(0xFF26374F),
                        borderColor: const Color(0xFFD6DCE6),
                        icon: const Text(
                          'G',
                          style: TextStyle(
                            color: Color(0xFF4285F4),
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onPressed: _isLoading ? null : _loginWithGoogle,
                        loading: _isLoading,
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 22),
                        Text(
                          _message!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: _isSuccess
                                ? const Color(0xFF16734A)
                                : const Color(0xFFB3261E),
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 55),
                      Text(
                        '\uCC98\uC74C \uC774\uC6A9\uD558\uC2DC\uB098\uC694?\n\uB85C\uADF8\uC778 \uD6C4 \uBCF8\uC778\uC778\uC99D\uC744 \uD1B5\uD574 \uC758\uB8CC\uAE30\uB85D\uC744 \uC5F0\uACB0\uD560 \uC218 \uC788\uC5B4\uC694.',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF65748D),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 64),
                      Text(
                        '\uC774\uC6A9\uC57D\uAD00   \u00B7   \uAC1C\uC778\uC815\uBCF4 \uCC98\uB9AC\uBC29\uCE68',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF71809A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x550B1D3A),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoginDivider extends StatelessWidget {
  const _LoginDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      children: [
        Expanded(child: Divider(color: color, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: color, height: 1)),
      ],
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    required this.loading,
    this.borderColor,
  });

  final String label;
  final Widget icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(width: 30, child: Center(child: icon)),
              Expanded(
                child: Center(
                  child: loading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: foregroundColor,
                          ),
                        )
                      : Text(
                          label,
                          style: TextStyle(
                            color: foregroundColor,
                            fontSize: 17,
                            letterSpacing: -0.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginBackdropPainter extends CustomPainter {
  const _LoginBackdropPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final blue = dark ? const Color(0xFF1A355B) : const Color(0xFFE6F3FF);
    final pink = dark ? const Color(0xFF402B42) : const Color(0xFFFFEAF0);

    paint.color = blue.withValues(alpha: dark ? 0.50 : 0.80);
    canvas.drawCircle(
      Offset(-size.width * 0.08, size.height * 0.08),
      size.width * 0.35,
      paint,
    );
    paint.color = pink.withValues(alpha: dark ? 0.42 : 0.82);
    canvas.drawCircle(
      Offset(size.width * 1.04, size.height * 0.19),
      size.width * 0.18,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.03, size.height * 0.99),
      size.width * 0.28,
      paint,
    );
    paint.color = blue.withValues(alpha: dark ? 0.42 : 0.74);
    canvas.drawCircle(
      Offset(size.width * 1.06, size.height * 0.90),
      size.width * 0.24,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LoginBackdropPainter oldDelegate) =>
      oldDelegate.dark != dark;
}
