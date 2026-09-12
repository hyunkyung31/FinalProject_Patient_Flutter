import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patient/core/network/api_client.dart';
import 'package:flutter_patient/features/reservation/model/booking_options.dart';
import 'package:flutter_patient/features/reservation/repository/reservation_repository.dart';
import 'package:flutter_patient/features/reservation/view/booking_form.dart';
import 'package:flutter_patient/features/reservation/view/reservation_screen.dart';
import 'package:flutter_patient/features/verification/view/phone_verification_screen.dart';

class FakeRepository extends ReservationRepository {
  FakeRepository() : super(ApiClient());
  BookingVerification? verification;
  bool linked = false;
  int departmentLoads = 0;
  @override
  Future<bool> hasPatientLink() async => linked;
  @override
  Future<BookingVerification?> getVerification() async => verification;
  @override
  Future<List<DepartmentOption>> getDepartments() async {
    departmentLoads++;
    return [];
  }
}

void main() {
  late FakeRepository repository;
  setUp(() => repository = FakeRepository());
  tearDown(() => repository.client.dispose());

  Future<void> openBooking(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => ReservationScreen(repository: repository),
                  ),
                ),
                child: const Text('예약 열기'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('예약 열기'));
    // Gate awaits authentication while its loading route is covered.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  BookingVerification valid() => BookingVerification(
    12,
    DateTime.now().add(const Duration(minutes: 30)),
    true,
    true,
    verifiedPhoneNumber: '+821012345678',
  );

  testWidgets('미인증 환자는 폼 조회 전에 인증하고 결과를 폼에 전달한다', (tester) async {
    await openBooking(tester);
    expect(find.byType(PhoneVerificationScreen), findsOneWidget);
    expect(find.byType(BookingForm), findsNothing);
    expect(repository.departmentLoads, 0);
    Navigator.of(
      tester.element(find.byType(PhoneVerificationScreen)),
    ).pop<BookingVerification>(valid());
    await tester.pumpAndSettle();
    final form = tester.widget<BookingForm>(find.byType(BookingForm));
    expect(form.initialVerification?.id, 12);
    expect(repository.departmentLoads, 1);
    expect(find.text('최초 예약에는 본인인증이 필요해요.'), findsNothing);
  });

  testWidgets('인증 취소 시 이전 화면으로 돌아가고 폼은 열지 않는다', (tester) async {
    await openBooking(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('예약 열기'), findsOneWidget);
    expect(find.byType(BookingForm), findsNothing);
    expect(repository.departmentLoads, 0);
  });

  testWidgets('유효 인증 기록이 있으면 인증 화면을 생략한다', (tester) async {
    repository.verification = valid();
    await openBooking(tester);
    await tester.pumpAndSettle();
    expect(find.byType(PhoneVerificationScreen), findsNothing);
    expect(find.byType(BookingForm), findsOneWidget);
  });

  testWidgets('병원기록 연결 환자는 기존대로 예약 폼을 연다', (tester) async {
    repository.linked = true;
    await openBooking(tester);
    await tester.pumpAndSettle();
    expect(find.byType(PhoneVerificationScreen), findsNothing);
    expect(find.byType(BookingForm), findsOneWidget);
  });
}
