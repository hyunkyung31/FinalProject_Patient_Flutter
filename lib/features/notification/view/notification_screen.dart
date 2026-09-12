import 'package:flutter/material.dart';
import '../model/patient_notification.dart';
import '../repository/notification_repository.dart';
import '../../reservation/repository/reservation_repository.dart';
import '../../reservation/view/patient_reservation_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, required this.reservationRepository});
  final ReservationRepository reservationRepository;
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final api = NotificationRepository(widget.reservationRepository.client);
  List<PatientNotification> items = [];
  bool loading = false, writing = false, unreadOnly = false, hasNext = false;
  int page = 0;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool next = false}) async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await api.list(
        page: next ? page + 1 : 1,
        unreadOnly: unreadOnly,
      );
      if (!mounted) return;
      setState(() {
        final combined = next ? [...items, ...result.items] : result.items;
        items = {
          for (final item in combined) item.recipientId: item,
        }.values.toList();
        page = result.page;
        hasNext = result.hasNext;
      });
    } catch (_) {
      if (mounted) {
        setState(() => error = '알림을 불러오지 못했어요. 로그인과 연결 상태를 확인하고 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _open(PatientNotification item) async {
    if (writing || loading) return;
    setState(() {
      writing = true;
      error = null;
    });
    try {
      if (!item.isRead) {
        final updated = await api.markRead(item.recipientId);
        if (!mounted) return;
        setState(
          () => items = items
              .map((n) => n.recipientId == updated.recipientId ? updated : n)
              .toList(),
        );
      }
      if (!mounted) return;
      if (item.referenceType == 'RESERVATION' && item.referenceId != null) {
        setState(() => writing = false);
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => PatientReservationDetailScreen(
              id: item.referenceId!,
              repository: widget.reservationRepository,
            ),
          ),
        );
      } else {
        setState(() => writing = false);
        await showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(item.title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.body),
                  const SizedBox(height: 12),
                  Text(item.dateLabel),
                  if (item.referenceType != null)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('관련 결과 화면 연결은 준비 중이에요.'),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('닫기'),
              ),
            ],
          ),
        );
      }
      if (mounted && unreadOnly) await _load();
    } catch (_) {
      if (mounted) setState(() => error = '알림 읽음 처리를 완료하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => writing = false);
    }
  }

  Future<void> _all() async {
    if (writing || loading) return;
    setState(() {
      writing = true;
      error = null;
    });
    try {
      await api.readAll();
      if (!mounted) return;
      setState(() => items = items.map((n) => n.read()).toList());
      await _load();
    } catch (_) {
      if (mounted) {
        setState(() => error = '전체 읽음 처리를 확인하지 못했어요. 새로고침 후 다시 확인해 주세요.');
      }
    } finally {
      if (mounted) setState(() => writing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('알림'),
      actions: [
        IconButton(
          tooltip: '새로고침',
          onPressed: loading || writing ? null : () => _load(),
          icon: const Icon(Icons.refresh),
        ),
        TextButton(
          onPressed: loading || writing ? null : _all,
          child: const Text('모두 읽음'),
        ),
      ],
    ),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: () => writing ? Future<void>.value() : _load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('전체')),
                ButtonSegment(value: true, label: Text('읽지 않음')),
              ],
              selected: {unreadOnly},
              onSelectionChanged: loading || writing
                  ? null
                  : (v) {
                      setState(() {
                        unreadOnly = v.first;
                        items = [];
                        page = 0;
                        hasNext = false;
                      });
                      _load();
                    },
            ),
            const SizedBox(height: 16),
            if (loading || writing) const LinearProgressIndicator(),
            if (error != null) ...[
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              TextButton(
                onPressed: loading || writing ? null : () => _load(),
                child: const Text('다시 시도'),
              ),
            ],
            if (!loading && error == null && items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  unreadOnly ? '읽지 않은 알림이 없어요.' : '알림이 없어요.',
                  textAlign: TextAlign.center,
                ),
              ),
            for (final item in items)
              Card(
                child: ListTile(
                  leading: Icon(
                    item.isRead
                        ? Icons.notifications_none
                        : Icons.notifications_active,
                    color: item.isRead
                        ? null
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: item.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('${item.body}\n${item.dateLabel}'),
                  isThreeLine: true,
                  onTap: loading || writing ? null : () => _open(item),
                ),
              ),
            if (hasNext)
              TextButton(
                onPressed: loading || writing ? null : () => _load(next: true),
                child: const Text('더 보기'),
              ),
          ],
        ),
      ),
    ),
  );
}

class PatientNotificationButton extends StatefulWidget {
  const PatientNotificationButton({super.key, required this.repository});
  final ReservationRepository repository;
  @override
  State<PatientNotificationButton> createState() =>
      _PatientNotificationButtonState();
}

class _PatientNotificationButtonState extends State<PatientNotificationButton>
    with WidgetsBindingObserver {
  int? count;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final value = await NotificationRepository(
        widget.repository.client,
      ).unreadCount();
      if (mounted) setState(() => count = value);
    } catch (_) {
      if (mounted) setState(() => count = null);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: count == null ? '알림' : '알림 · 읽지 않음 $count개',
    icon: Badge(
      isLabelVisible: count != null && count! > 0,
      label: Text(count != null && count! > 99 ? '99+' : '${count ?? 0}'),
      child: const Icon(Icons.notifications_none_rounded),
    ),
    onPressed: () async {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              NotificationScreen(reservationRepository: widget.repository),
        ),
      );
      if (mounted) await _load();
    },
  );
}
