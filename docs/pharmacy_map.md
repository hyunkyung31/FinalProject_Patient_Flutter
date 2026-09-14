# 주변 약국 지도 설정

Android 에뮬레이터를 지원하기 위해 webview_flutter와 카카오 지도 JavaScript SDK를 사용합니다.

1. Kakao Developers의 BOMI 앱에서 카카오맵 사용 설정을 켭니다.
2. JavaScript 키의 JavaScript SDK 도메인에 `https://localhost`를 등록합니다.
3. 네이티브 앱 키가 아닌 JavaScript 키로 실행합니다.

```powershell
flutter run -d emulator-5554 --dart-define=KAKAO_MAP_JAVASCRIPT_KEY=발급받은_JavaScript_키
```

키는 클라이언트용 설정값이며 앱에 포함됩니다. 관리자 키나 REST API 키를 사용하지 않습니다. 실행 설정 변경 후 앱을 완전히 재시작합니다.

키 미설정 또는 지도 로딩 실패 시 목록 검색은 계속 가능합니다. 기본 지도 중심은 서울시청이며 사용자의 위치라고 표시하지 않습니다. 현재 위치 버튼을 눌러 위치 권한을 허용한 경우에만 위치를 조회합니다. 검색 결과의 유효한 좌표만 지도에 표시합니다. 마커와 목록 선택 시 목록 응답 기반 카드를 열며 상세 조회는 별도 버튼에서 수행합니다.

환자 JWT는 백엔드 검색에만 사용하며 WebView에 전달하지 않습니다. 지도에는 표시할 좌표와 약국 식별자만 전달합니다. 지도 자체의 실기기 검증에는 유효한 키와 도메인 등록이 필요합니다.
