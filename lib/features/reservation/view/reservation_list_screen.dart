import 'dart:async';

import 'package:flutter/material.dart';

import '../model/patient_reservation.dart';
import '../repository/reservation_repository.dart';
import 'patient_reservation_detail_screen.dart';
import 'reservation_screen.dart';

class ReservationListScreen extends StatefulWidget {
  const ReservationListScreen({
    super.key,
    this.repository,
    this.embedded = false,
  });

  final ReservationRepository? repository;
  final bool embedded;

  @override
  State<ReservationListScreen> createState() => _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _refreshing = false;
  late Future<List<PatientReservation>>? _reservations = widget.repository
      ?.getReservations();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted &&
          ModalRoute.of(context)?.isCurrent == true &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _reload();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        mounted &&
        ModalRoute.of(context)?.isCurrent == true) {
      _reload();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _reload() async {
    final repository = widget.repository;
    if (repository == null || _refreshing || !mounted) return;
    _refreshing = true;
    final next = repository.getReservations();
    setState(() => _reservations = next);
    try {
      await next;
    } finally {
      _refreshing = false;
    }
  }

  Widget _reservationList(bool past) {
    if (_reservations == null) return _EmptyReservationList(past: past);
    return FutureBuilder<List<PatientReservation>>(
      future: _reservations,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: _reload,
                child: const Text('다시 시도'),
              ),
            ),
          );
        }
        final items =
            snapshot.data!
                .where((item) => item.isPast(DateTime.now()) == past)
                .toList()
              ..sort(
                (a, b) => past
                    ? b.reservedAt.compareTo(a.reservedAt)
                    : a.reservedAt.compareTo(b.reservedAt),
              );
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
            children: [
              Row(
                children: [
                  Icon(
                    past ? Icons.history_rounded : Icons.calendar_month_rounded,
                    size: 23,
                    color: const Color(0xFF5B8FF5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    past ? '지난 일정' : '다가오는 일정',
                    style: const TextStyle(
                      color: Color(0xFF182438),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Text(
                    past ? '지난 예약 내역이 없어요.' : '예정된 예약이 없어요.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7182A1),
                    ),
                  ),
                ),
              for (final item in items)
                _ReservationCard(
                  item: item,
                  onDetails: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => PatientReservationDetailScreen(
                          id: item.id,
                          repository: widget.repository!,
                        ),
                      ),
                    );
                    if (mounted) await _reload();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: widget.embedded
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              foregroundColor: const Color(0xFF182438),
              elevation: 0,
              title: const Text(
                '예약 목록',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 21),
              ),
              actions: [
                IconButton(
                  tooltip: '새로고침',
                  onPressed: widget.repository == null ? null : _reload,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                const SizedBox(width: 4),
              ],
              bottom: const TabBar(
                labelColor: Color(0xFF286BFF),
                unselectedLabelColor: Color(0xFF7182A1),
                indicatorColor: Color(0xFF286BFF),
                indicatorWeight: 3,
                labelStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: '예정된 예약'),
                  Tab(text: '지난 예약'),
                ],
              ),
            ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/reservation/backgrounds/reservation_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
          TabBarView(
            children: [_reservationList(false), _reservationList(true)],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2854BD),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          onPressed: () async {
            await Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => ReservationScreen(
                  showListAction: false,
                  repository: widget.repository,
                ),
              ),
            );
            if (mounted) await _reload();
          },
          icon: const Icon(Icons.add_rounded, size: 23),
          label: const Text('진료 예약'),
        ),
      ),
    ),
  );
}

class _EmptyReservationList extends StatelessWidget {
  const _EmptyReservationList({required this.past});
  final bool past;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      past ? '지난 예약 내역이 없어요.' : '예정된 예약이 없어요.',
      style: const TextStyle(fontSize: 14, color: Color(0xFF7182A1)),
    ),
  );
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.item, required this.onDetails});

  final PatientReservation item;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A467BC0),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.statusLabel,
                style: const TextStyle(
                  color: Color(0xFF286BFF),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Spacer(),
            const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFF0F6FF),
              child: Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF7AA7F5),
                size: 25,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          item.dateLabel,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF182438),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '예약번호 ${item.id} · ${item.applicantName}',
          style: const TextStyle(fontSize: 14, color: Color(0xFF667895)),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onDetails,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF286BFF),
            side: const BorderSide(color: Color(0xFF286BFF)),
            minimumSize: const Size(0, 39),
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.chevron_right_rounded, size: 19),
          label: const Text(
            '예약 상세 보기',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
