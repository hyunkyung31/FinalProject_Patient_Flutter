import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../model/patient_reservation.dart';
import '../repository/reservation_repository.dart';

class PatientReservationDetailScreen extends StatefulWidget {
  const PatientReservationDetailScreen({
    super.key,
    required this.id,
    required this.repository,
  });
  final int id;
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
                      Text(
                        '진료과  ${item.departmentName ?? '확인하지 못했어요'}',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '의료진  ${item.doctorName ?? '확인하지 못했어요'}',
                      ),
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
                const OutlinedButton(onPressed: null, child: Text('예약 변경')),
                const Text('예약 변경 기능을 준비 중이에요.', textAlign: TextAlign.center),
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
