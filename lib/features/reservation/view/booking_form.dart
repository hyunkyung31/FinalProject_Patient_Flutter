import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../model/booking_options.dart';
import '../model/reservation_applicant.dart';
import '../repository/reservation_repository.dart';
import 'patient_reservation_detail_screen.dart';
import '../widgets/booking_slot_picker.dart';
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
  List<DepartmentOption> _departments = [];
  List<DoctorOption> _doctors = [];
  List<BookingSlot> _slots = [];
  List<DoctorCalendarDay> _calendarDays = [];
  DateTime? _selectedDate;
  DepartmentOption? _department;
  DoctorOption? _doctor;
  BookingSlot? _slot;
  BookingVerification? _verification;
  ReservationApplicant? _applicant;
  bool? _linked;
  bool _busy = false;
  bool _initialError = false;
  bool _uncertain = false;
  String? _error;
  final _firstVisitName = TextEditingController();
  final _firstVisitBirthDate = TextEditingController();
  final _firstVisitContact = TextEditingController();

  @override
  void initState() {
    super.initState();
    _verification = widget.initialVerification;
    _firstVisitContact.text = _verification?.verifiedPhoneNumber ?? '';
    _initialize();
  }

  @override
  void dispose() {
    _firstVisitName.dispose();
    _firstVisitBirthDate.dispose();
    _firstVisitContact.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _busy = true;
      _error = null;
      _initialError = false;
    });
    try {
      final departments = await widget.repository.getDepartments();
      ReservationApplicant? applicant;
      if (widget.linked) {
        applicant = await widget.repository.getReservationApplicant();
      }
      if (!mounted) return;
      setState(() {
        _departments = departments;
        _applicant = applicant;
        _linked = widget.linked;
      });
    } catch (error) {
      debugPrint('Reservation initialization failed: $error');
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

  ReservationApplicant? _firstVisitApplicant() {
    final name = _firstVisitName.text.trim();
    final contact = _firstVisitContact.text.trim();
    final digits = _firstVisitBirthDate.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (name.isEmpty || contact.isEmpty || digits.length != 8) return null;
    final birthDate =
        '${digits.substring(0, 4)}-${digits.substring(4, 6)}-${digits.substring(6, 8)}';
    return ReservationApplicant(
      name: name,
      birthDate: birthDate,
      contact: contact,
    );
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

      setState(() {
        _verification = result;
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
    if (_busy || _uncertain) return;
    final slot = _slot;
    final doctor = _doctor;
    final applicant = _applicant ?? _firstVisitApplicant();
    if (slot == null ||
        doctor == null ||
        applicant == null ||
        _linked == null) {
      setState(
        () => _error =
            '\uC608\uC57D \uC2E0\uCCAD\uC790 \uC815\uBCF4\uB97C \uBAA8\uB450 \uC785\uB825\uD574 \uC8FC\uC138\uC694.',
      );
      return;
    }
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
            '${_department!.name} · ${doctor.name}\n${slot.label} (한국 시간)\n신청자: ${applicant.name}\n\n병원 승인 후 예약이 확정됩니다.',
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
        name: applicant.name,
        birthDate: applicant.birthDate,
        contact: applicant.contact,
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

  @override
  Widget build(BuildContext context) {
    if (_linked == null && _busy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_initialError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '\uC608\uC57D \uC815\uBCF4\uB97C \uBD88\uB7EC\uC624\uC9C0 \uBABB\uD588\uC5B4\uC694.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (_error != null) Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _initialize,
                child: const Text('\uB2E4\uC2DC \uC2DC\uB3C4'),
              ),
            ],
          ),
        ),
      );
    }
    final compact = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    Widget card(int step, String title, Widget child) => Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: EdgeInsets.all(compact ? 13 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4ECFA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: const Color(0xFFEAF3FF),
                child: Text(
                  '$step',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF286BFF),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF182438),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text(
          '\uC9C4\uB8CC \uC608\uC57D\uC744 \uC2DC\uC791\uD574 \uBCFC\uAE4C\uC694?',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: Color(0xFF182438),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          '\uAC04\uD3B8\uD55C \uC21C\uC11C\uB85C \uC608\uC57D\uD560 \uC218 \uC788\uC5B4\uC694.',
          style: TextStyle(fontSize: 14, color: Color(0xFF7182A1)),
        ),
        const SizedBox(height: 16),
        card(
          1,
          '\uC9C4\uB8CC\uACFC \uC120\uD0DD',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '\uC9C4\uB8CC\uB97C \uBC1B\uC744 \uC9C4\uB8CC\uACFC\uB97C \uC120\uD0DD\uD574 \uC8FC\uC138\uC694.',
                style: TextStyle(fontSize: 13, color: Color(0xFF7182A1)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final item in _departments)
                    ChoiceChip(
                      label: Text(
                        item.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                      selected: _department?.id == item.id,
                      selectedColor: const Color(0xFFEAF3FF),
                      onSelected: _busy ? null : (_) => _selectDepartment(item),
                    ),
                ],
              ),
            ],
          ),
        ),
        card(
          2,
          '\uC758\uB8CC\uC9C4 \uC120\uD0DD',
          Column(
            children: [
              if (_department == null)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '\uC9C4\uB8CC\uACFC\uB97C \uBA3C\uC800 \uC120\uD0DD\uD574 \uC8FC\uC138\uC694.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF7182A1)),
                  ),
                ),
              for (final doctor in _doctors)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundImage: AssetImage(
                      'assets/images/reservation/doctors/doctor_default_male.png',
                    ),
                  ),
                  title: Text(
                    doctor.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: doctor.title == null
                      ? null
                      : Text(
                          doctor.title!,
                          style: const TextStyle(fontSize: 13),
                        ),
                  trailing: Icon(
                    _doctor?.id == doctor.id
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: _doctor?.id == doctor.id
                        ? const Color(0xFF286BFF)
                        : const Color(0xFF7182A1),
                  ),
                  onTap: _busy ? null : () => _selectDoctor(doctor),
                ),
            ],
          ),
        ),
        card(
          3,
          '\uB0A0\uC9DC\u00B7\uC2DC\uAC04 \uC120\uD0DD',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '\uC624\uB298\uBD80\uD130 90\uC77C \uC774\uB0B4 \u00B7 \uD55C\uAD6D \uC2DC\uAC04 \uAE30\uC900',
                style: TextStyle(fontSize: 13, color: Color(0xFF7182A1)),
              ),
              const SizedBox(height: 8),
              if (_doctor == null)
                const Text(
                  '\uC758\uB8CC\uC9C4\uC744 \uBA3C\uC800 \uC120\uD0DD\uD574 \uC8FC\uC138\uC694.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF7182A1)),
                ),
              if (_calendarDays.isNotEmpty)
                BookingSlotPicker(
                  calendarDays: _calendarDays,
                  selectedDate: _selectedDate,
                  slots: _slots,
                  selectedSlot: _slot,
                  doctorName: _doctor?.name ?? '',
                  enabled: !_busy,
                  onDateSelected: _selectDate,
                  onSlotSelected: (value) {
                    if (_busy || (value != null && !value.isAvailable)) return;
                    setState(() => _slot = value);
                  },
                ),
            ],
          ),
        ),
        card(
          4,
          '\uC2E0\uCCAD\uC790 \uC815\uBCF4',
          _linked == false
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '\uC644\uC804 \uCD08\uC9C4 \uC608\uC57D\uC744 \uC704\uD574 \uC815\uBCF4\uB97C \uC785\uB825\uD574 \uC8FC\uC138\uC694.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF7182A1)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _firstVisitName,
                      enabled: !_busy,
                      decoration: const InputDecoration(
                        labelText: '\uC774\uB984',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 9),
                    TextField(
                      controller: _firstVisitBirthDate,
                      enabled: !_busy,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '\uC0DD\uB144\uC6D4\uC77C',
                        hintText: 'YYYYMMDD',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 9),
                    TextField(
                      controller: _firstVisitContact,
                      enabled: !_busy,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: '\uC5F0\uB77D\uCC98',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                )
              : _applicant == null
              ? const Text(
                  '\uD658\uC790 \uC815\uBCF4\uB97C \uBD88\uB7EC\uC624\uB294 \uC911\uC774\uC5D0\uC694.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\uC774\uB984   ${_applicant!.name}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '\uC0DD\uB144\uC6D4\uC77C   ${_applicant!.birthDateLabel}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '\uC5F0\uB77D\uCC98   ${_applicant!.contact}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _busy || _uncertain || _slot == null || !_slot!.isAvailable
              ? null
              : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF286BFF),
            minimumSize: const Size.fromHeight(50),
          ),
          child: Text(
            _busy ? '\uCC98\uB9AC \uC911...' : '\uC608\uC57D \uC2E0\uCCAD',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _legacyBuild(BuildContext context) {
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
    return ListView(
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
        if (_linked == false && _verification?.isValid(DateTime.now()) != true)
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
                onSelected: _busy ? null : (_) => _selectDepartment(department),
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
        _ApplicantInfoCard(applicant: _applicant),
        const SizedBox(height: 24),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        FilledButton(
          onPressed: _busy || _uncertain || _slot == null || !_slot!.isAvailable
              ? null
              : _submit,
          child: Text(_busy ? '처리 중…' : '예약 신청'),
        ),
      ],
    );
  }
}

class _ApplicantInfoCard extends StatelessWidget {
  const _ApplicantInfoCard({required this.applicant});

  final ReservationApplicant? applicant;

  @override
  Widget build(BuildContext context) {
    final value = applicant;
    if (value == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '등록 환자 정보',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _ApplicantInfoRow(label: '이름', value: value.name),
            _ApplicantInfoRow(label: '생년월일', value: value.birthDateLabel),
            _ApplicantInfoRow(label: '연락처', value: value.contact),
            const SizedBox(height: 8),
            const Text(
              '정보 변경은 내 정보의 환자정보 수정에서 할 수 있어요.',
              style: TextStyle(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicantInfoRow extends StatelessWidget {
  const _ApplicantInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.mutedText),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
