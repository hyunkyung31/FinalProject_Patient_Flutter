import '../../core/network/api_client.dart';

class Pharmacy {
  Pharmacy(this.data) {
    if (data['id'] is! String || data['name'] is! String) {
      throw const FormatException('약국 응답 오류');
    }
  }
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get name => data['name'] as String;
  String get address =>
      data['road_address'] as String? ??
      data['address'] as String? ??
      '주소 정보 없음';
  String? get phone => data['phone'] as String?;
  double? get latitude => (data['latitude'] as num?)?.toDouble();
  double? get longitude => (data['longitude'] as num?)?.toDouble();
  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite &&
      latitude!.abs() <= 90 &&
      longitude!.abs() <= 180;
  String get status {
    if (data['hours_available'] != true) return '운영시간 정보 없음';
    if (data['business_status'] == 'OPEN' && data['is_open_now'] == true) {
      return '등록 운영시간상 영업 중';
    }
    if (data['business_status'] == 'CLOSED' && data['is_open_now'] == false) {
      return '등록 운영시간상 영업 종료';
    }
    return '운영시간 정보 없음';
  }

  String get distance {
    final value = data['distance_m'];
    if (value is! num || !value.isFinite || value < 0) return '';
    return value < 1000
        ? '${value.round()}m'
        : '${(value / 1000).toStringAsFixed(1)}km';
  }
}

class PharmacyPage {
  PharmacyPage(this.items, this.hasNext);
  final List<Pharmacy> items;
  final bool hasNext;
}

class PharmacyRepository {
  PharmacyRepository(this.client);
  final ApiClient client;
  Future<PharmacyPage> search(
    Map<String, dynamic> filters, {
    int page = 1,
  }) async {
    final nearby = filters.containsKey('latitude');
    final response = await client.dio.get<Map<String, dynamic>>(
      '/api/patient/pharmacies/${nearby ? 'nearby' : 'search'}/',
      queryParameters: {...filters, 'page': page, 'size': 15},
    );
    final data = response.data;
    if (data == null || data['results'] is! List || !data.containsKey('next')) {
      throw const FormatException('약국 목록 응답 오류');
    }
    // 서버의 next URL에 환자 JWT를 전달하지 않고 동일한 API에서 다음 페이지를 조회합니다.
    return PharmacyPage(
      (data['results'] as List)
          .map((r) => Pharmacy(Map<String, dynamic>.from(r as Map)))
          .toList(),
      data['next'] != null,
    );
  }

  Future<Pharmacy> detail(String id) async {
    final response = await client.dio.get<Map<String, dynamic>>(
      '/api/patient/pharmacies/${Uri.encodeComponent(id)}/',
    );
    if (response.data == null) throw const FormatException('약국 상세 응답 오류');
    return Pharmacy(response.data!);
  }
}
