import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patient/app.dart';
import 'package:flutter_patient/features/onboarding/repository/onboarding_repository.dart';

class MemoryOnboardingRepository extends OnboardingRepository {
  bool completed = false;
  bool failSave = false;
  @override
  Future<bool> isCompleted() async => completed;
  @override
  Future<void> complete() async {
    if (failSave) throw StateError('storage unavailable');
    completed = true;
  }
}

void main() {
  testWidgets('First launch, all pages, finish, next launch and replay', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemoryOnboardingRepository();
    await tester.pumpWidget(MyApp(onboardingRepository: repository));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('onboarding-page-1')), findsOneWidget);
    for (var page = 2; page <= 7; page++) {
      await tester.tap(find.byKey(ValueKey('onboarding-next-${page - 1}')));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('onboarding-page-$page')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('onboarding-page-6')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-next-6')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('onboarding-next-7')));
    await tester.pumpAndSettle();
    expect(repository.completed, isTrue);
    expect(find.text('다가오는 진료'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(MyApp(onboardingRepository: repository));
    await tester.pumpAndSettle();
    expect(find.text('다가오는 진료'), findsOneWidget);
    await tester.tap(find.byTooltip('앱 사용 가이드'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('onboarding-page-1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-skip-1')));
    await tester.pumpAndSettle();
    expect(find.text('다가오는 진료'), findsOneWidget);
  });

  testWidgets('Skip saves completion; storage failure allows retry', (
    tester,
  ) async {
    final repository = MemoryOnboardingRepository()..failSave = true;
    await tester.pumpWidget(MyApp(onboardingRepository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('onboarding-skip-1')));
    await tester.pumpAndSettle();
    expect(repository.completed, isFalse);
    expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    repository.failSave = false;
    await tester.tap(find.byKey(const ValueKey('onboarding-skip-1')));
    await tester.pumpAndSettle();
    expect(repository.completed, isTrue);
    expect(find.text('다가오는 진료'), findsOneWidget);
  });
}
