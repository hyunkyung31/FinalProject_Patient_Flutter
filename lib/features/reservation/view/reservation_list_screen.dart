import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../core/theme/app_colors.dart';
import 'reservation_screen.dart';
import '../model/reservation_preview.dart';
import '../widgets/reservation_card.dart';
import '../model/patient_reservation.dart';
import '../repository/reservation_repository.dart';
import 'patient_reservation_detail_screen.dart';

class ReservationListScreen extends StatefulWidget {
  const ReservationListScreen({super.key, this.repository});
  final ReservationRepository? repository;

  @override
  State<ReservationListScreen> createState() => _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen> {
  bool _preview = false;
  late Future<List<PatientReservation>>? _reservations = widget.repository
      ?.getReservations();

  Future<void> _reload() async {
    final repository = widget.repository;
    if (repository == null) return;
    final future = repository.getReservations();
    setState(() {
      _reservations = future;
    });
    // FutureBuilder가 오류를 표시합니다. 당겨서 새로고침에서도 오류를 중복 전파하지 않습니다.
    try {
      await future;
    } catch (_) {}
  }

  Widget _liveList(bool past) {
    if (_reservations == null) return _ReservationPlaceholder(past: past);
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reservationErrorMessage(snapshot.error!),
                    textAlign: TextAlign.center,
                  ),
                  FilledButton(onPressed: _reload, child: const Text('다시 시도')),
                ],
              ),
            ),
          );
        }
        final now = DateTime.now();
        final items =
            snapshot.data!.where((item) => item.isPast(now) == past).toList()
              ..sort(
                (a, b) => past
                    ? b.reservedAt.compareTo(a.reservedAt)
                    : a.reservedAt.compareTo(b.reservedAt),
              );
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                past ? '지난 일정과 취소된 예약 · 한국 시간 기준' : '다가오는 일정 · 한국 시간 기준',
                style: const TextStyle(color: AppColors.mutedText),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 64),
                  child: Text(
                    past ? '지난 예약 내역이 없어요.' : '예정된 예약이 없어요.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final item in items)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.statusLabel,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.dateLabel,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('예약번호 ${item.id} · ${item.applicantName}'),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () async {
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
                          child: const Text('예약 상세 보기'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  late final DateTime _today = DateTime.now();

  Widget _previewList(bool past) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Text(
        '디자인 확인용 예시이며 실제 예약이 아닙니다.',
        style: TextStyle(color: AppColors.navy, height: 1.5),
      ),
      const SizedBox(height: 16),
      ReservationCard(
        reservation: ReservationPreview(
          date: DateTime(
            _today.year,
            _today.month,
            _today.day + (past ? -7 : 7),
            10,
            30,
          ),
          completed: past,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('예약 목록'),
        actions: [
          if (widget.repository != null)
            IconButton(
              tooltip: '새로고침',
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
            ),
        ],
        bottom: const TabBar(
          labelColor: AppColors.navy,
          unselectedLabelColor: AppColors.mutedText,
          indicatorColor: AppColors.blue,
          tabs: [
            Tab(text: '예정된 예약'),
            Tab(text: '지난 예약'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (kDebugMode)
            SwitchListTile(
              title: const Text('예시 화면 보기'),
              subtitle: const Text('개발용 · 실제 예약 내역과 무관합니다.'),
              value: _preview,
              onChanged: (value) => setState(() => _preview = value),
            ),
          Expanded(
            child: TabBarView(
              children: [
                _preview ? _previewList(false) : _liveList(false),
                _preview ? _previewList(true) : _liveList(true),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => ReservationScreen(
                showListAction: false,
                repository: widget.repository,
              ),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('진료 예약'),
        ),
      ),
    ),
  );
}

class _ReservationPlaceholder extends StatelessWidget {
  const _ReservationPlaceholder({required this.past});
  final bool past;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              past ? Icons.history : Icons.event_note_outlined,
              size: 44,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            past ? '지난 진료 내역을 모아볼 수 있어요' : '다가오는 진료를 확인해 보세요',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '예약 내역 조회를 준비 중이에요.\n현재는 실제 예약 내역을 표시하지 않습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText, height: 1.6),
          ),
        ],
      ),
    ),
  );
}
