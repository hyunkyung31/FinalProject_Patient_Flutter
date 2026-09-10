import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patient/features/record_link/view/patient_link_required_screen.dart';
import 'package:flutter_patient/features/reservation/view/reservation_screen.dart';

void main() {
  testWidgets('미연결 화면에서 예약 화면으로 이동하고 뒤로 돌아온다', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: PatientLinkRequiredScreen()),
    );
    await tester.tap(find.text('진료 예약'));
    await tester.pumpAndSettle();
    expect(find.byType(ReservationScreen), findsOneWidget);
    expect(find.text('진료과 선택'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('예약 신청'), 200);
    final submit = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('예약 신청'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(submit.onPressed, isNull);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('아직 연결된 병원기록이 없어요'), findsOneWidget);
  });
}
