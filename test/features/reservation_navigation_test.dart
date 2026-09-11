import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patient/features/record_link/view/patient_link_required_screen.dart';
import 'package:flutter_patient/features/reservation/view/reservation_screen.dart';
import 'package:flutter_patient/features/reservation/view/reservation_list_screen.dart';

void main() {
  testWidgets('예시 모드를 켜야 카드가 나타나고 상세에서 변경과 취소는 비활성화된다', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: ReservationListScreen()));
    expect(find.text('예약 상세 보기'), findsNothing);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('예약 상세 보기'));
    await tester.pumpAndSettle();
    expect(find.text('예약 상세'), findsOneWidget);
    expect(find.text('디자인 확인용 예시 예약입니다.\n실제 접수된 예약이 아닙니다.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('예약 취소'), 200);
    final cancel = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('예약 취소'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(cancel.onPressed, isNull);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('지난 예약'));
    await tester.pumpAndSettle();
    expect(find.text('진료 완료'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('예약 상세 보기'), findsNothing);
  });
  testWidgets('예약 신청에서 목록의 두 탭을 확인하고 새 예약을 연다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReservationScreen()));
    await tester.tap(find.byTooltip('예약 목록'));
    await tester.pumpAndSettle();
    expect(find.text('다가오는 진료를 확인해 보세요'), findsOneWidget);
    await tester.tap(find.text('지난 예약'));
    await tester.pumpAndSettle();
    expect(find.text('지난 진료 내역을 모아볼 수 있어요'), findsOneWidget);
    await tester.tap(find.text('진료 예약'));
    await tester.pumpAndSettle();
    expect(find.text('진료 예약을 시작해 볼까요?'), findsOneWidget);
    expect(find.byTooltip('예약 목록'), findsNothing);
    expect(tester.takeException(), isNull);
  });
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
