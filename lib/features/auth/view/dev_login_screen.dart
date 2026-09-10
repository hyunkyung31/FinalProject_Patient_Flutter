import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../repository/auth_repository.dart';

import '../../record_link/view/patient_link_required_screen.dart';

class DevLoginScreen extends StatefulWidget {
  const DevLoginScreen({super.key, this.repository, this.onAuthenticated});
  final AuthRepository? repository;
  final Future<void> Function()? onAuthenticated;

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

  Future<void> _login({required bool linkedPatient}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isSuccess = false;
      _message = null;
    });

    try {
      await _authRepository.loginForDevelopment(linkedPatient: linkedPatient);

      if (!mounted) return;
      if (widget.onAuthenticated != null) {
        await widget.onAuthenticated!();
        return;
      }

      setState(() {
        _isSuccess = true;
        _message = '로그인에 성공했어요.\n다음 단계에서 병원기록 연결 상태를 확인할게요.';
      });
    } on DioException catch (error) {
      if (!mounted) return;

      final statusCode = error.response?.statusCode;

      setState(() {
        _message = statusCode == null
            ? '서버에 연결하지 못했어요. 인터넷 연결을 확인하고 다시 시도해 주세요.'
            : '로그인 요청에 실패했어요. (응답 코드: $statusCode)';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _message = '로그인 처리 또는 토큰 저장에 실패했어요. 다시 시도해 주세요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(body: Center(child: Text('로그인 기능을 준비 중이에요.')));
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'BOMI',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '개발용 로그인',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'API 연결을 확인할 테스트 계정을 선택해 주세요.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _isLoading ? null : _loginWithKakao,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE500),
                      foregroundColor: const Color(0xFF191919),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('카카오 로그인/회원가입'),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading
                        ? null
                        : () => _login(linkedPatient: true),
                    child: const Text('연결된 환자 계정으로 로그인'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _login(linkedPatient: false),
                    child: const Text('미연결 환자 계정으로 로그인'),
                  ),
                  if (_isLoading) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (_message != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isSuccess
                            ? const Color(0xFF1E3A8A)
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
