import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../home/view/dashboard_screen.dart';
import '../repository/auth_repository.dart';
import '../service/biometric_auth_service.dart';
import 'dev_login_screen.dart';
import '../../reservation/repository/reservation_repository.dart';
import '../../chatbot/repository/chatbot_repository.dart';
import '../../chatbot/view/chatbot_conversation_list_screen.dart';
import '../../chatbot/widgets/chatbot_overlay_host.dart';

enum _SessionPage { loading, biometric, login, linked, unlinked, error }

class SessionGate extends StatefulWidget {
  const SessionGate({super.key, this.repository, this.biometricAuthenticator});
  final AuthRepository? repository;
  final BiometricAuthenticator? biometricAuthenticator;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  final _client = ApiClient();
  late final _reservationRepository = ReservationRepository(_client);
  late final _chatbotRepository = ChatbotRepository(_client);
  late final _repository =
      widget.repository ??
      AuthRepository(apiClient: _client, tokenStorage: TokenStorage());
  late final _biometricAuthenticator =
      widget.biometricAuthenticator ?? BiometricAuthService();
  _SessionPage _page = _SessionPage.loading;
  bool _authenticated = false;
  String _error = '';
  bool _logoutBusy = false;
  bool _retryLogout = false;
  bool _biometricBusy = false;
  String? _biometricError;

  Future<void> _openChatbot() async {
    if (!mounted ||
        !_authenticated ||
        (_page != _SessionPage.linked && _page != _SessionPage.unlinked)) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ChatbotConversationListScreen(repository: _chatbotRepository),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    if (_logoutBusy) return;
    _logoutBusy = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃할까요?'),
        content: const Text('이 기기의 환자 앱에서 로그아웃합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    _logoutBusy = false;
    if (!mounted || confirmed != true) return;
    await _logout();
  }

  Future<void> _logout() async {
    if (_logoutBusy) return;
    _logoutBusy = true;
    _retryLogout = true;
    setState(() => _page = _SessionPage.loading);
    try {
      await _repository.logout();
      if (!mounted) return;
      _authenticated = false;
      _retryLogout = false;
      Navigator.of(context).popUntil((route) => route.isFirst);
      setState(() => _page = _SessionPage.login);
    } catch (_) {
      _showError('로그아웃을 완료하지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요.');
    } finally {
      _logoutBusy = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _unlockWithBiometrics() async {
    if (_biometricBusy) return;
    setState(() {
      _biometricBusy = true;
      _biometricError = null;
    });
    try {
      if (!await _biometricAuthenticator.authenticate()) {
        if (mounted) {
          setState(() => _biometricError = '생체 인증을 완료하지 못했어요. 다시 시도해 주세요.');
        }
        return;
      }
      _authenticated = await _repository.restoreSession();
      if (!_authenticated) {
        await _repository.clearSession();
        if (mounted) setState(() => _page = _SessionPage.login);
        return;
      }
      await _load();
    } catch (_) {
      if (mounted) {
        setState(
          () => _biometricError = '생체 인증 로그인에 실패했어요. 다른 로그인 방법을 사용해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _biometricBusy = false);
    }
  }

  Future<void> _offerBiometricLogin() async {
    if (await _repository.requiresBiometricLogin() ||
        !await _biometricAuthenticator.isAvailable() ||
        !mounted) {
      return;
    }
    final enable = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('생체 로그인 사용'),
        content: const Text('다음부터 지문 또는 얼굴 인증으로 빠르게 로그인할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('나중에'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('사용하기'),
          ),
        ],
      ),
    );
    if (!mounted || enable != true) return;
    if (await _biometricAuthenticator.authenticate()) {
      await _repository.setBiometricLoginEnabled(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생체 인증을 완료하지 못해 설정하지 않았어요.')),
      );
    }
  }

  Future<void> _load() async {
    ChatbotOverlayController.instance.deactivate();
    setState(() => _page = _SessionPage.loading);
    try {
      if (!_authenticated) {
        if (await _repository.requiresBiometricLogin()) {
          if (mounted) setState(() => _page = _SessionPage.biometric);
          return;
        }
        _authenticated = await _repository.restoreSession();
      }
      if (!mounted) return;
      if (!_authenticated) {
        setState(() => _page = _SessionPage.login);
        return;
      }
      final linked = await _repository.hasPatientLink();
      if (!mounted) return;
      setState(
        () => _page = linked ? _SessionPage.linked : _SessionPage.unlinked,
      );

      ChatbotOverlayController.instance.activate(_openChatbot);
    } on DioException catch (error) {
      if (!mounted) return;
      if (error.response?.statusCode == 401) {
        try {
          await _repository.clearSession();
          if (!mounted) return;
          _authenticated = false;
          setState(() => _page = _SessionPage.login);
        } catch (_) {
          _showError('로그인 정보를 정리하지 못했어요. 다시 시도해 주세요.');
        }
      } else {
        _showError('로그인 또는 병원기록 연결 상태를 확인하지 못했어요.\n연결 상태를 확인하고 다시 시도해 주세요.');
      }
    } catch (_) {
      _showError('로그인 정보를 불러오지 못했어요. 다시 시도해 주세요.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ChatbotOverlayController.instance.deactivate();
    setState(() {
      _error = message;
      _page = _SessionPage.error;
    });
  }

  Future<void> _onAuthenticated() async {
    _authenticated = true;
    await _offerBiometricLogin();
    if (mounted) await _load();
  }

  @override
  void dispose() {
    ChatbotOverlayController.instance.deactivate();
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_page) {
      case _SessionPage.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _SessionPage.biometric:
        return _BiometricLoginScreen(
          busy: _biometricBusy,
          error: _biometricError,
          onAuthenticate: _unlockWithBiometrics,
          onOtherLogin: () => setState(() => _page = _SessionPage.login),
        );
      case _SessionPage.login:
        return DevLoginScreen(
          repository: _repository,
          onAuthenticated: _onAuthenticated,
        );
      case _SessionPage.unlinked:
      case _SessionPage.linked:
        return DashboardScreen(
          patientLinked: _page == _SessionPage.linked,
          onRefreshLink: _load,
          reservationRepository: _reservationRepository,
          onLogout: _confirmLogout,
        );
      case _SessionPage.error:
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _retryLogout ? _logout : _load,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }
}

class _BiometricLoginScreen extends StatelessWidget {
  const _BiometricLoginScreen({
    required this.busy,
    required this.onAuthenticate,
    required this.onOtherLogin,
    this.error,
  });

  final bool busy;
  final VoidCallback onAuthenticate;
  final VoidCallback onOtherLogin;
  final String? error;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.fingerprint,
                  size: 72,
                  color: Color(0xFF1E3A8A),
                ),
                const SizedBox(height: 24),
                const Text(
                  '생체 인증으로 로그인',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  '등록된 지문 또는 얼굴로 환자 정보를 안전하게 확인해 주세요.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: busy ? null : onAuthenticate,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(busy ? '인증 중…' : '생체 인증하기'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: busy ? null : onOtherLogin,
                  child: const Text('다른 방법으로 로그인'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
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
