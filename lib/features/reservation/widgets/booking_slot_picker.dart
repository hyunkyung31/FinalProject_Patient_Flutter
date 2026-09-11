import 'package:flutter/material.dart';

import '../model/booking_options.dart';

class BookingSlotPicker extends StatelessWidget {
  const BookingSlotPicker({
    super.key,
    required this.calendarDays,
    required this.selectedDate,
    required this.slots,
    required this.selectedSlot,
    required this.onDateSelected,
    required this.onSlotSelected,
    this.enabled = true,
  });

  final List<DoctorCalendarDay> calendarDays;
  final DateTime? selectedDate;
  final List<BookingSlot> slots;
  final BookingSlot? selectedSlot;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<BookingSlot?> onSlotSelected;
  final bool enabled;

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
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
        IgnorePointer(
          ignoring: !enabled,
          child: CalendarDatePicker(
            key: ValueKey(
              '${days.first.date}-'
              '${days.last.date}-'
              '$selectedDate',
            ),
            initialDate: initialDate,
            firstDate: days.first.date,
            lastDate: days.last.date,
            selectableDayPredicate: canSelectDate,
            onDateChanged: onDateSelected,
          ),
        ),
        const Text(
          '진료 일정에 따라 예약 가능한 날짜만 선택할 수 있어요.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        if (selectedDate == null)
          const Text('달력에서 날짜를 선택해 주세요.')
        else ...[
          Text(
            '${selectedDate!.month}월 ${selectedDate!.day}일 예약 시간',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (!enabled)
            const Text('처리 중이에요.')
          else if (slots.isEmpty)
            const Text('선택한 날짜에 등록된 시간이 없어요.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slot in slots)
                  ChoiceChip(
                    label: Text(
                      slot.isAvailable &&
                              slot.startsAt.isAfter(
                                DateTime.now().toUtc(),
                              )
                          ? slot.timeLabel
                          : '${slot.timeLabel} · 예약 불가',
                    ),
                    selected: selectedSlot?.id == slot.id,
                    onSelected:
                        enabled &&
                            slot.isAvailable &&
                            slot.startsAt.isAfter(
                              DateTime.now().toUtc(),
                            )
                        ? (selected) {
                            onSlotSelected(selected ? slot : null);
                          }
                        : null,
                  ),
              ],
            ),
        ],
      ],
    );
  }
}