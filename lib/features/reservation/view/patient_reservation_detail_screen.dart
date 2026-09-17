import 'package:flutter/material.dart';

import '../model/patient_reservation.dart';
import '../model/reservation_change_request.dart';
import '../repository/reservation_repository.dart';
import 'questionnaire_screen.dart';
import 'reservation_change_screen.dart';

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
    extends State<PatientReservationDetailScreen>
    with WidgetsBindingObserver {
  late Future<PatientReservation> _detail = widget.repository.getReservation(
    widget.id,
  );
  bool _busy = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.openQuestionnaire) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _questionnaire();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && !_busy) _reload();
  }

  void _reload() => setState(() {
    _error = null;
    _detail = widget.repository.getReservation(widget.id);
  });

  Future<void> _questionnaire() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QuestionnaireScreen(
          reservationId: widget.id,
          repository: widget.repository,
        ),
      ),
    );
    if (!mounted || submitted != true) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
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
      if (result != null && mounted) _reload();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(PatientReservation item) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('예약을 취소할까요?'),
        content: const Text('취소하면 예약을 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('돌아가기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('예약 취소'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _sending = true;
    });
    try {
      final updated = await widget.repository.cancelReservation(widget.id);
      if (!mounted) return;
      setState(() {
        _detail = Future.value(
          updated.withNames(
            doctorName: item.doctorName,
            departmentName: item.departmentName,
          ),
        );
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = reservationErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FBFF),
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      foregroundColor: const Color(0xFF182438),
      title: const Text(
        '예약 상세',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          onPressed: _busy ? null : _reload,
          icon: const Icon(Icons.refresh_rounded),
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
            child: FilledButton(onPressed: _reload, child: const Text('다시 시도')),
          );
        }
        final item = snapshot.data!;
        final canManage = item.canCancel(DateTime.now());
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x09467BC0),
                      blurRadius: 14,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        item.statusLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF286BFF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      item.dateLabel,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF182438),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '한국 시간 기준',
                      style: TextStyle(fontSize: 13, color: Color(0xFF7182A1)),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE7EDF7)),
                    const SizedBox(height: 10),
                    _DetailRow(label: '예약번호', value: '${item.id}'),
                    _DetailRow(label: '신청자', value: item.applicantName),
                    _DetailRow(
                      label: '진료과',
                      value: item.departmentName ?? '확인 필요',
                    ),
                    _DetailRow(label: '의료진', value: item.doctorName ?? '확인 필요'),
                  ],
                ),
              ),
              if (item.latestChangeRequest != null) ...[
                const SizedBox(height: 12),
                _ChangeRequestNotice(request: item.latestChangeRequest!),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _busy ? null : _questionnaire,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF286BFF),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.assignment_outlined, size: 20),
                label: const Text(
                  '문진표 작성·확인',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed:
                    !canManage ||
                        _busy ||
                        item.doctorId == null ||
                        item.latestChangeRequest?.status == 'PENDING'
                    ? null
                    : () => _change(item),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '예약 변경',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: !canManage || _busy ? null : () => _cancel(item),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '예약 취소',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              if (_sending)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF7182A1)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF182438),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ChangeRequestNotice extends StatelessWidget {
  const _ChangeRequestNotice({required this.request});
  final ReservationChangeRequest request;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F6FF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      '${request.statusLabel}\n변경 요청 시간: ${request.dateLabel}',
      style: const TextStyle(
        fontSize: 13,
        height: 1.5,
        color: Color(0xFF4165A8),
      ),
    ),
  );
}
