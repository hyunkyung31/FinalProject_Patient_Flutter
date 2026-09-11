import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patient/features/home/view/dashboard_screen.dart';

void main() {
  testWidgets('Dashboard fits a narrow phone and opens reservation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    expect(find.text('다가오는 진료'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('진료 예약하기'));
    await tester.pumpAndSettle();
    expect(find.text('진료 예약을 시작해 볼까요?'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('다가오는 진료'), findsOneWidget);
  });
}
