import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'pharmacy_repository.dart';

String pharmacyMapData(
  List<Pharmacy> items,
  double? latitude,
  double? longitude,
) => jsonEncode({
  'places': [
    for (final p in items.where((p) => p.hasCoordinates))
      {'id': p.id, 'lat': p.latitude, 'lng': p.longitude},
  ],
  'location': latitude == null || longitude == null
      ? null
      : {'lat': latitude, 'lng': longitude},
});

class PharmacyMap extends StatefulWidget {
  const PharmacyMap({
    super.key,
    required this.items,
    required this.onSelected,
    this.latitude,
    this.longitude,
  });
  final List<Pharmacy> items;
  final ValueChanged<Pharmacy> onSelected;
  final double? latitude, longitude;
  @override
  State<PharmacyMap> createState() => _PharmacyMapState();
}

class _PharmacyMapState extends State<PharmacyMap> {
  static const keyValue = String.fromEnvironment('KAKAO_MAP_JAVASCRIPT_KEY');
  WebViewController? controller;
  Timer? timer;
  bool ready = false;
  String? error;
  String? diagnostic;

  void reportFailure(String code) {
    if (!mounted) return;
    timer?.cancel();
    setState(() {
      diagnostic = code;
      error = '지도를 불러오지 못했어요. 목록 검색은 계속 사용할 수 있어요.';
    });
  }
  @override
  void initState() {
    super.initState();
    if (keyValue.isNotEmpty) start();
  }

  Future<void> start() async {
    try {
      final c = WebViewController();
      controller = c;
      await c.setJavaScriptMode(JavaScriptMode.unrestricted);
      await c.addJavaScriptChannel(
        'PharmacyBridge',
        onMessageReceived: (message) {
          if (!mounted) return;
          if (message.message == 'ready') {
            timer?.cancel();
            setState(() {
              ready = true;
              error = null;
              diagnostic = null;
            });
            sync();
          } else if (message.message == 'SDK_LOAD_FAILED' ||
              message.message == 'MAP_INIT_FAILED') {
            if (diagnostic == null) reportFailure(message.message);
          } else {
            try {
              final data = jsonDecode(message.message);
              if (data is Map && data['id'] is String) {
                for (final p in widget.items) {
                  if (p.id == data['id']) {
                    widget.onSelected(p);
                    break;
                  }
                }
              }
            } catch (_) {}
          }
        },
      );
      await c.setNavigationDelegate(
        NavigationDelegate(
          onHttpError: (event) {
            final uri = Uri.tryParse(event.request?.uri.toString() ?? '');
            if (uri?.host == 'dapi.kakao.com') {
              reportFailure('KAKAO_HTTP_${event.response?.statusCode ?? 0}');
            }
          },
          onWebResourceError: (event) {
            final uri = Uri.tryParse(event.url ?? '');
            if (uri?.host == 'dapi.kakao.com' || event.isForMainFrame == true) {
              // Keep only Chromium's symbolic error, never the URL or app key.
              final reason = RegExp(r'\bERR_[A-Z0-9_]+\b')
                  .firstMatch(event.description)
                  ?.group(0);
              // A generic WebView callback must not overwrite an HTTP status.
              if (diagnostic?.startsWith('KAKAO_HTTP_') != true) {
                reportFailure(reason ?? 'WEBVIEW_${event.errorCode}');
              }
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            return uri?.host == 'localhost' || request.url == 'about:blank'
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      );
      final sdk = jsonEncode(
        'https://dapi.kakao.com/v2/maps/sdk.js?autoload=false&appkey=${Uri.encodeQueryComponent(keyValue)}',
      );
      await c.loadHtmlString(
        '''<!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1.0"><style>html,body,#map{height:100%;margin:0} .me{background:#1d4ed8;color:white;border:2px solid white;border-radius:20px;padding:5px;font:12px sans-serif}</style></head><body><div id="map"></div><script>
let map, overlays=[];
window.updatePharmacies=function(data){
 if(!map)return;
 overlays.forEach(o=>o.setMap(null));overlays=[];
 const bounds=new kakao.maps.LatLngBounds();let count=0;
 data.places.forEach(p=>{const pos=new kakao.maps.LatLng(p.lat,p.lng);const marker=new kakao.maps.Marker({map:map,position:pos});overlays.push(marker);bounds.extend(pos);count++;
 kakao.maps.event.addListener(marker,'click',()=>PharmacyBridge.postMessage(JSON.stringify({id:p.id})));});
 if(data.location){const pos=new kakao.maps.LatLng(data.location.lat,data.location.lng);overlays.push(new kakao.maps.CustomOverlay({map:map,position:pos,content:'<span class="me">내 위치</span>'}));if(!count){map.setCenter(pos);map.setLevel(5);}}
 if(count)map.setBounds(bounds,40,40,40,40);
};
const script=document.createElement('script');script.src=$sdk;
script.onerror=()=>PharmacyBridge.postMessage('SDK_LOAD_FAILED');
script.onload=()=>{try{kakao.maps.load(()=>{try{map=new kakao.maps.Map(document.getElementById('map'),{center:new kakao.maps.LatLng(37.5665,126.9780),level:7});PharmacyBridge.postMessage('ready');}catch(e){PharmacyBridge.postMessage('MAP_INIT_FAILED');}});}catch(e){PharmacyBridge.postMessage('MAP_INIT_FAILED');}};
document.head.appendChild(script);
</script></body></html>''',
        baseUrl: 'https://localhost/',
      );
      if (!mounted) return;
      setState(() {});
      if (!ready && error == null) {
        timer = Timer(const Duration(seconds: 20), () {
          if (mounted && !ready) {
            setState(() => error = '지도 연결을 확인해 주세요. 목록 검색은 계속 사용할 수 있어요.');
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = '지도를 시작하지 못했어요.');
    }
  }

  Future<void> sync() async {
    if (!ready) return;
    try {
      await controller?.runJavaScript(
        'window.updatePharmacies(${pharmacyMapData(widget.items, widget.latitude, widget.longitude)});',
      );
    } catch (_) {
      if (mounted) setState(() => error = '지도 갱신에 실패했어요.');
    }
  }

  @override
  void didUpdateWidget(covariant PharmacyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items) ||
        oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      sync();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (keyValue.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '지도 연결 설정이 필요해요.\n아래에서 약국을 검색할 수 있어요.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Stack(
      children: [
        if (controller != null)
          Positioned.fill(
            child: WebViewWidget(
              controller: controller!,
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
            ),
          ),
        if (!ready && error == null)
          const Center(child: CircularProgressIndicator()),
        if (error != null)
          Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  kDebugMode && diagnostic != null
                      ? '$error\n오류 코드: $diagnostic'
                      : error!,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
