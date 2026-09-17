class ReservationApplicant {
  const ReservationApplicant({
    required this.name,
    required this.birthDate,
    required this.contact,
  });

  final String name;
  final String birthDate;
  final String contact;

  factory ReservationApplicant.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final birthDate = json['birth_date'];
    final contact = json['contact'];
    if (name is! String ||
        name.trim().isEmpty ||
        birthDate is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(birthDate) ||
        contact is! String ||
        contact.trim().isEmpty) {
      throw const FormatException('예약에 필요한 환자 정보를 확인하지 못했어요.');
    }
    return ReservationApplicant(
      name: name.trim(),
      birthDate: birthDate,
      contact: contact.trim(),
    );
  }

  String get birthDateLabel => birthDate.replaceAll('-', '.');
}
