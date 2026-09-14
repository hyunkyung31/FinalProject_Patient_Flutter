import 'package:flutter/material.dart';

import '../model/patient_prescription.dart';
import '../repository/patient_prescription_repository.dart';

class PatientPrescriptionDetailScreen extends StatefulWidget {
  const PatientPrescriptionDetailScreen({
    super.key,
    required this.repository,
    required this.prescriptionId,
  });

  final PatientPrescriptionRepository repository;
  final int prescriptionId;

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
    return Scaffold(
      appBar: AppBar(title: const Text('처방 상세')),
      body: _buildBody(),
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
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '확정된 처방',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
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
                          'SIGNED',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('처방일 ${_dateText(prescription.prescribedAt)}'),
                  if (prescription.signedAt != null) ...[
                    const SizedBox(height: 4),
                    Text('확정일 ${_dateText(prescription.signedAt!)}'),
                  ],
                  if (prescription.notes?.isNotEmpty == true) ...[
                    const Divider(height: 28),
                    Text(
                      prescription.notes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            '처방 약품',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '현재 유효한 처방 항목만 표시돼요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              medication.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (medication.ingredient?.isNotEmpty == true) ...[
              const SizedBox(height: 3),
              Text(
                medication.ingredient!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (medication.strength?.isNotEmpty == true) ...[
              const SizedBox(height: 3),
              Text(
                medication.strength!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const Divider(height: 26),
            _DetailRow(label: '복용량', value: _doseText(item)),
            _DetailRow(
              label: '복용 횟수',
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
            if (item.startDate != null)
              _DetailRow(label: '시작일', value: _dateText(item.startDate!)),
            if (item.endDate != null)
              _DetailRow(label: '종료일', value: _dateText(item.endDate!)),
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
