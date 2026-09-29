import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/features/bomi_studio/model/bomi_equipment.dart';
import 'package:flutter_patient/features/bomi_studio/repository/bomi_studio_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> equipmentJson({
  Object? outfit = 'BOMI_OUTFIT_PINK_TRAINING',
  Object? accessory = 'BOMI_ACC_HEART_RIBBON',
  Object? background = 'BOMI_BG_PARK_LAKESIDE',
}) {
  return {
    'id': 17,
    'patient_account': 3,
    'outfit_reward_code': outfit,
    'accessory_reward_code': accessory,
    'background_reward_code': background,
    'created_at': '2026-09-20T01:00:00Z',
    'updated_at': '2026-09-20T01:05:00Z',
  };
}

class BomiStudioAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  bool malformedResponse = false;

  Map<String, dynamic> responseData = equipmentJson();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    final body = malformedResponse
        ? jsonEncode(['invalid'])
        : jsonEncode(responseData);

    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('BomiEquipment', () {
    test('보미 장착 상태 JSON을 정상 파싱한다', () {
      final equipment = BomiEquipment.fromJson(equipmentJson());

      expect(equipment.id, 17);
      expect(equipment.patientAccount, 3);
      expect(equipment.outfitRewardCode, 'BOMI_OUTFIT_PINK_TRAINING');
      expect(equipment.accessoryRewardCode, 'BOMI_ACC_HEART_RIBBON');
      expect(equipment.backgroundRewardCode, 'BOMI_BG_PARK_LAKESIDE');
      expect(equipment.createdAt, DateTime.parse('2026-09-20T01:00:00Z'));
    });

    test('null 및 빈 reward code는 미장착 상태로 처리한다', () {
      final equipment = BomiEquipment.fromJson(
        equipmentJson(outfit: null, accessory: '', background: '   '),
      );

      expect(equipment.outfitRewardCode, isNull);
      expect(equipment.accessoryRewardCode, isNull);
      expect(equipment.backgroundRewardCode, isNull);
    });
  });

  group('PatientBomiStudioRepository', () {
    late ApiClient client;
    late BomiStudioAdapter adapter;
    late PatientBomiStudioRepository repository;

    setUp(() {
      client = ApiClient();
      client.setAccessToken('fake-patient-access');

      adapter = BomiStudioAdapter();
      client.dio.httpClientAdapter = adapter;

      repository = PatientBomiStudioRepository(client);
    });

    tearDown(() {
      client.dispose();
    });

    test('GET은 보미 장착 API와 환자 인증 헤더를 사용한다', () async {
      final equipment = await repository.getEquipment();

      expect(equipment.accessoryRewardCode, 'BOMI_ACC_HEART_RIBBON');

      expect(adapter.requests.length, 1);

      final request = adapter.requests.single;

      expect(request.method, 'GET');
      expect(request.path, '/api/patient/bomi-equipment/');
      expect(request.headers['Authorization'], 'Bearer fake-patient-access');
    });

    test('PATCH는 변경할 장착 상태를 그대로 전달한다', () async {
      final changes = <String, dynamic>{
        'outfit_reward_code': 'BOMI_OUTFIT_BLUE_BUNNY_HOODIE',
        'accessory_reward_code': null,
        'background_reward_code': 'BOMI_BG_BEACH_PASTEL',
      };

      adapter.responseData = equipmentJson(
        outfit: 'BOMI_OUTFIT_BLUE_BUNNY_HOODIE',
        accessory: null,
        background: 'BOMI_BG_BEACH_PASTEL',
      );

      final equipment = await repository.updateEquipment(changes);

      final request = adapter.requests.single;

      expect(request.method, 'PATCH');
      expect(request.path, '/api/patient/bomi-equipment/');
      expect(request.data, changes);
      expect(request.headers['Authorization'], 'Bearer fake-patient-access');

      expect(equipment.outfitRewardCode, 'BOMI_OUTFIT_BLUE_BUNNY_HOODIE');
      expect(equipment.accessoryRewardCode, isNull);
      expect(equipment.backgroundRewardCode, 'BOMI_BG_BEACH_PASTEL');
    });

    test('객체가 아닌 서버 응답은 FormatException으로 처리한다', () async {
      adapter.malformedResponse = true;

      await expectLater(
        repository.getEquipment(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
