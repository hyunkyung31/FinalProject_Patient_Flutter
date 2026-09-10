import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../home/view/dashboard_screen.dart';
import '../../record_link/view/patient_link_required_screen.dart';
import '../repository/auth_repository.dart';
import 'dev_login_screen.dart';

enum _SessionPage { loading, login, linked, unlinked, error }

class SessionGate extends StatefulWidget {
  const SessionGate({super.key, this.repository});
  final AuthRepository? repository;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  final _client = ApiClient();
  late final _repository =
      widget.repository ??
      AuthRepository(apiClient: _client, tokenStorage: TokenStorage());
  _SessionPage _page = _SessionPage.loading;
  bool _authenticated = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _page = _SessionPage.loading);
    try {
      if (!_authenticated) {
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
    setState(() {
      _error = message;
      _page = _SessionPage.error;
    });
  }

  Future<void> _onAuthenticated() async {
    _authenticated = true;
    await _load();
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_page) {
      case _SessionPage.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _SessionPage.login:
        return DevLoginScreen(
          repository: _repository,
          onAuthenticated: _onAuthenticated,
        );
      case _SessionPage.unlinked:
        return PatientLinkRequiredScreen(onRefresh: _load);
      case _SessionPage.linked:
        return const Column(
          children: [
            SafeArea(
              bottom: false,
              child: Material(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('병원기록 연결 완료 · 아래 대시보드는 예시 데이터입니다.'),
                ),
              ),
            ),
            Expanded(child: DashboardScreen()),
          ],
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
                    FilledButton(onPressed: _load, child: const Text('다시 시도')),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }
}
