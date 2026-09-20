import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../model/bomi_equipment.dart';

abstract class BomiStudioRepository {
  Future<BomiEquipment> getEquipment();

  Future<BomiEquipment> updateEquipment(Map<String, dynamic> changes);
}

class PatientBomiStudioRepository implements BomiStudioRepository {
  PatientBomiStudioRepository(this.client);

  final ApiClient client;

  static const _equipmentPath = '/api/patient/bomi-equipment/';

  @override
  Future<BomiEquipment> getEquipment() async {
    final response = await client.dio.get<Object?>(_equipmentPath);

    final data = response.data;

    if (data is! Map) {
      throw const FormatException('보미 장착 정보 응답 형식이 올바르지 않습니다.');
    }

    return BomiEquipment.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<BomiEquipment> updateEquipment(Map<String, dynamic> changes) async {
    final response = await client.dio.patch<Object?>(
      _equipmentPath,
      data: changes,
    );

    final data = response.data;

    if (data is! Map) {
      throw const FormatException('보미 장착 정보 응답 형식이 올바르지 않습니다.');
    }

    return BomiEquipment.fromJson(Map<String, dynamic>.from(data));
  }
}

String bomiStudioErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;

    if (data is Map) {
      final detail = data['detail'];

      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
    }

    return switch (error.response?.statusCode) {
      401 => '로그인이 만료됐어요. 다시 로그인해 주세요.',
      403 => '보유하지 않은 아이템은 장착할 수 없어요.',
      404 => '보미 장착 저장 기능은 서버 배포 후 사용할 수 있어요.',
      _ => '보미 장착 상태를 저장하지 못했어요.',
    };
  }

  if (error is FormatException) {
    return error.message;
  }

  return '보미 장착 상태를 저장하지 못했어요.';
}
