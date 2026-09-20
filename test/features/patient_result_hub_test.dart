import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/features/home/view/patient_result_hub_screen.dart';
import 'package:flutter_patient/features/reservation/repository/reservation_repository.dart';

void main() {
  testWidgets('검사결과 허브는 세 검사 유형을 표시한다', (tester) async {
    final repository = ReservationRepository(ApiClient());

    await tester.pumpWidget(
      MaterialApp(home: PatientResultHubScreen(repository: repository)),
    );

    expect(find.text('검사결과'), findsOneWidget);
    expect(find.text('혈액검사'), findsOneWidget);
    expect(find.text('혈관조영술'), findsOneWidget);
    expect(find.text('혈관 CT'), findsOneWidget);

    // 리포트와 generic AI 결과는 검사결과 허브에 포함하지 않는다.
    expect(find.text('AI 분석 결과'), findsNothing);
    expect(find.text('환자 리포트'), findsNothing);
  });
}
