import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_patient/features/chatbot/widgets/chatbot_floating_launcher.dart';
import 'package:flutter_patient/features/chatbot/widgets/chatbot_overlay_host.dart';

void main() {
  final controller = ChatbotOverlayController.instance;

  tearDown(() {
    controller.deactivate();
  });

  testWidgets('梨쀫큸 ?곗쿂???쒖꽦?????쒖떆?섍퀬 梨쀫큸 ?댁슜 以묒뿉???④꺼吏꾨떎', (tester) async {
    final completer = Completer<void>();
    var openCount = 0;

    await tester.pumpWidget(
      const MaterialApp(
        home: ChatbotOverlayHost(child: Scaffold(body: Text('?섏옄 ?붾㈃'))),
      ),
    );

    expect(find.byType(ChatbotFloatingLauncher), findsNothing);

    controller.activate(() {
      openCount += 1;
      return completer.future;
    });

    await tester.pump();

    expect(find.byType(ChatbotFloatingLauncher), findsOneWidget);

    await tester.tap(find.byType(ChatbotFloatingLauncher));
    await tester.pump();

    expect(openCount, 1);
    expect(find.byType(ChatbotFloatingLauncher), findsNothing);

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.byType(ChatbotFloatingLauncher), findsOneWidget);

    controller.deactivate();
    await tester.pump();

    expect(find.byType(ChatbotFloatingLauncher), findsNothing);
  });
}
