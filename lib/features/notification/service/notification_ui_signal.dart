import 'package:flutter/foundation.dart';

class NotificationUiEvent {
  const NotificationUiEvent({
    required this.id,
    required this.title,
    required this.body,
  });

  final int id;
  final String title;
  final String body;
}

class NotificationUiSignal {
  NotificationUiSignal._();

  static final NotificationUiSignal instance = NotificationUiSignal._();

  final ValueNotifier<NotificationUiEvent?> event =
      ValueNotifier<NotificationUiEvent?>(null);

  int _nextId = 0;
  String? _lastSignature;
  DateTime? _lastEmittedAt;

  void show(String title, String body) {
    final now = DateTime.now();
    final signature = '$title\n$body';

    final recentlyEmitted =
        _lastEmittedAt != null &&
        now.difference(_lastEmittedAt!) < const Duration(seconds: 2);

    // ?? ??? ?? ?? ??? ??? ???? ? ?? ?????.
    if (recentlyEmitted && _lastSignature == signature) {
      return;
    }

    _lastSignature = signature;
    _lastEmittedAt = now;

    event.value = NotificationUiEvent(id: ++_nextId, title: title, body: body);
  }
}
