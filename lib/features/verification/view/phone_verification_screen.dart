import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../reservation/model/booking_options.dart';
import '../../reservation/repository/reservation_repository.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key, required this.repository});

  final ReservationRepository repository;

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();

  String? _verificationId;
  String? _message;
  User? _firebaseUser;

  bool _sending = false;
  bool _verifying = false;
  bool _completed = false;

  // 이전 발송 요청에서 늦게 도착한 콜백을 구분합니다.
  int _requestId = 0;

  bool get _busy => _sending || _verifying;

  bool _isCurrent(int requestId) {
    return mounted && !_completed && requestId == _requestId;
  }

  Future<void> _sendCode() async {
    if (_busy || _completed) {
      return;
    }

    final phone = _phone.text.trim();

    if (!RegExp(r'^010\d{8}$').hasMatch(phone)) {
      setState(() {
        _message = '010으로 시작하는 휴대폰 번호 11자리를 입력해 주세요.';
      });
      return;
    }

    final requestId = ++_requestId;

    setState(() {
      _sending = true;
      _verificationId = null;
      _firebaseUser = null;
      _code.clear();
      _message = '인증번호를 요청하고 있어요.';
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        // 01012345678 → +821012345678
        phoneNumber: '+82${phone.substring(1)}',
        timeout: const Duration(seconds: 60),

        verificationCompleted: (credential) async {
          if (!_isCurrent(requestId)) {
            return;
          }

          await _completeFirebase(credential, requestId);
        },

        verificationFailed: (error) {
          if (!_isCurrent(requestId) || _verifying) {
            return;
          }

          setState(() {
            _sending = false;
            _message = _firebaseErrorMessage(error);
          });
        },

        codeSent: (verificationId, resendToken) {
          if (!_isCurrent(requestId) || _verifying) {
            return;
          }

          setState(() {
            _sending = false;
            _verificationId = verificationId;
            _message = '인증번호가 발송됐어요. 문자에 있는 6자리를 입력해 주세요.';
          });
        },

        codeAutoRetrievalTimeout: (verificationId) {
          if (!_isCurrent(requestId) || _verifying) {
            return;
          }

          setState(() {
            _sending = false;
            _verificationId = verificationId;
            _message = '자동 확인이 종료됐어요. 받은 인증번호를 직접 입력해 주세요.';
          });
        },
      );
    } on FirebaseAuthException catch (error) {
      if (!_isCurrent(requestId) || _verifying) {
        return;
      }

      setState(() {
        _sending = false;
        _message = _firebaseErrorMessage(error);
      });
    } catch (_) {
      if (!_isCurrent(requestId) || _verifying) {
        return;
      }

      setState(() {
        _sending = false;
        _message = '인증번호를 요청하지 못했어요. 연결 상태를 확인해 주세요.';
      });
    }
  }

  Future<void> _confirmCode() async {
    if (_busy || _completed) {
      return;
    }

    final verificationId = _verificationId;
    final code = _code.text.trim();

    if (verificationId == null) {
      setState(() {
        _message = '먼저 인증번호를 받아 주세요.';
      });
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _message = '인증번호 6자리를 입력해 주세요.';
      });
      return;
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );

    await _completeFirebase(credential, _requestId);
  }

  Future<void> _completeFirebase(
    PhoneAuthCredential credential,
    int requestId,
  ) async {
    if (!_isCurrent(requestId) || _verifying) {
      return;
    }

    setState(() {
      _sending = false;
      _verifying = true;
      _message = '휴대폰 번호를 확인하고 있어요.';
    });

    try {
      final result = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      if (!_isCurrent(requestId)) {
        return;
      }

      final user = result.user;

      if (user == null || user.phoneNumber == null) {
        throw StateError('인증된 전화번호를 확인하지 못했습니다.');
      }

      _firebaseUser = user;
      await _verifyWithBackend(user, requestId);
    } on FirebaseAuthException catch (error) {
      if (_isCurrent(requestId)) {
        setState(() {
          _message = _firebaseErrorMessage(error);
        });
      }
    } catch (_) {
      if (_isCurrent(requestId)) {
        setState(() {
          _message = '휴대폰 인증을 완료하지 못했어요. 다시 시도해 주세요.';
        });
      }
    } finally {
      if (_isCurrent(requestId)) {
        setState(() {
          _verifying = false;
        });
      }
    }
  }

  Future<void> _verifyWithBackend(User user, int requestId) async {
    try {
      final token = await user.getIdToken();

      if (!_isCurrent(requestId)) {
        return;
      }

      if (token == null || token.isEmpty) {
        throw StateError('Firebase ID 토큰이 없습니다.');
      }

      BookingVerification verification;

      try {
        verification = await widget.repository.verifyFirebasePhone(token);
      } on DioException catch (error) {
        // Firebase 토큰 오류일 때만 새 토큰으로 한 번 재시도합니다.
        if (_errorCode(error) != 'INVALID_FIREBASE_ID_TOKEN') {
          rethrow;
        }

        if (!_isCurrent(requestId)) {
          return;
        }

        final refreshedToken = await user.getIdToken(true);

        if (!_isCurrent(requestId)) {
          return;
        }

        if (refreshedToken == null || refreshedToken.isEmpty) {
          throw StateError('Firebase ID 토큰을 갱신하지 못했습니다.');
        }

        verification = await widget.repository.verifyFirebasePhone(
          refreshedToken,
        );
      }

      if (!_isCurrent(requestId)) {
        return;
      }

      if (!mounted) {
        return;
      }

      _completed = true;

      Navigator.of(context).pop<BookingVerification>(verification);
    } on DioException catch (error) {
      if (!_isCurrent(requestId)) {
        return;
      }

      final code = _errorCode(error);

      setState(() {
        if (code == 'PHONE_AUTH_REQUIRED' ||
            code == 'INVALID_FIREBASE_ID_TOKEN') {
          _firebaseUser = null;
        }

        _message = switch (code) {
          'INVALID_FIREBASE_ID_TOKEN' => '인증 정보가 유효하지 않아요. 휴대폰 인증을 다시 진행해 주세요.',
          'PHONE_AUTH_REQUIRED' => '전화번호 인증이 필요해요. 인증번호를 다시 받아 주세요.',
          'FIREBASE_NOT_CONFIGURED' => '서버 인증 설정을 준비 중이에요. 잠시 후 다시 시도해 주세요.',
          _ =>
            error.response?.statusCode == 401
                ? '환자 로그인이 만료됐어요. 다시 로그인한 뒤 진행해 주세요.'
                : '서버 확인을 완료하지 못했어요. 서버 확인 다시 시도를 눌러 주세요.',
        };
      });
    } on FirebaseAuthException catch (error) {
      if (_isCurrent(requestId)) {
        setState(() {
          _firebaseUser = null;
          _message = _firebaseErrorMessage(error);
        });
      }
    } catch (_) {
      if (_isCurrent(requestId)) {
        setState(() {
          _message = '인증 결과를 확인하지 못했어요. 서버 확인 다시 시도를 눌러 주세요.';
        });
      }
    }
  }

  Future<void> _retryBackend() async {
    final user = _firebaseUser;

    if (_busy || _completed || user == null) {
      return;
    }

    setState(() {
      _verifying = true;
      _message = '서버에서 인증 결과를 확인하고 있어요.';
    });

    try {
      await _verifyWithBackend(user, _requestId);
    } finally {
      if (mounted && !_completed) {
        setState(() {
          _verifying = false;
        });
      }
    }
  }

  void _changePhone() {
    if (_busy) {
      return;
    }

    // 이전 요청의 자동 인증 콜백을 무시합니다.
    _requestId++;

    setState(() {
      _verificationId = null;
      _firebaseUser = null;
      _code.clear();
      _message = null;
    });
  }

  String? _errorCode(DioException error) {
    final data = error.response?.data;
    return data is Map ? data['code'] as String? : null;
  }

  String _firebaseErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-phone-number' => '휴대폰 번호를 확인해 주세요.',
      'invalid-verification-code' => '인증번호가 올바르지 않아요.',
      'session-expired' => '인증번호가 만료됐어요. 인증번호를 다시 받아 주세요.',
      'too-many-requests' => '요청이 많아요. 잠시 후 다시 시도해 주세요.',
      'quota-exceeded' => '문자 발송 한도에 도달했어요. 잠시 후 다시 시도해 주세요.',
      'network-request-failed' => '인터넷 연결을 확인해 주세요.',
      'operation-not-allowed' =>
        '전화번호 인증 요청 실패\n'
        '코드: ${error.code}\n'
        '내용: ${error.message ?? '상세 정보 없음'}',
      _ => '휴대폰 인증을 진행하지 못했어요. 오류 코드: ${error.code}',
    };
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseVerified = _firebaseUser != null;

    return Scaffold(
      appBar: AppBar(title: const Text('휴대폰 인증')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.phone_android, size: 56, color: Color(0xFF1E3A8A)),
            const SizedBox(height: 24),
            const Text(
              '휴대폰 번호를 확인할게요',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text('입력한 휴대폰 번호로 전송된 인증번호를 입력해 주세요.'),
            const SizedBox(height: 32),
            TextField(
              controller: _phone,
              enabled: !_busy && _verificationId == null && !firebaseVerified,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: const InputDecoration(
                labelText: '휴대폰 번호',
                hintText: '01012345678',
                helperText: '하이픈 없이 숫자만 입력해 주세요.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _busy || firebaseVerified ? null : _sendCode,
              child: Text(
                _sending
                    ? '발송 요청 중…'
                    : _verificationId == null
                    ? '인증번호 받기'
                    : '인증번호 다시 받기',
              ),
            ),
            if (_verificationId != null || firebaseVerified)
              TextButton(
                onPressed: _busy ? null : _changePhone,
                child: const Text('휴대폰 번호 변경'),
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _code,
              enabled: !_busy && _verificationId != null && !firebaseVerified,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                labelText: '인증번호',
                hintText: '숫자 6자리',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy || _verificationId == null || firebaseVerified
                  ? null
                  : _confirmCode,
              child: const Text('인증 확인'),
            ),
            if (firebaseVerified)
              OutlinedButton(
                onPressed: _busy ? null : _retryBackend,
                child: const Text('서버 확인 다시 시도'),
              ),
            if (_busy) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(_message!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
