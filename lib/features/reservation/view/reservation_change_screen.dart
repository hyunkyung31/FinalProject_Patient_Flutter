import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../model/booking_options.dart';
import '../model/patient_reservation.dart';
import '../model/reservation_change_request.dart';
import '../repository/reservation_repository.dart';
import '../widgets/booking_slot_picker.dart';

class ReservationChangeScreen extends StatefulWidget {
  const ReservationChangeScreen({
    super.key,
    required this.repository,
    required this.reservation,
  });
  final ReservationRepository repository;
  final PatientReservation reservation;

  @override
  State<ReservationChangeScreen> createState() =>
      _ReservationChangeScreenState();
}

class _ReservationChangeScreenState extends State<ReservationChangeScreen> {
  final reason = TextEditingController();
  List<DoctorCalendarDay> days = [];
  List<BookingSlot> slots = [];
  DateTime? date;
  BookingSlot? slot;
  bool loading = false;
  bool submitting = false;
  bool locked = false;
  String? error;
  bool get busy => loading || submitting;

  @override
  void initState() {
    super.initState();
    _calendar();
  }

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  Future<void> _calendar() async {
    final doctorId = widget.reservation.doctorId;
    if (doctorId == null) {
      setState(() => error = '의료진 정보를 확인할 수 없어요. 예약 상세를 다시 확인해 주세요.');
      return;
    }
    setState(() {
      loading = true;
      days = [];
      slots = [];
      date = null;
      slot = null;
      error = null;
    });
    try {
      final result = await widget.repository.getCalendar(doctorId);
      if (mounted) setState(() => days = result);
    } catch (e) {
      if (mounted) setState(() => error = reservationErrorMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _date(DateTime selected) async {
    if (busy ||
        !days.any(
          (day) => day.isBookingDay && DateUtils.isSameDay(day.date, selected),
        )) {
      return;
    }
    setState(() {
      date = selected;
      slot = null;
      slots = [];
      loading = true;
      error = null;
    });
    try {
      final result = await widget.repository.getSlots(
        widget.reservation.doctorId!,
        date: selected,
      );
      if (mounted) {
        setState(() {
          // 기존 예약 시간은 변경 후보에서 제외합니다.
          slots = result
              .where(
                (item) => !item.startsAt.isAtSameMomentAs(
                  widget.reservation.reservedAt,
                ),
              )
              .toList();
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = reservationErrorMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _submit() async {
    final selected = slot;
    if (busy || locked || selected == null) return;
    if (!widget.reservation.canCancel(DateTime.now()) ||
        !selected.isAvailable ||
        !selected.startsAt.isAfter(DateTime.now().toUtc()) ||
        !DateUtils.isSameDay(selected.koreanDate, date)) {
      setState(() {
        slot = null;
        error = '선택한 시간은 더 이상 예약할 수 없어요. 다른 시간을 선택해 주세요.';
      });
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('예약 변경을 요청할까요?'),
        content: Text('변경 요청: ${selected.label}\n병원 확인 전까지 기존 예약은 유지돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('돌아가기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('변경 요청'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() {
      submitting = true;
      error = null;
    });
    try {
      final result = await widget.repository.requestReservationChange(
        reservationId: widget.reservation.id,
        requestedAt: selected.startsAt,
        reason: reason.text.trim(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFEAF3FF),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF286BFF),
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '변경 요청이 제출되었습니다',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                '승인 결과는 알림으로 안내드릴게요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF7182A1)),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop<ReservationChangeRequest>(result);
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      if (data is Map && data['code'] == 'RESERVATION_SLOT_UNAVAILABLE') {
        setState(() {
          slot = null;
          error = '선택한 시간이 마감되었어요. 다른 시간을 선택해 주세요.';
        });
        await _calendar();
      } else {
        setState(
          () => error = data is Map && data['detail'] is String
              ? data['detail'] as String
              : reservationErrorMessage(e),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = reservationErrorMessage(e));
    } finally {
      if (mounted) setState(() => submitting = false);
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
        '예약 변경',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _CurrentReservationCard(reservation: widget.reservation),
          const SizedBox(height: 14),
          const Text(
            '같은 의료진의 다른 날짜와 시간으로 변경을 요청할 수 있어요.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF7182A1),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          if (loading && days.isEmpty) const LinearProgressIndicator(),
          BookingSlotPicker(
            calendarDays: days,
            selectedDate: date,
            slots: slots,
            selectedSlot: slot,
            doctorName: widget.reservation.doctorName ?? '',
            enabled: !busy && !locked,
            onDateSelected: _date,
            onSlotSelected: (value) {
              if (!busy && !locked) setState(() => slot = value);
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: reason,
            enabled: !busy && !locked,
            maxLength: 500,
            maxLines: 2,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              labelText: '변경 사유 (선택)',
              labelStyle: const TextStyle(fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE4ECFA)),
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                error!,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          FilledButton(
            onPressed: busy || locked || slot == null ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: const Color(0xFF286BFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              submitting ? '처리 중...' : '변경 요청',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CurrentReservationCard extends StatelessWidget {
  const _CurrentReservationCard({required this.reservation});
  final PatientReservation reservation;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE4ECFA)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reservation.departmentName ?? '진료과 확인 필요',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF182438),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '의료진   ${reservation.doctorName ?? '확인 필요'}',
          style: const TextStyle(fontSize: 13, color: Color(0xFF536580)),
        ),
        Text(
          '현재 예약   ${reservation.dateLabel}',
          style: const TextStyle(fontSize: 13, color: Color(0xFF536580)),
        ),
      ],
    ),
  );
}
