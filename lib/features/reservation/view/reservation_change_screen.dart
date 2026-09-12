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
      setState(() => error = '의료진 정보를 확인하지 못했어요. 예약 상세를 다시 확인해 주세요.');
      return;
    }
    setState(() {
      loading = true;
      days = [];
      slots = [];
      date = null;
      slot = null;
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
          (d) => d.isBookingDay && DateUtils.isSameDay(d.date, selected),
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
          // 현재 예약 시각으로의 변경은 허용하지 않습니다.
          slots = result
              .where(
                (s) =>
                    !s.startsAt.isAtSameMomentAs(widget.reservation.reservedAt),
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
        error = '현재 변경할 수 없는 일정이에요. 예약과 시간을 다시 확인해 주세요.';
      });
      return;
    }
    setState(() {
      submitting = true;
      error = null;
    });
    bool dispatched = false;
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('예약 변경을 요청할까요?'),
          content: Text(
            '현재: ${widget.reservation.dateLabel}\n변경 희망: ${selected.label}\n한국 시간 기준\n\n병원 승인 전에는 기존 예약이 유지됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('돌아가기'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('변경 요청'),
            ),
          ],
        ),
      );
      if (!mounted || accepted != true) return;
      // 확인 창을 열어둔 사이 시간이 지난 경우도 차단합니다.
      if (!selected.startsAt.isAfter(DateTime.now().toUtc())) {
        setState(() {
          slot = null;
          error = '선택한 시간이 지났어요. 다시 선택해 주세요.';
        });
        return;
      }
      dispatched = true;
      final result = await widget.repository.requestReservationChange(
        reservationId: widget.reservation.id,
        requestedAt: selected.startsAt,
        reason: reason.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop<ReservationChangeRequest>(result);
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final code = data is Map ? data['code'] : null;
      final detail = data is Map ? data['detail'] : null;
      if (code == 'RESERVATION_SLOT_UNAVAILABLE') {
        setState(() {
          slot = null;
          error = '선택한 시간이 마감됐어요. 다른 시간을 선택해 주세요.';
        });
        await _calendar();
      } else {
        setState(() {
          locked =
              e.response == null ||
              (e.response?.statusCode ?? 500) >= 500 ||
              detail == '처리 대기 중인 변경 요청이 있습니다.' ||
              detail == '취소된 예약입니다.';
          error = e.response == null || (e.response?.statusCode ?? 500) >= 500
              ? '접수 여부를 확인하지 못했어요. 중복 요청하지 말고 병원에 확인해 주세요.'
              : detail is String
              ? detail
              : reservationErrorMessage(e);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          locked = dispatched;
          error = dispatched
              ? '접수 결과를 확인하지 못했어요. 중복 요청하지 말고 병원에 확인해 주세요.'
              : '변경 요청을 진행하지 못했어요.';
        });
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('예약 변경')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            widget.reservation.departmentName ?? '진료과 확인 필요',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text('의료진: ${widget.reservation.doctorName ?? '확인 필요'}'),
          Text('현재 예약: ${widget.reservation.dateLabel}'),
          const SizedBox(height: 16),
          const Text('같은 의료진의 다른 날짜·시간으로 변경을 요청할 수 있어요. 승인 전에는 기존 예약이 유지돼요.'),
          const SizedBox(height: 16),
          if (loading) const LinearProgressIndicator(),
          BookingSlotPicker(
            calendarDays: days,
            selectedDate: date,
            slots: slots,
            selectedSlot: slot,
            enabled: !busy && !locked,
            onDateSelected: _date,
            onSlotSelected: (value) {
              if (!busy && !locked) setState(() => slot = value);
            },
          ),
          TextButton(
            onPressed: busy || locked
                ? null
                : () {
                    setState(() => error = null);
                    _calendar();
                  },
            child: const Text('일정 새로고침'),
          ),
          TextField(
            controller: reason,
            enabled: !busy && !locked,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '변경 사유 (선택)',
              border: OutlineInputBorder(),
            ),
          ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: busy || locked || slot == null ? null : _submit,
            child: Text(submitting ? '처리 중…' : '예약 변경 요청'),
          ),
        ],
      ),
    ),
  );
}
