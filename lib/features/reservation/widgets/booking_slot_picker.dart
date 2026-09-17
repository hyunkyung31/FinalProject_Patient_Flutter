import 'package:flutter/material.dart';

import '../model/booking_options.dart';

class BookingSlotPicker extends StatelessWidget {
  const BookingSlotPicker({
    super.key,
    required this.calendarDays,
    required this.selectedDate,
    required this.slots,
    required this.selectedSlot,
    this.doctorName = '',
    required this.onDateSelected,
    required this.onSlotSelected,
    this.enabled = true,
  });

  final List<DoctorCalendarDay> calendarDays;
  final DateTime? selectedDate;
  final List<BookingSlot> slots;
  final BookingSlot? selectedSlot;
  final String doctorName;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<BookingSlot?> onSlotSelected;
  final bool enabled;

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  String _dateLabel(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day (${weekdays[date.weekday - 1]})';
  }

  @override
  Widget build(BuildContext context) {
    if (calendarDays.isEmpty) {
      return const Text('등록된 진료 일정이 없어요.');
    }

    final days = [...calendarDays]
      ..sort((a, b) => a.date.compareTo(b.date));

    final koreanNow = DateTime.now().toUtc().add(
      const Duration(hours: 9),
    );
    final today = DateTime(
      koreanNow.year,
      koreanNow.month,
      koreanNow.day,
    );

    bool canSelectDate(DateTime date) {
      return !date.isBefore(today) &&
          days.any(
            (day) => _sameDay(day.date, date) && day.isBookingDay,
          );
    }

    final availableDays = days
        .where((day) => canSelectDate(day.date))
        .toList();

    if (availableDays.isEmpty) {
      return const Text('조회 기간에 예약 가능한 날짜가 없어요.');
    }

    final initialDate =
        selectedDate != null && canSelectDate(selectedDate!)
        ? selectedDate!
        : availableDays.first.date;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE4ECFA)),
          ),
          child: IgnorePointer(
            ignoring: !enabled,
            child: CalendarDatePicker(
              key: ValueKey(
                '${days.first.date}-${days.last.date}-$selectedDate',
              ),
              initialDate: initialDate,
              firstDate: days.first.date,
              lastDate: days.last.date,
              selectableDayPredicate: canSelectDate,
              onDateChanged: onDateSelected,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 17, color: Color(0xFF5B8FF5)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '진료 일정에 따라 예약 가능한 날짜만 선택할 수 있어요.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF7182A1)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (selectedDate == null)
          const Text(
            '달력에서 날짜를 선택해 주세요.',
            style: TextStyle(fontSize: 14, color: Color(0xFF7182A1)),
          )
        else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4ECFA)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFEAF3FF),
                  child: Icon(Icons.calendar_month_rounded,
                      color: Color(0xFF286BFF), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7182A1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('선택한 의료진   ${doctorName.isEmpty ? '의료진' : doctorName}'),
                        const SizedBox(height: 5),
                        Text('선택한 날짜   ${_dateLabel(selectedDate!)}',
                            style: const TextStyle(
                              color: Color(0xFF182438),
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${selectedDate!.month}월 ${selectedDate!.day}일 예약 시간',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF182438),
            ),
          ),
          const SizedBox(height: 12),
          if (!enabled)
            const Center(child: CircularProgressIndicator())
          else if (slots.isEmpty)
            const Text(
              '선택한 날짜에 등록된 시간이 없어요.',
              style: TextStyle(fontSize: 14, color: Color(0xFF7182A1)),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: slots.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final slot = slots[index];
                final selectable = slot.isAvailable &&
                    slot.startsAt.isAfter(DateTime.now().toUtc());
                final selected = selectedSlot?.id == slot.id;
                return OutlinedButton(
                  onPressed: selectable
                      ? () => onSlotSelected(selected ? null : slot)
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: selected
                        ? Colors.white
                        : selectable
                            ? const Color(0xFF182438)
                            : const Color(0xFF9AA7BC),
                    backgroundColor: selected
                        ? const Color(0xFF286BFF)
                        : selectable
                            ? Colors.white
                            : const Color(0xFFF4F6FA),
                    disabledForegroundColor: const Color(0xFF9AA7BC),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFF286BFF)
                          : selectable
                              ? const Color(0xFFBED2FF)
                              : const Color(0xFFE2E7F0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: Text(
                    selectable ? slot.timeLabel : '${slot.timeLabel}  마감',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 17, color: Color(0xFF5B8FF5)),
              SizedBox(width: 6),
              Text('마감된 시간은 선택할 수 없어요.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF7182A1))),
            ],
          ),
        ],
      ],
    );
  }
}