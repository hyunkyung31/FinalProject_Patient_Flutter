import 'package:flutter/material.dart';

import '../model/patient_prescription.dart';
import '../repository/patient_prescription_repository.dart';
import '../widgets/medication_image.dart';

class PatientPrescriptionDetailScreen extends StatefulWidget {
  const PatientPrescriptionDetailScreen({
    super.key,
    required this.repository,
    required this.prescriptionId,
    this.embedded = false,
    this.onBack,
  });

  final PatientPrescriptionRepository repository;
  final int prescriptionId;
  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<PatientPrescriptionDetailScreen> createState() =>
      _PatientPrescriptionDetailScreenState();
}

class _PatientPrescriptionDetailScreenState
    extends State<PatientPrescriptionDetailScreen> {
  bool _loading = true;
  String? _error;
  PatientPrescriptionDetail? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await widget.repository.getPrescription(
        widget.prescriptionId,
      );

      if (!mounted) return;

      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = patientPrescriptionErrorMessage(error);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();

    if (widget.embedded) {
      return ColoredBox(
        color: const Color(0xFFF4F6FB),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    tooltip: '처방 목록으로',
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '처방 상세',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(title: const Text('처방 상세')),
      body: body,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    final detail = _detail!;
    final prescription = detail.prescription;
    final items = detail.activeItems;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer
                              .withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '처방 정보',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '의료진이 확정한 처방입니다.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '확정',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _DetailRow(
                    label: '처방일',
                    value: _dateText(prescription.prescribedAt),
                  ),
                  if (prescription.signedAt != null)
                    _DetailRow(
                      label: '확정일',
                      value: _dateText(prescription.signedAt!),
                    ),
                  if (prescription.notes?.isNotEmpty == true) ...[
                    const Divider(height: 28),
                    Text(
                      '의료진 메모',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      prescription.notes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 20,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '처방 약품',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '현재 복용 중인 약과 복용 방법을 확인하세요.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(22),
                child: Text('현재 표시할 처방 약품이 없어요.'),
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PrescriptionItemCard(item: item),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '복용 방법이나 약에 대해 궁금한 점이 있으면 임의로 변경하지 말고 담당 의료진 또는 약사에게 확인해 주세요.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionItemCard extends StatelessWidget {
  const _PrescriptionItemCard({required this.item});

  final PatientPrescriptionItem item;

  @override
  Widget build(BuildContext context) {
    final medication = item.medication;
    final ingredient = _patientIngredientText(medication.ingredient);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MedicationImage(imageUrl: medication.imageUrl, size: 76),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (ingredient != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          ingredient,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 7),
                Text(
                  '복용 안내',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_hasPatientSafeDose(item))
              _DetailRow(label: '1회 복용량', value: _doseText(item)),
            _DetailRow(
              label: '하루 복용 횟수',
              value: item.frequencyPerDay == null
                  ? '안내 없음'
                  : '하루 ${item.frequencyPerDay}회',
            ),
            _DetailRow(
              label: '복용 기간',
              value: item.durationDays == null
                  ? '안내 없음'
                  : '${item.durationDays}일',
            ),
            if (item.instructions?.isNotEmpty == true)
              _DetailRow(label: '복용 방법', value: item.instructions!),
            if (item.note?.isNotEmpty == true)
              _DetailRow(label: '안내', value: item.note!),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

String? _patientIngredientText(String? value) {
  final raw = value?.trim();

  if (raw == null || raw.isEmpty) {
    return null;
  }

  final tokens = raw
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  const ignoredStandards = <String>{
    'BP',
    'USP',
    'KP',
    'JP',
    'EP',
    '\uBCC4\uADDC',
  };

  const units = <String, String>{
    '\uBC00\uB9AC\uADF8\uB7A8': 'mg',
    '\uADF8\uB7A8': 'g',
    '\uB9C8\uC774\uD06C\uB85C\uADF8\uB7A8': '\u03BCg',
    '\uBC00\uB9AC\uB9AC\uD130': 'mL',
  };

  final result = <String>[];

  for (var index = 0; index < tokens.length; index++) {
    final token = tokens[index];

    if (ignoredStandards.contains(token.toUpperCase()) ||
        ignoredStandards.contains(token)) {
      continue;
    }

    if (units.containsKey(token)) {
      continue;
    }

    final number = double.tryParse(token);

    if (number != null &&
        result.isNotEmpty &&
        index + 1 < tokens.length &&
        units.containsKey(tokens[index + 1])) {
      final displayNumber = number == number.roundToDouble()
          ? number.toInt().toString()
          : number
                .toStringAsFixed(3)
                .replaceFirst(RegExp(r'0+$'), '')
                .replaceFirst(RegExp(r'\.$'), '');

      final unit = units[tokens[index + 1]]!;

      result[result.length - 1] =
          '${result[result.length - 1]} $displayNumber $unit';

      index++;
      continue;
    }

    if (number != null) {
      final displayNumber = number == number.roundToDouble()
          ? number.toInt().toString()
          : number
                .toStringAsFixed(3)
                .replaceFirst(RegExp(r'0+$'), '')
                .replaceFirst(RegExp(r'\.$'), '');

      result.add(displayNumber);
      continue;
    }

    result.add(token);
  }

  if (result.isEmpty) {
    return null;
  }

  return result.join(' \u00B7 ');
}

bool _hasPatientSafeDose(PatientPrescriptionItem item) {
  if (item.doseValue == null) {
    return false;
  }

  final unit = item.doseUnit?.trim();

  if (unit == null || unit.isEmpty) {
    return true;
  }

  final looksLikePackageUnit =
      unit.contains(',') ||
      unit.contains('\uC815/\uBCD1') ||
      unit.contains('\uCEA1\uC290/\uBCD1') ||
      unit.contains('\uC815/\uD3EC') ||
      unit.contains('\uCEA1\uC290/\uD3EC');

  return !looksLikePackageUnit;
}

String _doseText(PatientPrescriptionItem item) {
  if (item.doseValue == null) return '안내 없음';

  final value = item.doseValue!;
  final number = value == value.roundToDouble()
      ? value.toInt().toString()
      : '$value';

  final unit = item.doseUnit?.trim();

  return unit == null || unit.isEmpty ? number : '$number $unit';
}

String _dateText(DateTime date) {
  final local = date.toLocal();

  String two(int value) => value.toString().padLeft(2, '0');

  return '${local.year}.${two(local.month)}.${two(local.day)}';
}
