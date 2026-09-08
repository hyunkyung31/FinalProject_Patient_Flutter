import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_patient/features/onboarding/widgets/onboarding_scene.dart';

void main() {
  testWidgets('Greeting moves the separated arm while keeping the body fixed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: OnboardingScene(index: 0, active: true)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 576));
    final bodyRect = tester.getRect(
      find.byKey(const ValueKey('bomi-fixed-body')),
    );
    final firstArm = tester
        .widget<Transform>(find.byKey(const ValueKey('bomi-waving-arm')))
        .transform
        .clone();
    await tester.pump(const Duration(milliseconds: 252));
    expect(
      tester.getRect(find.byKey(const ValueKey('bomi-fixed-body'))),
      bodyRect,
    );
    expect(
      tester
          .widget<Transform>(find.byKey(const ValueKey('bomi-waving-arm')))
          .transform,
      isNot(equals(firstArm)),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Transform>(find.byKey(const ValueKey('bomi-waving-arm')))
          .transform
          .isIdentity(),
      isTrue,
    );
    expect(tester.hasRunningAnimations, isFalse);
  });
  testWidgets('Greeting never displays sparkle effects', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: OnboardingScene(index: 0, active: true)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('arrival-effect-0')), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('arrival-effect-0')), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });
  testWidgets('Mission animates to 75 percent and stops offscreen', (
    tester,
  ) async {
    Widget scene(bool active) => MaterialApp(
      home: Scaffold(body: OnboardingScene(index: 5, active: active)),
    );
    await tester.pumpWidget(scene(true));
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0,
    );
    await tester.pump(const Duration(milliseconds: 800));
    final middle = tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
        .value!;
    expect(middle, greaterThan(0));
    expect(middle, lessThan(.75));
    await tester.pump(const Duration(seconds: 2));
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      .75,
    );
    expect(find.text('+100 P'), findsOneWidget);
    final before = tester
        .widget<Transform>(find.byKey(const ValueKey('bomi-motion-5')))
        .transform;
    await tester.pump(const Duration(milliseconds: 400));
    final after = tester
        .widget<Transform>(find.byKey(const ValueKey('bomi-motion-5')))
        .transform;
    expect(before, equals(after));
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(scene(false));
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'All scenes support large text on a narrow phone with reduced motion',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (var index = 0; index < 7; index++) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                disableAnimations: true,
                textScaler: TextScaler.linear(2),
              ),
              child: Scaffold(
                body: OnboardingScene(
                  key: ValueKey(index),
                  index: index,
                  active: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.takeException(), isNull, reason: 'Scene $index overflow');
      }
    },
  );
}
