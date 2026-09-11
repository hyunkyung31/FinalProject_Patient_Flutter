/// 화면 검토용 데이터. 서버 응답 모델과 실제 예약 내역으로 사용하지 않습니다.
class ReservationPreview {
  const ReservationPreview({required this.date, required this.completed});

  final DateTime date;
  final bool completed;
  String get status => completed ? '진료 완료' : '예약 확정';
  String get dateLabel => '${date.year}.${_two(date.month)}.${_two(date.day)}';
  String get timeLabel => '${_two(date.hour)}:${_two(date.minute)}';
  String get hospital => '예시 병원';
  String get department => '순환기내과';
  String get doctor => '예시 의료진';

  static String _two(int value) => value.toString().padLeft(2, '0');
}
