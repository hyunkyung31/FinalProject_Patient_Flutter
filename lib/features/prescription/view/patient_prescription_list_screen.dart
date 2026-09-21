import 'package:flutter/material.dart';

import '../model/patient_prescription.dart';
import '../repository/patient_prescription_repository.dart';
import 'patient_prescription_detail_screen.dart';
import '../widgets/medication_image.dart';

class PatientPrescriptionListScreen extends StatefulWidget {
  const PatientPrescriptionListScreen({
    super.key,
    required this.repository,
    this.embedded = false,
  });

  final PatientPrescriptionRepository repository;
  final bool embedded;

  @override
  State<PatientPrescriptionListScreen> createState() =>
      _PatientPrescriptionListScreenState();
}

class _PatientPrescriptionListScreenState
    extends State<PatientPrescriptionListScreen> {
  bool _loading = true;
  String? _error;
  List<PatientCurrentMedication> _currentMedications = const [];
  List<PatientPrescription> _prescriptions = const [];
  int? _selectedPrescriptionId;

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
      final currentFuture = widget.repository.getCurrentMedications();
      final prescriptionFuture = widget.repository.getPrescriptions();

      final current = await currentFuture;
      final prescriptions = await prescriptionFuture;

      if (!mounted) return;

      setState(() {
        _currentMedications = current;
        _prescriptions = prescriptions;
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

  void _openPrescription(PatientPrescription prescription) {
    if (widget.embedded) {
      setState(() {
        _selectedPrescriptionId = prescription.id;
      });
      return;
    }

    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PatientPrescriptionDetailScreen(
          repository: widget.repository,
          prescriptionId: prescription.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded && _selectedPrescriptionId != null) {
      return PatientPrescriptionDetailScreen(
        repository: widget.repository,
        prescriptionId: _selectedPrescriptionId!,
        embedded: true,
        onBack: () {
          setState(() {
            _selectedPrescriptionId = null;
          });
        },
      );
    }

    final content = ColoredBox(
      color: const Color(0xFFF4F6FB),
      child: _buildBody(),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(title: const Text('처방 조회')),
      body: content,
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          if (widget.embedded) ...[
            const _PrescriptionHero(),
            const SizedBox(height: 28),
          ],
          _SectionTitle(title: '현재 복용약', subtitle: '현재 복용 중으로 등록된 약이에요.'),
          const SizedBox(height: 12),
          if (_currentMedications.isEmpty)
            const _EmptyCard(message: '현재 복용 중으로 등록된 약이 없어요.')
          else
            ..._currentMedications.map(
              (medication) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CurrentMedicationCard(medication: medication),
              ),
            ),
          const SizedBox(height: 20),
          const _SectionTitle(title: '처방 이력', subtitle: '의료진이 확정한 처방만 표시돼요.'),
          const SizedBox(height: 12),
          if (_prescriptions.isEmpty)
            const _EmptyCard(message: '확인할 수 있는 처방 이력이 없어요.')
          else
            ..._prescriptions.map(
              (prescription) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PrescriptionCard(
                  key: ValueKey('prescription-${prescription.id}'),
                  prescription: prescription,
                  onTap: () => _openPrescription(prescription),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PrescriptionHero extends StatelessWidget {
  const _PrescriptionHero();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.medication_outlined,
              color: scheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '처방 조회',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '복용 중인 약과 의료진이 확정한 처방 내역을 확인하세요.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 20,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrentMedicationCard extends StatelessWidget {
  const _CurrentMedicationCard({required this.medication});

  final PatientCurrentMedication medication;

  @override
  Widget build(BuildContext context) {
    final item = medication.prescriptionItem;
    final ingredient = _patientIngredientText(medication.medication.ingredient);

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
                MedicationImage(
                  imageUrl: medication.medication.imageUrl,
                  size: 76,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.medication.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (ingredient != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          ingredient,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const _StatusChip(label: '복용 중'),
              ],
            ),
            const SizedBox(height: 14),
            if (_hasPatientSafeDose(item))
              _InfoRow(label: '1회 복용량', value: _doseText(item)),
            _InfoRow(
              label: '복용 횟수',
              value: item.frequencyPerDay == null
                  ? '안내 없음'
                  : '하루 ${item.frequencyPerDay}회',
            ),
            _InfoRow(
              label: '복용 기간',
              value: item.durationDays == null
                  ? '안내 없음'
                  : '${item.durationDays}일',
            ),
            if (item.instructions?.isNotEmpty == true)
              _InfoRow(label: '복용 방법', value: item.instructions!),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({
    super.key,
    required this.prescription,
    required this.onTap,
  });

  final PatientPrescription prescription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '처방 내역',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(_dateText(prescription.prescribedAt)),
                    if (prescription.notes?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        prescription.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const _StatusChip(label: '확정'),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
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
