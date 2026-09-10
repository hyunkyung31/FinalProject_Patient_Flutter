import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/features/auth/model/auth_login_result.dart';
import 'package:flutter_patient/features/auth/service/auth_service.dart';

class LoginAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      '{"access":"server-access","refresh":"server-refresh",'
      '"is_new_account":true,"patient_link":null}',
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('카카오 ID 토큰으로 로그인하고 신규 미연결 계정을 읽는다', () async {
    final client = ApiClient();
    addTearDown(client.dispose);
    final adapter = LoginAdapter();
    client.dio.httpClientAdapter = adapter;

    final result = await AuthService(client).loginWithKakao(
      idToken: 'fake-kakao-id-token',
      deviceId: 'test-device',
    );

    expect(adapter.request!.path, '/api/auth/social/login/');
    expect(adapter.request!.method, 'POST');
    expect(adapter.request!.data, {
      'identity_type': 'KAKAO',
      'id_token': 'fake-kakao-id-token',
      'device_id': 'test-device',
      'device_name': 'Android Device',
      'platform': 'ANDROID',
    });
    expect(result.isNewAccount, isTrue);
    expect(result.hasPatientLink, isFalse);
    expect(result.tokens.access, 'server-access');
    expect(result.tokens.refresh, 'server-refresh');
  });

  test('연결된 기존 계정과 잘못된 토큰 응답을 구분한다', () {
    final data = <String, dynamic>{
      'access': 'server-access',
      'refresh': 'server-refresh',
      'is_new_account': false,
      'patient_link': {'patient_id': 3},
    };
    final result = AuthLoginResult.fromJson(data);
    expect(result.isNewAccount, isFalse);
    expect(result.hasPatientLink, isTrue);
    expect(
      () => AuthLoginResult.fromJson({...data, 'access': ''}),
      throwsFormatException,
    );
  });
}
