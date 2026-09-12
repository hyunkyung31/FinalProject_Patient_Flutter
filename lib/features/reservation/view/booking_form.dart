import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../model/booking_options.dart';
import '../repository/reservation_repository.dart';
import 'patient_reservation_detail_screen.dart';
import '../widgets/booking_slot_picker.dart';
import 'package:flutter/services.dart';
import '../../verification/view/phone_verification_screen.dart';

class BookingForm extends StatefulWidget {
  const BookingForm({
    super.key,
    required this.repository,
    required this.linked,
    this.initialVerification,
  });
  final ReservationRepository repository;
  final bool linked;
  final BookingVerification? initialVerification;
  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _birth = TextEditingController();
  final _contact = TextEditingController();
  List<DepartmentOption> _departments = [];
  List<DoctorOption> _doctors = [];
  List<BookingSlot> _slots = [];
  List<DoctorCalendarDay> _calendarDays = [];
  DateTime? _selectedDate;
  DepartmentOption? _department;
  DoctorOption? _doctor;
  BookingSlot? _slot;
  BookingVerification? _verification;
  bool? _linked;
  bool _busy = false;
  bool _initialError = false;
  bool _uncertain = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verification = widget.initialVerification;
    final phone = _verification?.verifiedPhoneNumber;
    if (phone != null) {
      _contact.text = phone.startsWith('+82')
          ? '0${phone.substring(3)}'
          : phone;
    }
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _busy = true;
      _error = null;
      _initialError = false;
    });
    try {
      final departments = await widget.repository.getDepartments();
      if (!mounted) return;
      setState(() {
        _departments = departments;
        _linked = widget.linked;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _initialError = true;
          _error = reservationErrorMessage(error);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _selectDepartment(DepartmentOption item) async {
    if (_busy) return;
    setState(() {
      _department = item;
      _doctor = null;
      _slot = null;
      _doctors = [];
      _slots = [];
      _calendarDays = [];
      _selectedDate = null;
      _busy = true;
      _error = null;
    });
    try {
      final doctors = await widget.repository.getDoctors(item.id);
      if (mounted) setState(() => _doctors = doctors);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = '${reservationErrorMessage(error)}\n진료과를 다시 선택해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _selectDoctor(DoctorOption item) async {
    if (_busy) return;
    setState(() {
      _doctor = item;
      _slot = null;
      _slots = [];
      _calendarDays = [];
      _selectedDate = null;
      _busy = true;
      _error = null;
    });

    try {
      final days = await widget.repository.getCalendar(item.id);

      if (!mounted) return;

      setState(() {
        _calendarDays = days;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error =
            '${reservationErrorMessage(error)}\n'
            '의료진을 다시 선택해 주세요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _selectDate(DateTime date) async {
    final doctor = _doctor;

    if (doctor == null || _busy) return;
    if (!_calendarDays.any(
      (day) => day.isBookingDay && DateUtils.isSameDay(day.date, date),
    )) {
      return;
    }

    setState(() {
      _selectedDate = date;
      _slot = null;
      _slots = [];
      _busy = true;
      _error = null;
    });

    try {
      final slots = await widget.repository.getSlots(doctor.id, date: date);

      if (!mounted) return;

      setState(() {
        _slots = slots;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error =
            '${reservationErrorMessage(error)}\n'
            '날짜를 다시 선택해 주세요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _verify() async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final result = await Navigator.of(context).push<BookingVerification>(
        MaterialPageRoute<BookingVerification>(
          builder: (_) =>
              PhoneVerificationScreen(repository: widget.repository),
        ),
      );

      if (!mounted || result == null) {
        return;
      }

      if (!result.isValid(DateTime.now())) {
        setState(() {
          _error = '인증이 만료됐어요. 다시 인증해 주세요.';
        });
        return;
      }

      final phone = result.verifiedPhoneNumber;
      final localPhone = phone != null && phone.startsWith('+82')
          ? '0${phone.substring(3)}'
          : phone;

      setState(() {
        _verification = result;

        if (localPhone != null) {
          _contact.text = localPhone;
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('휴대폰 인증이 완료됐어요.')));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_busy || _uncertain || !_form.currentState!.validate()) return;
    final slot = _slot;
    final doctor = _doctor;
    if (slot == null || doctor == null || _linked == null) return;
    if (!slot.isAvailable ||
        !DateUtils.isSameDay(slot.koreanDate, _selectedDate)) {
      setState(() {
        _slot = null;
        _error = '선택한 시간을 예약할 수 없어요. 날짜와 시간을 다시 선택해 주세요.';
      });
      return;
    }
    if (!slot.startsAt.isAfter(DateTime.now().toUtc())) {
      setState(() {
        _slot = null;
        _error = '선택한 시간이 지났어요. 일정을 다시 선택해 주세요.';
      });
      return;
    }
    if (!_linked! && _verification?.isValid(DateTime.now()) != true) {
      setState(() {
        _verification = null;
        _error = '유효한 본인인증이 필요해요. 인증 상태를 다시 확인해 주세요.';
      });
      await _verify();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('예약을 신청할까요?'),
          content: Text(
            '${_department!.name} · ${doctor.name}\n${slot.label} (한국 시간)\n신청자: ${_name.text.trim()}\n\n병원 승인 후 예약이 확정됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('돌아가기'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('신청하기'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      final result = await widget.repository.createReservation(
        doctorId: doctor.id,
        reservedAt: slot.startsAt,
        name: _name.text.trim(),
        birthDate: _birthDateForApi(),
        contact: _contact.text.trim(),
        verificationId: _linked! ? null : _verification!.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('예약 신청이 접수됐어요. 예약 상태를 확인해 주세요.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PatientReservationDetailScreen(
            id: result.id,
            repository: widget.repository,
            openQuestionnaire: true,
          ),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      final data = error.response?.data;
      if (data is Map && data['code'] == 'RESERVATION_SLOT_UNAVAILABLE') {
        setState(() {
          _slot = null;
          _slots = [];
          _error = '선택한 시간이 마감되었거나 진료 일정이 변경됐어요. 다른 시간을 선택해 주세요.';
        });
        try {
          final days = await widget.repository.getCalendar(doctor.id);
          if (!mounted) return;
          final date = _selectedDate;
          final canBookDate =
              date != null &&
              days.any(
                (day) =>
                    day.isBookingDay && DateUtils.isSameDay(day.date, date),
              );
          final slots = canBookDate
              ? await widget.repository.getSlots(doctor.id, date: date)
              : <BookingSlot>[];
          if (!mounted) return;
          setState(() {
            _calendarDays = days;
            _slots = slots;
            if (!canBookDate) _selectedDate = null;
          });
        } catch (_) {
          if (mounted) {
            setState(() => _error = '선택한 시간을 예약할 수 없어요. 일정 새로고침으로 다시 확인해 주세요.');
          }
        }
      } else if (error.response?.statusCode == 400) {
        final detail = data is Map ? data['detail'] : null;
        setState(() {
          _error = detail is String
              ? detail
              : '입력한 이름·생년월일·연락처와 선택한 일정을 확인해 주세요.';
          // 시간 충돌·인증 만료 이후에는 다시 선택·확인하도록 합니다.
          _slot = null;
          if (!_linked!) _verification = null;
        });
      } else {
        setState(() {
          _uncertain =
              error.response == null ||
              (error.response!.statusCode ?? 500) >= 500;
          _error = _uncertain
              ? '접수 여부를 확인하지 못했어요. 중복 신청하지 말고 예약 목록에서 먼저 확인해 주세요.'
              : reservationErrorMessage(error);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _uncertain = true;
          _error = '접수 결과를 확인하지 못했어요. 예약 목록에서 먼저 확인해 주세요.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _birthError(String? value) {
    final text = value?.trim() ?? '';
    if (!RegExp(r'^\d{8}$').hasMatch(text)) {
      return "생년월일을 숫자 8자리로 입력해주세요.";
    }

    final year = int.parse(text.substring(0, 4));
    final month = int.parse(text.substring(4, 6));
    final day = int.parse(text.substring(6, 8));
    final date = DateTime(year, month, day);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (year < 1900 ||
        date.year != year ||
        date.month != month ||
        date.day != day ||
        date.isAfter(today)) {
      return "올바른 생년월일을 입력해 주세요.";
    }
    return null;
  }

  String _birthDateForApi() {
    final text = _birth.text.trim();
    return "${text.substring(0, 4)}-"
        "${text.substring(4, 6)}-"
        "${text.substring(6, 8)}";
  }

  @override
  void dispose() {
    _name.dispose();
    _birth.dispose();
    _contact.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_linked == null && _busy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_initialError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            FilledButton(onPressed: _initialize, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            '진료 예약을 시작해 볼까요?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 16),
          if (_linked == false &&
              _verification?.isValid(DateTime.now()) != true)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('인증이 만료됐어요. 입력한 예약 정보는 유지돼요.'),
                    const SizedBox(height: 8),
                    Text(
                      _verification?.isValid(DateTime.now()) == true
                          ? '사용 가능한 인증 기록이 있어요.'
                          : '유효한 인증 기록이 없어요.',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _busy ? null : _verify,
                      child: const Text('휴대폰 인증'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            '1. 진료과 선택',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final department in _departments)
                ChoiceChip(
                  label: Text(department.name),
                  selected: _department?.id == department.id,
                  onSelected: _busy
                      ? null
                      : (_) => _selectDepartment(department),
                ),
            ],
          ),
          if (_departments.isEmpty) const Text('현재 선택할 수 있는 진료과가 없어요.'),
          const SizedBox(height: 24),
          const Text(
            '2. 의료진 선택',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (_department == null) const Text('진료과를 먼저 선택해 주세요.'),
          for (final doctor in _doctors)
            Card(
              child: ListTile(
                title: Text(doctor.name),
                subtitle: doctor.title == null ? null : Text(doctor.title!),
                trailing: _doctor?.id == doctor.id
                    ? const Icon(Icons.check_circle, color: AppColors.blue)
                    : const Icon(Icons.circle_outlined),
                onTap: _busy ? null : () => _selectDoctor(doctor),
              ),
            ),
          if (_department != null && _doctors.isEmpty && !_busy)
            const Text('현재 선택할 수 있는 의료진이 없어요.'),
          const SizedBox(height: 24),
          const Text(
            '3. 날짜·시간 선택',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const Text('오늘부터 90일 이내 · 한국 시간 기준'),
          if (_doctor == null) const Text('의료진을 먼저 선택해 주세요.'),
          if (_calendarDays.isNotEmpty)
            BookingSlotPicker(
              calendarDays: _calendarDays,
              selectedDate: _selectedDate,
              slots: _slots,
              selectedSlot: _slot,
              enabled: !_busy,
              onDateSelected: _selectDate,
              onSlotSelected: (slot) {
                if (_busy) return;
                if (slot != null &&
                    (!slot.isAvailable ||
                        !DateUtils.isSameDay(slot.koreanDate, _selectedDate))) {
                  return;
                }
                setState(() {
                  _slot = slot;
                });
              },
            ),
          if (_doctor != null && _calendarDays.isEmpty && !_busy)
            const Text('조회 기간에 등록된 진료 일정이 없어요.'),
          if (_doctor != null)
            TextButton(
              onPressed: _busy ? null : () => _selectDoctor(_doctor!),
              child: const Text('일정 새로고침'),
            ),
          const SizedBox(height: 24),
          const Text(
            '4. 신청자 정보',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          TextFormField(
            controller: _name,
            enabled: !_busy,
            maxLength: 100,
            decoration: const InputDecoration(labelText: '이름'),
            validator: (value) =>
                value == null || value.trim().isEmpty ? '이름을 입력해 주세요.' : null,
          ),
          TextFormField(
            controller: _birth,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            decoration: const InputDecoration(
              labelText: "생년월일 8자리",
              hintText: "19950420",
              helperText: "숫자만 입력해 주세요.",
            ),
            validator: _birthError,
          ),
          TextFormField(
            controller: _contact,
            enabled: !_busy,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: '연락처',
              hintText: '010-1234-5678',
            ),
            validator: (value) =>
                RegExp(
                  r'^0\d{8,10}$',
                ).hasMatch((value ?? '').replaceAll(RegExp(r'[-\s]'), ''))
                ? null
                : '연락처를 확인해 주세요.',
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          FilledButton(
            onPressed:
                _busy || _uncertain || _slot == null || !_slot!.isAvailable
                ? null
                : _submit,
            child: Text(_busy ? '처리 중…' : '예약 신청'),
          ),
        ],
      ),
    );
  }
}
