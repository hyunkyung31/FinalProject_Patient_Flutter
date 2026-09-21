import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../ai_result/model/patient_ai_result.dart';
import '../../ai_result/repository/patient_ai_result_repository.dart';
import '../../ai_result/view/patient_ai_result_detail_screen.dart';
import '../../lab_result/model/lab_result.dart';
import '../../lab_result/repository/lab_result_repository.dart';
import '../../lab_result/view/lab_result_detail_screen.dart';
import '../model/patient_report.dart';
import '../repository/patient_report_repository.dart';

class PatientReportDetailScreen extends StatefulWidget {
  const PatientReportDetailScreen({
    super.key,
    required this.repository,
    required this.resultId,
  });

  final PatientReportRepository repository;
  final int resultId;

  @override
  State<PatientReportDetailScreen> createState() =>
      _PatientReportDetailScreenState();
}

class _PatientReportDetailScreenState extends State<PatientReportDetailScreen> {
  late Future<PatientReleasedResultDetail> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.repository.getResult(widget.resultId);
  }

  // ?? ???? ??? ?? Encounter? ???? ??? ?????.
  void _openLabDetail(LabResultDetail detail) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LabResultDetailScreen(
          result: detail.result,
          repository: PatientLabResultRepository(widget.repository.client),
        ),
      ),
    );
  }

  // ?? ???? ??? ?? Encounter? AI ?? ??? ?????.
  void _openAiDetail(PatientAIResult result) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PatientAIResultDetailScreen(
          repository: PatientAIResultRepository(widget.repository.client),
          resultId: result.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('심혈관 통합 리포트')),
      body: FutureBuilder<PatientReleasedResultDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _DetailErrorView(
              message: patientReportErrorMessage(snapshot.error!),
              onRetry: () {
                setState(_load);
              },
            );
          }

          final detail = snapshot.data;

          if (detail == null) {
            return const SizedBox.shrink();
          }

          return _DetailContent(
            detail: detail,
            onOpenLabDetail: _openLabDetail,
            onOpenAiDetail: _openAiDetail,
          );
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.detail,
    required this.onOpenLabDetail,
    required this.onOpenAiDetail,
  });

  final PatientReleasedResultDetail detail;
  final void Function(LabResultDetail) onOpenLabDetail;
  final void Function(PatientAIResult) onOpenAiDetail;

  @override
  Widget build(BuildContext context) {
    final result = detail.medicalResult;
    final summary = result.summary?.trim();
    final conclusion = result.conclusion?.trim();

    final xcaResults = detail.aiResults
        .where((item) => item.analysisType.toUpperCase() == 'ANGIO_2D')
        .toList();

    final cctaResults = detail.aiResults
        .where((item) => item.analysisType.toUpperCase() == 'CCTA')
        .toList();

    final patientExplanations = <PatientAIExplanation>[];
    final explanationTexts = <String>{};

    for (final aiResult in detail.aiResults) {
      for (final explanation in aiResult.explanations) {
        final text = explanation.summaryText.trim();

        if (explanation.explanationType.toUpperCase() != 'PATIENT' ||
            text.isEmpty ||
            explanationTexts.contains(text)) {
          continue;
        }

        explanationTexts.add(text);
        patientExplanations.add(explanation);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ReportHeroCard(dateText: _formatDate(result.updatedAt)),
        const SizedBox(height: 20),

        _SectionCard(
          title: '한눈에 보는 요약',
          icon: Icons.summarize_outlined,
          highlighted: true,
          child: Text(
            summary == null || summary.isEmpty ? '등록된 결과 요약이 없습니다.' : summary,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ),

        if (detail.labResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: '혈액검사',
            icon: Icons.science_outlined,
            onActionTap: () => onOpenLabDetail(detail.labResults.first),
            child: _LabResultContent(results: detail.labResults),
          ),
        ],

        if (xcaResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: '혈관조영술',
            icon: Icons.monitor_heart_outlined,
            onActionTap: () => onOpenAiDetail(xcaResults.first),
            child: _XcaResultContent(results: xcaResults),
          ),
        ],

        if (cctaResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: '혈관 CT',
            icon: Icons.view_in_ar_outlined,
            onActionTap: () => onOpenAiDetail(cctaResults.first),
            child: _CctaResultContent(results: cctaResults),
          ),
        ],

        if (patientExplanations.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'AI가 쉽게 설명해 드려요',
            icon: Icons.auto_awesome_outlined,
            highlighted: true,
            child: _AIExplanationContent(explanations: patientExplanations),
          ),
        ],

        const SizedBox(height: 16),

        _SectionCard(
          title: '의료진 최종 소견',
          icon: Icons.medical_information_outlined,
          child: Text(
            conclusion == null || conclusion.isEmpty
                ? '등록된 의료진 결론이 없습니다.'
                : conclusion,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 20, color: AppColors.blue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '이 리포트는 의료진이 검토하고 승인한 결과를 바탕으로 환자에게 공개됩니다.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabResultContent extends StatelessWidget {
  const _LabResultContent({required this.results});

  final List<LabResultDetail> results;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주요 심혈관 지표와 정상 범위를 벗어난 항목을 요약해서 보여드려요.',
          style: TextStyle(
            fontSize: 12,
            height: 1.45,
            color: AppColors.mutedText,
          ),
        ),
        const SizedBox(height: 14),

        for (
          var resultIndex = 0;
          resultIndex < results.length;
          resultIndex++
        ) ...[
          if (resultIndex > 0) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
          ],

          if (results[resultIndex].result.summaryText.trim().isNotEmpty) ...[
            Text(
              results[resultIndex].result.summaryText.trim(),
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 12),
          ],

          Builder(
            builder: (context) {
              final measurements = _reportLabMeasurements(
                results[resultIndex].measurements,
              );

              if (measurements.isEmpty) {
                return const Text(
                  '??? ?? ???? ??? ????. ?? ??? ?????? ??? ? ???.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.mutedText,
                  ),
                );
              }

              return Column(
                children: measurements
                    .map(
                      (measurement) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ValueRow(
                          label: measurement.name.trim().isEmpty
                              ? measurement.code
                              : measurement.name,
                          value: _measurementValue(measurement),
                          detail: _measurementDetail(measurement),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _XcaResultContent extends StatelessWidget {
  const _XcaResultContent({required this.results});

  final List<PatientAIResult> results;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (
          var resultIndex = 0;
          resultIndex < results.length;
          resultIndex++
        ) ...[
          if (resultIndex > 0) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
          ],

          if (results[resultIndex].summaryText.trim().isNotEmpty) ...[
            Text(
              results[resultIndex].summaryText.trim(),
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (results[resultIndex].lesions.isNotEmpty)
            ...results[resultIndex].lesions.map(
              (lesion) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ValueRow(
                  label: _lesionLabel(lesion),
                  value: lesion.stenosisPercent == null
                      ? '협착 정도 미제공'
                      : '${_compactNumber(lesion.stenosisPercent!)}% 협착',
                  detail: lesion.severityGrade.trim().isEmpty
                      ? null
                      : '중증도 ${lesion.severityGrade}',
                ),
              ),
            )
          else if (results[resultIndex].detections.isNotEmpty)
            ...results[resultIndex].detections.map(
              (detection) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ValueRow(
                  label: detection.arterySegment.trim().isEmpty
                      ? '협착 탐지'
                      : detection.arterySegment,
                  value: detection.findingType.trim().isEmpty
                      ? 'AI 탐지 결과'
                      : detection.findingType,
                  detail: detection.severity.trim().isEmpty
                      ? null
                      : '중증도 ${detection.severity}',
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _CctaResultContent extends StatelessWidget {
  const _CctaResultContent({required this.results});

  final List<PatientAIResult> results;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (
          var resultIndex = 0;
          resultIndex < results.length;
          resultIndex++
        ) ...[
          if (resultIndex > 0) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
          ],

          if (results[resultIndex].summaryText.trim().isNotEmpty) ...[
            Text(
              results[resultIndex].summaryText.trim(),
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (results[resultIndex].cacScores.isEmpty)
            const Text(
              '표시할 석회화 점수 정보가 없습니다.',
              style: TextStyle(fontSize: 13, color: AppColors.mutedText),
            )
          else
            ...results[resultIndex].cacScores.map(
              (score) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ValueRow(
                    label: 'CAC 총점',
                    value: _nullableNumber(score.scoreValue),
                    detail: score.riskCategory.trim().isEmpty
                        ? null
                        : '위험 분류 ${score.riskCategory}',
                  ),
                  const SizedBox(height: 10),
                  _ValueRow(
                    label: 'LAD',
                    value: _nullableNumber(score.ladScore),
                  ),
                  const SizedBox(height: 10),
                  _ValueRow(
                    label: 'LCX',
                    value: _nullableNumber(score.lcxScore),
                  ),
                  const SizedBox(height: 10),
                  _ValueRow(
                    label: 'RCA',
                    value: _nullableNumber(score.rcaScore),
                  ),
                  if (score.percentile != null) ...[
                    const SizedBox(height: 10),
                    _ValueRow(
                      label: '백분위',
                      value: '${_compactNumber(score.percentile!)}%',
                    ),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _AIExplanationContent extends StatelessWidget {
  const _AIExplanationContent({required this.explanations});

  final List<PatientAIExplanation> explanations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < explanations.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  explanations[index].summaryText.trim(),
                  style: const TextStyle(fontSize: 14, height: 1.55),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value, this.detail});

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final detailText = detail?.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (detailText != null && detailText.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  detailText,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

List<LabMeasurement> _reportLabMeasurements(List<LabMeasurement> measurements) {
  final selected = <LabMeasurement>[];
  final selectedIds = <int>{};

  // ??? ?? ?? ??
  for (final measurement in measurements) {
    if (_cardiovascularLabPriority(measurement) < 100) {
      selected.add(measurement);
      selectedIds.add(measurement.id);
    }
  }

  // ?? ?? ? ??? ????? ????? ?? ?????.
  for (final measurement in measurements) {
    final flag = measurement.normalizedFlag;

    if ((flag == 'HIGH' || flag == 'LOW') &&
        !selectedIds.contains(measurement.id)) {
      selected.add(measurement);
      selectedIds.add(measurement.id);
    }
  }

  selected.sort((a, b) {
    final priorityCompare = _cardiovascularLabPriority(
      a,
    ).compareTo(_cardiovascularLabPriority(b));

    if (priorityCompare != 0) {
      return priorityCompare;
    }

    return a.id.compareTo(b.id);
  });

  return selected;
}

int _cardiovascularLabPriority(LabMeasurement measurement) {
  final code = _normalizeLabText(measurement.code);
  final name = _normalizeLabText(measurement.name);

  if (code.contains('LDL') || name.contains('LDL')) {
    return 10;
  }

  if (code.contains('HDL') || name.contains('HDL')) {
    return 20;
  }

  if (code == 'TG' || code.contains('TRIGLYCERIDE') || name.contains('????')) {
    return 30;
  }

  if (code == 'TC' ||
      code == 'CHOL' ||
      code.contains('CHOLESTEROL') ||
      name.contains('??????')) {
    return 40;
  }

  if (code == 'FBS' ||
      code == 'GLU' ||
      code.contains('GLUCOSE') ||
      name.contains('????')) {
    return 50;
  }

  return 100;
}

String _normalizeLabText(String value) {
  return value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9?-?]'), '');
}

String _measurementValue(LabMeasurement measurement) {
  final unit = measurement.displayUnit;

  if (unit.isEmpty) {
    return measurement.displayValue;
  }

  return '${measurement.displayValue} $unit';
}

String? _measurementDetail(LabMeasurement measurement) {
  final parts = <String>[];

  if (measurement.displayReference != '-') {
    final unit = measurement.displayUnit;

    parts.add(
      unit.isEmpty
          ? '참고범위 ${measurement.displayReference}'
          : '참고범위 ${measurement.displayReference} $unit',
    );
  }

  final flag = switch (measurement.normalizedFlag) {
    'NORMAL' => '정상 범위',
    'HIGH' => '정상 범위보다 높음',
    'LOW' => '정상 범위보다 낮음',
    _ => '',
  };

  if (flag.isNotEmpty) {
    parts.add(flag);
  }

  return parts.isEmpty ? null : parts.join(' · ');
}

String _lesionLabel(PatientAILesion lesion) {
  final parts = <String>[
    if (lesion.arteryName.trim().isNotEmpty) lesion.arteryName.trim(),
    if (lesion.segmentName.trim().isNotEmpty) lesion.segmentName.trim(),
  ];

  return parts.isEmpty ? '관상동맥 병변' : parts.join(' · ');
}

String _nullableNumber(double? value) {
  if (value == null) {
    return '-';
  }

  return _compactNumber(value);
}

String _compactNumber(num value) {
  final doubleValue = value.toDouble();

  if (doubleValue == doubleValue.roundToDouble()) {
    return doubleValue.toStringAsFixed(0);
  }

  return doubleValue
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

class _ReportHeroCard extends StatelessWidget {
  const _ReportHeroCard({required this.dateText});

  final String dateText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.blue,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '검사 결과를 한눈에 확인하세요',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '의료진이 검토한 심혈관 통합 리포트입니다.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(
                Icons.event_available_outlined,
                size: 18,
                color: AppColors.mutedText,
              ),
              const SizedBox(width: 7),
              Text(
                dateText,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '의료진 검토 완료',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.highlighted = false,
    this.onActionTap,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final bool highlighted;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.blue.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? AppColors.blue.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 21, color: AppColors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onActionTap != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onActionTap,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('상세보기'),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DetailErrorView extends StatelessWidget {
  const _DetailErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final year = date.year.toString();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$year.$month.$day';
}
