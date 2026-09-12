import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../model/patient_reservation.dart';
import '../repository/reservation_repository.dart';
import '../model/reservation_change_request.dart';
import 'reservation_change_screen.dart';
import 'questionnaire_screen.dart';

class PatientReservationDetailScreen extends StatefulWidget {
  const PatientReservationDetailScreen({
    super.key,
    required this.id,
    required this.repository,
    this.openQuestionnaire = false,
  });
  final int id;
  final bool openQuestionnaire;
  final ReservationRepository repository;
  @override
  State<PatientReservationDetailScreen> createState() =>
      _PatientReservationDetailScreenState();
}

class _PatientReservationDetailScreenState
    extends State<PatientReservationDetailScreen> {
  late Future<PatientReservation> _detail = widget.repository.getReservation(
    widget.id,
  );
  bool _busy = false;
  bool _sending = false;
  String? _error;
  ReservationChangeRequest? _changeRequest;

  @override
  void initState() {
    super.initState();
    if (widget.openQuestionnaire) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _questionnaire();
      });
    }
  }

  void _questionnaire() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => QuestionnaireScreen(
          reservationId: widget.id,
          repository: widget.repository,
        ),
      ),
    );
  }

  Future<void> _change(PatientReservation item) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await Navigator.of(context).push<ReservationChangeRequest>(
        MaterialPageRoute(
          builder: (_) => ReservationChangeScreen(
            repository: widget.repository,
            reservation: item,
          ),
        ),
      );
      if (!mounted || result == null) return;
      setState(() {
        _changeRequest = result;
        // 변경 신청은 예약 확정 시각을 바꾸지 않습니다.
        _detail = widget.repository.getReservation(widget.id);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(PatientReservation reservation) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('예약을 취소할까요?'),
          content: Text(
            '${reservation.dateLabel} (한국 시간)\n취소하면 이 예약으로 진료받을 수 없어요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('유지하기'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('예약 취소하기'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      setState(() => _sending = true);
      final updated = await widget.repository.cancelReservation(widget.id);
      if (!mounted) return;
      setState(() {
        _detail = Future.value(
          updated.withNames(
            doctorName: reservation.doctorName,
            departmentName: reservation.departmentName,
          ),
        );
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error =
            '${reservationErrorMessage(error)}\n취소 반영 여부는 새로고침으로 확인해 주세요.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _sending = false;
        });
      }
    }
  }

  void _reload() => setState(() {
    _error = null;
    _detail = widget.repository.getReservation(widget.id);
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('예약 상세'),
      actions: [
        IconButton(
          tooltip: '새로고침',
          onPressed: _busy ? null : _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<PatientReservation>(
      future: _detail,
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
        final item = snapshot.data!;
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                item.statusLabel,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.dateLabel,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                '한국 시간 기준',
                style: TextStyle(color: AppColors.mutedText),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('예약번호  ${item.id}'),
                      const SizedBox(height: 16),
                      Text('신청자  ${item.applicantName}'),
                      const SizedBox(height: 16),
                      Text('진료과  ${item.departmentName ?? '확인하지 못했어요'}'),
                      const SizedBox(height: 16),
                      Text('의료진  ${item.doctorName ?? '확인하지 못했어요'}'),
                      if (item.cancelReason?.isNotEmpty == true) ...[
                        const SizedBox(height: 16),
                        Text('취소 사유  ${item.cancelReason}'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (item.canCancel(DateTime.now())) ...[
                OutlinedButton.icon(
                  onPressed: _busy ? null : _questionnaire,
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('문진표 작성·확인'),
                ),
                if (_changeRequest != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      '변경 요청 접수: ${_changeRequest!.dateLabel}\n'
                      '${_changeRequest!.status == 'PENDING' ? '접수 당시 상태: 변경 승인 대기' : '접수 당시 상태: ${_changeRequest!.status}'}\n'
                      '최신 승인·반려 상태 조회는 준비 중이에요. 현재 예약 시간은 위에서 확인해 주세요.',
                    ),
                  ),
                OutlinedButton(
                  onPressed:
                      _busy || item.doctorId == null || _changeRequest != null
                      ? null
                      : () => _change(item),
                  child: const Text('예약 변경'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _busy ? null : () => _cancel(item),
                  child: const Text('예약 취소'),
                ),
              ],
              if (_sending) const Center(child: CircularProgressIndicator()),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        );
      },
    ),
  );
}
