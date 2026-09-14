import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pharmacy_repository.dart';
import 'pharmacy_map.dart';

String pharmacyError(Object e) {
  if (e is FormatException || e is TypeError) {
    return '서버 응답 형식이 약국 명세와 달라 정보를 표시하지 못했어요.';
  }
  if (e is DioException) {
    if (e.response?.statusCode == 401) return '로그인이 만료됐어요. 다시 로그인해 주세요.';
    if (e.response?.data is Map &&
        e.response?.data['code'] == 'PHARMACY_PROVIDER_UNAVAILABLE') {
      return '약국정보 제공기관에 연결할 수 없어요. 잠시 후 다시 시도해 주세요.';
    }
    if (e.response == null) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return '약국 검색 응답이 늦어지고 있어요. 잠시 후 다시 시도해 주세요.';
      }
      return '서버 연결에 실패했어요.${kDebugMode ? '\n연결 오류: ${e.type.name}' : ''}';
    }
    final data = e.response?.data;
    String safe(String text) => text
        .replaceAll(RegExp(r'[\w.+-]+@[\w.-]+'), '[이메일 숨김]')
        .replaceAll(RegExp(r'Bearer\s+\S+', caseSensitive: false), '[토큰 숨김]')
        .replaceAll(RegExp(r'[A-Za-z0-9_\-./+=]{32,}'), '[식별값 숨김]');
    final details = kDebugMode && data is Map
        ? [
            for (final field in ['code', 'detail'])
              if (data[field] is String)
                '$field: ${safe(data[field] as String)}',
          ].join('\n')
        : '';
    return '약국 조회에 실패했어요. (HTTP ${e.response?.statusCode})${details.isEmpty ? '' : '\n$details'}';
  }
  return '약국 정보를 불러오지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요.';
}

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key, required this.repository});
  final PharmacyRepository repository;
  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  final query = TextEditingController(text: '약국');
  final region = TextEditingController();
  List<Pharmacy> items = [];
  Map<String, dynamic>? filters;
  int radius = 3000, page = 0;
  bool busy = false, hasNext = false, searched = false;
  String? error;
  double? currentLatitude, currentLongitude;
  Pharmacy? selected;
  bool searchExpanded = false;

  void showPlace(Pharmacy p) {
    FocusScope.of(context).unfocus();
    setState(() {
      selected = p;
      searchExpanded = false;
    });
  }

  Widget placeCard(Pharmacy p) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: '약국 카드 닫기',
                  onPressed: () => setState(() => selected = null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SelectableText(p.address),
            Text(p.status),
            const Text('등록 운영시간 기준이에요. 방문 전 전화로 확인해 주세요.'),
            OutlinedButton(
              onPressed: p.phone?.trim().isNotEmpty != true
                  ? null
                  : () => openExternal(
                      Uri(
                        scheme: 'tel',
                        path: p.phone!.replaceAll(RegExp(r'[^0-9+]'), ''),
                      ),
                    ),
              child: const Text('전화하기'),
            ),
            FilledButton(
              onPressed: !p.hasCoordinates
                  ? null
                  : () => openExternal(
                      Uri.parse(
                        'https://map.kakao.com/link/to/${Uri.encodeComponent(p.name)},${p.latitude},${p.longitude}',
                      ),
                    ),
              child: const Text('카카오맵 길찾기'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PharmacyDetailScreen(
                      repository: widget.repository,
                      id: p.id,
                    ),
                  ),
                );
              },
              child: const Text('상세 보기'),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> openExternal(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('연결할 앱을 열지 못했어요.')));
    }
  }

  @override
  void dispose() {
    query.dispose();
    region.dispose();
    super.dispose();
  }

  Future<void> load({bool next = false}) async {
    if (filters == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
      searchExpanded = false;
      if (!next) selected = null;
    });
    try {
      final target = next ? page + 1 : 1;
      final result = await widget.repository.search(filters!, page: target);
      if (!mounted) return;
      setState(() {
        items = {
          for (final item in [
            ...(next ? items : <Pharmacy>[]),
            ...result.items,
          ])
            item.id: item,
        }.values.toList();
        page = target;
        hasNext = result.hasNext;
        searched = true;
      });
    } catch (e) {
      if (mounted) setState(() => error = pharmacyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> nearby() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          setState(() => error = '기기 위치 서비스를 켜 주세요. 아래 지역 검색도 사용할 수 있어요.');
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        if (mounted) {
          setState(
            () => error = '위치 권한이 없어요. 기기 설정에서 권한을 허용하거나 아래 지역 검색을 이용해 주세요.',
          );
        }
        return;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      filters = {
        'latitude': p.latitude,
        'longitude': p.longitude,
        'radius': radius,
      };
      setState(() {
        currentLatitude = p.latitude;
        currentLongitude = p.longitude;
        items = [];
        hasNext = false;
        searched = false;
      });
      await load();
    } on TimeoutException {
      if (mounted) {
        setState(() => error = '위치를 확인하는 데 시간이 걸려요. 다시 시도하거나 지역명으로 검색해 주세요.');
      }
    } catch (_) {
      if (mounted) setState(() => error = '위치를 가져오지 못했어요. 지역명으로 검색해 주세요.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget searchControls() => ListView(
    shrinkWrap: true,
    padding: const EdgeInsets.all(16),
    children: [
      const Text('현재 위치는 주변 약국을 검색할 때만 사용해요. 위치 권한 없이도 지역명으로 검색할 수 있어요.'),
      DropdownButton<int>(
        value: radius,
        isExpanded: true,
        items: [1000, 3000, 5000, 10000, 20000]
            .map(
              (r) => DropdownMenuItem(
                value: r,
                child: Text('검색 반경 ${r ~/ 1000}km'),
              ),
            )
            .toList(),
        onChanged: busy ? null : (v) => setState(() => radius = v!),
      ),
      FilledButton.icon(
        onPressed: busy ? null : nearby,
        icon: const Icon(Icons.my_location),
        label: const Text('현재 위치로 찾기'),
      ),
      const SizedBox(height: 24),
      TextField(
        controller: query,
        enabled: !busy,
        decoration: const InputDecoration(
          labelText: '약국명 (필수)',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: region,
        enabled: !busy,
        decoration: const InputDecoration(
          labelText: '지역명 (선택)',
          hintText: '예: 역삼동',
          border: OutlineInputBorder(),
        ),
      ),
      OutlinedButton(
        onPressed: busy
            ? null
            : () {
                if (query.text.trim().isEmpty) {
                  setState(
                    () => error = '약국명을 입력해 주세요. 지역으로 찾으려면 약국명에 ‘약국’을 입력해 주세요.',
                  );
                  return;
                }
                filters = {
                  'query': query.text.trim(),
                  if (region.text.trim().isNotEmpty)
                    'region': region.text.trim(),
                };
                setState(() {
                  items = [];
                  hasNext = false;
                  searched = false;
                });
                load();
              },
        child: const Text('약국명·지역 검색'),
      ),
    ],
  );
  Widget resultsPanel() => ListView(
    key: const ValueKey('pharmacyResults'),
    shrinkWrap: true,
    padding: const EdgeInsets.all(12),
    children: [
      Text('검색된 약국 ${items.length}곳'),
      for (final item in items)
        Card(
          child: ListTile(
            title: Text(item.name),
            subtitle: Text(
              '${item.address}\n${item.status}${item.distance.isEmpty ? '' : ' · ${item.distance}'}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showPlace(item),
          ),
        ),
      if (hasNext)
        TextButton(
          onPressed: busy ? null : () => load(next: true),
          child: const Text('더 보기'),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('주변 약국 찾기')),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Positioned.fill(
              child: PharmacyMap(
                items: items,
                latitude: currentLatitude,
                longitude: currentLongitude,
                onSelected: showPlace,
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => setState(
                              () => searchExpanded = !searchExpanded,
                            ),
                            icon: const Icon(Icons.search),
                            label: Text(
                              searchExpanded ? '검색창 닫기' : '약국명·지역 검색',
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: '현재 위치로 찾기',
                          onPressed: busy ? null : nearby,
                          icon: const Icon(Icons.my_location),
                        ),
                      ],
                    ),
                    if (busy) const LinearProgressIndicator(),
                    if (searchExpanded)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight * .55,
                        ),
                        child: searchControls(),
                      ),
                  ],
                ),
              ),
            ),
            if (!searchExpanded && MediaQuery.viewInsetsOf(context).bottom == 0)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * .40,
                    ),
                    child: selected != null
                        ? placeCard(selected!)
                        : error != null
                        ? SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(error!),
                                  if (filters != null)
                                    TextButton(
                                      onPressed: busy ? null : () => load(),
                                      child: const Text('다시 조회'),
                                    ),
                                ],
                              ),
                            ),
                          )
                        : items.isNotEmpty
                        ? resultsPanel()
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              searched && !busy
                                  ? '검색된 약국이 없어요. 지역이나 검색 반경을 바꿔 주세요.'
                                  : '위의 검색창이나 현재 위치 버튼으로 약국을 찾아보세요.',
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class PharmacyDetailScreen extends StatefulWidget {
  const PharmacyDetailScreen({
    super.key,
    required this.repository,
    required this.id,
  });
  final PharmacyRepository repository;
  final String id;
  @override
  State<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends State<PharmacyDetailScreen> {
  late Future<Pharmacy> future = widget.repository.detail(widget.id);
  Future<void> launch(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연결할 앱을 열지 못했어요. 주소나 전화번호를 복사해 이용해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('약국 상세'),
      actions: [
        IconButton(
          tooltip: '새로고침',
          onPressed: () =>
              setState(() => future = widget.repository.detail(widget.id)),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<Pharmacy>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(pharmacyError(snapshot.error!)));
        }
        final p = snapshot.data!;
        final hours = p.data['opening_hours'];
        const days = {
          'monday': '월요일',
          'tuesday': '화요일',
          'wednesday': '수요일',
          'thursday': '목요일',
          'friday': '금요일',
          'saturday': '토요일',
          'sunday': '일요일',
        };
        final phone = p.phone?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              SelectableText(p.address),
              Text(p.status),
              const Text('실시간 영업 확인이 아니에요. 방문 전 전화로 확인해 주세요.'),
              const SizedBox(height: 16),
              SelectableText(
                p.phone?.isNotEmpty == true ? p.phone! : '전화번호 정보 없음',
              ),
              OutlinedButton(
                onPressed: phone.isEmpty
                    ? null
                    : () => launch(Uri(scheme: 'tel', path: phone)),
                child: const Text('전화하기'),
              ),
              FilledButton(
                onPressed: !p.hasCoordinates
                    ? null
                    : () => launch(
                        Uri.https('www.google.com', '/maps/dir/', {
                          'api': '1',
                          'destination': '${p.latitude},${p.longitude}',
                        }),
                      ),
                child: const Text('길찾기'),
              ),
              const SizedBox(height: 24),
              const Text('등록 운영시간'),
              for (final day in days.entries)
                Text(
                  '${day.value}: ${hours is Map && hours[day.key] is Map && hours[day.key]['opens_at'] != null && hours[day.key]['closes_at'] != null ? '${hours[day.key]['opens_at']} ~ ${hours[day.key]['closes_at']}' : '정보 없음'}',
                ),
              if (p.data['data_source'] is String)
                Text('정보 출처: ${p.data['data_source']}'),
            ],
          ),
        );
      },
    ),
  );
}
