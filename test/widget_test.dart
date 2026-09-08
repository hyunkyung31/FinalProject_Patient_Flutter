import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patient/app.dart';

void main() {
  testWidgets('Dashboard fits a narrow phone and opens menu notice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    expect(find.text('다가오는 진료'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('진료 예약하기'));
    await tester.pumpAndSettle();
    expect(find.text('이 기능은 준비 중이에요. 지금은 메인 화면 미리보기입니다.'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('다가오는 진료'), findsOneWidget);
  });
}
