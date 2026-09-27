import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../ai_result/model/patient_ai_result.dart';
import '../../lab_result/model/lab_result.dart';
import '../../lab_result/repository/lab_result_repository.dart';
import '../../lab_result/view/lab_result_detail_screen.dart';
import '../model/patient_report.dart';
import '../repository/patient_report_repository.dart';
import 'patient_xca_composite_image.dart';
import 'patient_ccta_image.dart';

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
  late Future<_ReportDetailBundle> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _loadReportDetail();
  }

  Future<_ReportDetailBundle> _loadReportDetail() async {
    final detailFuture = widget.repository.getResult(widget.resultId);
    final integratedFuture = widget.repository.getIntegratedResult(
      widget.resultId,
    );

    return _ReportDetailBundle(
      detail: await detailFuture,
      integrated: await integratedFuture,
    );
  }

  // 동일 Encounter의 혈액검사 상세
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('심혈관 통합 리포트')),
      body: FutureBuilder<_ReportDetailBundle>(
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

          final data = snapshot.data;

          if (data == null) {
            return const SizedBox.shrink();
          }

          return _DetailContent(
            detail: data.detail,
            integrated: data.integrated,
            repository: widget.repository,
            onOpenLabDetail: _openLabDetail,
          );
        },
      ),
    );
  }
}

class _ReportDetailBundle {
  const _ReportDetailBundle({required this.detail, required this.integrated});

  final PatientReleasedResultDetail detail;
  final PatientIntegratedResult integrated;
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.detail,
    required this.integrated,
    required this.repository,
    required this.onOpenLabDetail,
  });

  final PatientReleasedResultDetail detail;
  final PatientIntegratedResult integrated;
  final PatientReportRepository repository;
  final void Function(LabResultDetail) onOpenLabDetail;

  @override
  Widget build(BuildContext context) {
    final result = detail.medicalResult;
    final summary = result.summary?.trim();
    final finalOpinion = integrated.finalOpinion?.trim();

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
        _ReportHeroCard(
          dateText: _formatDate(
            integrated.approval.approvedAt ?? result.updatedAt,
          ),
        ),
        const SizedBox(height: 20),

        if (summary != null && summary.isNotEmpty) ...[
          _SectionCard(
            title: '한눈에 보는 요약',
            icon: Icons.summarize_outlined,
            highlighted: true,
            child: Text(
              summary,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
        ],

        const _ReportGroupHeader(
          icon: Icons.fact_check_outlined,
          title: '검사 결과',
          subtitle: '공개된 검사 결과를 항목별로 확인할 수 있어요.',
        ),
        const SizedBox(height: 12),

        if (detail.labResults.isNotEmpty) ...[
          _SectionCard(
            title: '혈액검사',
            icon: Icons.science_outlined,
            onActionTap: () => onOpenLabDetail(detail.labResults.first),
            child: _LabResultContent(results: detail.labResults),
          ),
          const SizedBox(height: 12),
        ],

        _SectionCard(
          title: '혈관조영술',
          icon: Icons.monitor_heart_outlined,
          child: _IntegratedXcaResultContent(
            repository: repository,
            xca: integrated.xca,
          ),
        ),

        const SizedBox(height: 12),

        _SectionCard(
          title: '혈관 CT',
          icon: Icons.view_in_ar_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IntegratedCtResultContent(ct: integrated.ct),
              if (integrated.ct.available) ...[
                const SizedBox(height: 14),
                PatientCctaImage(
                  repository: repository,
                  resultId: integrated.medicalResultId,
                ),
              ],
            ],
          ),
        ),

        if (patientExplanations.isNotEmpty) ...[
          const SizedBox(height: 28),
          const _ReportGroupHeader(
            icon: Icons.auto_awesome_outlined,
            title: '결과 설명',
            subtitle: '검사 결과를 이해하기 쉽게 정리한 설명이에요.',
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'AI가 쉽게 설명해 드려요',
            icon: Icons.chat_bubble_outline_rounded,
            highlighted: true,
            child: _AIExplanationContent(explanations: patientExplanations),
          ),
        ],

        const SizedBox(height: 28),

        const _ReportGroupHeader(
          icon: Icons.medical_information_outlined,
          title: '의료진 확인',
          subtitle: '의료진의 최종 확인 내용과 승인 정보를 확인하세요.',
        ),
        const SizedBox(height: 12),

        _SectionCard(
          title: '의료진 최종 소견',
          icon: Icons.notes_rounded,
          child: Text(
            finalOpinion == null || finalOpinion.isEmpty
                ? '등록된 의료진 최종 소견이 없습니다.'
                : finalOpinion,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ),

        const SizedBox(height: 12),

        _SectionCard(
          title: '승인 정보',
          icon: Icons.verified_user_outlined,
          highlighted: true,
          child: _IntegratedApprovalContent(approval: integrated.approval),
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

class _ReportGroupHeader extends StatelessWidget {
  const _ReportGroupHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: AppColors.blue),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.mutedText,
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

class _LabResultContent extends StatelessWidget {
  const _LabResultContent({required this.results});

  final List<LabResultDetail> results;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주요 혈액검사 수치와 참고 범위를 확인하세요.',
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

          Builder(
            builder: (context) {
              final measurements = _reportLabMeasurements(
                results[resultIndex].measurements,
              );

              if (measurements.isEmpty) {
                return const Text(
                  '표시할 주요 혈액검사 항목이 없습니다. 전체 결과는 상세 화면에서 확인해 주세요.',
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

class _IntegratedXcaResultContent extends StatefulWidget {
  const _IntegratedXcaResultContent({
    required this.repository,
    required this.xca,
  });

  final PatientReportRepository repository;
  final PatientIntegratedXca xca;

  @override
  State<_IntegratedXcaResultContent> createState() =>
      _IntegratedXcaResultContentState();
}

class _IntegratedXcaResultContentState
    extends State<_IntegratedXcaResultContent> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final xca = widget.xca;

    if (!xca.available || xca.findings.isEmpty) {
      return const Text(
        '이 리포트에 공개된 혈관조영술 결과가 없습니다.',
        style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.mutedText),
      );
    }

    final findings = _showAll ? xca.findings : xca.findings.take(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _ValueRow(
                label: '촬영 시리즈',
                value: xca.seriesCount?.toString() ?? '-',
              ),
              const SizedBox(height: 9),
              _ValueRow(
                label: '전체 프레임',
                value: xca.frameCount?.toString() ?? '-',
              ),
              const SizedBox(height: 9),
              _ValueRow(label: '확인 소견', value: '${xca.findings.length}건'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        for (var index = 0; index < findings.length; index++) ...[
          if (index > 0) ...[
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 18),
          ],
          _IntegratedXcaFindingContent(
            repository: widget.repository,
            finding: findings[index],
            number: index + 1,
          ),
        ],

        if (xca.findings.length > 1) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _showAll = !_showAll;
                });
              },
              icon: Icon(
                _showAll
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
              ),
              label: Text(
                _showAll ? '대표 영상만 보기' : '전체 ${xca.findings.length}건 보기',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _IntegratedXcaFindingContent extends StatelessWidget {
  const _IntegratedXcaFindingContent({
    required this.repository,
    required this.finding,
    required this.number,
  });

  final PatientReportRepository repository;
  final PatientIntegratedXcaFinding finding;
  final int number;

  @override
  Widget build(BuildContext context) {
    final original = finding.originalImageUrl?.trim();
    final overlay = finding.overlayImageUrl?.trim();
    final opinion = finding.doctorOpinion?.trim();

    final metadata = <String>[
      if (finding.captureNo != null) '촬영 ${finding.captureNo}',
      if (finding.frameIndex != null) 'Frame ${finding.frameIndex}',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.018),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.055)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '확인 영상',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          if (metadata.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: metadata
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.035),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          if (opinion != null && opinion.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.055),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.medical_information_outlined,
                        size: 16,
                        color: AppColors.blue,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '의료진 확인 내용',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    opinion,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ],

          if (original != null && original.isNotEmpty) ...[
            const SizedBox(height: 14),
            PatientXcaCompositeImage(
              repository: repository,
              originalPath: original,
              overlayPath: overlay,
            ),
          ],
        ],
      ),
    );
  }
}

class _IntegratedCtResultContent extends StatelessWidget {
  const _IntegratedCtResultContent({required this.ct});

  final PatientIntegratedCt ct;

  @override
  Widget build(BuildContext context) {
    if (ct.isPending) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.blue.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ResultStatusIcon(icon: Icons.schedule_rounded),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '분석 대기 중',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '분석이 완료되고 의료진의 확인을 거친 뒤 결과가 표시됩니다.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (!ct.available) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.025),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 19,
              color: AppColors.mutedText,
            ),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                '이 리포트에 공개된 혈관 CT 결과가 없습니다.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.mutedText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final summary = ct.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              _ResultStatusIcon(icon: Icons.check_rounded),
              SizedBox(width: 10),
              Text(
                '분석 완료',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (summary is String && summary.trim().isNotEmpty)
          Text(
            summary.trim(),
            style: const TextStyle(fontSize: 13, height: 1.55),
          )
        else
          const Text(
            '분석이 완료되었습니다. 세부 결과는 의료진 설명과 함께 확인해 주세요.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.mutedText,
            ),
          ),
      ],
    );
  }
}

class _ResultStatusIcon extends StatelessWidget {
  const _ResultStatusIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 19, color: AppColors.blue),
    );
  }
}

class _IntegratedApprovalContent extends StatelessWidget {
  const _IntegratedApprovalContent({required this.approval});

  final PatientIntegratedApproval approval;

  @override
  Widget build(BuildContext context) {
    final doctor = approval.doctorName?.trim();
    final department = approval.department?.trim();
    final signatureAsset = _doctorSignatureAsset(doctor);

    final doctorText = doctor != null && doctor.isNotEmpty
        ? doctor
        : '의료진 정보 없음';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.blue.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.blue,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (department != null && department.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        department,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '승인 완료',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        _ValueRow(
          label: '승인 일시',
          value: approval.approvedAt == null
              ? '정보 없음'
              : _formatDateTime(approval.approvedAt!),
        ),
        const SizedBox(height: 9),
        _ValueRow(
          label: '보고서 버전',
          value: approval.version?.trim().isNotEmpty == true
              ? approval.version!.trim()
              : '정보 없음',
        ),

        if (signatureAsset != null) ...[
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Text(
                  '의료진 서명',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
              Image.asset(
                signatureAsset,
                width: 145,
                height: 68,
                fit: BoxFit.contain,
              ),
            ],
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

  // 심혈관 주요 항목 우선
  for (final measurement in measurements) {
    if (_cardiovascularLabPriority(measurement) < 100) {
      selected.add(measurement);
      selectedIds.add(measurement.id);
    }
  }

  // 주요 항목 외 HIGH/LOW도 함께 표시
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

  if (code == 'TG' || code.contains('TRIGLYCERIDE') || name.contains('중성지방')) {
    return 30;
  }

  if (code == 'TC' ||
      code == 'CHOL' ||
      code.contains('CHOLESTEROL') ||
      name.contains('총콜레스테롤')) {
    return 40;
  }

  if (code == 'FBS' ||
      code == 'GLU' ||
      code.contains('GLUCOSE') ||
      (name.contains('공복혈당') || name.contains('혈당') || name.contains('포도당'))) {
    return 50;
  }

  return 100;
}

String _normalizeLabText(String value) {
  return value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9가-힣]'), '');
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
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.blue.withValues(alpha: 0.035)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted
              ? AppColors.blue.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.055),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.085),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: AppColors.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onActionTap != null)
                TextButton(
                  onPressed: onActionTap,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('상세보기', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 1),
                      Icon(Icons.chevron_right_rounded, size: 17),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
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

String? _doctorSignatureAsset(String? doctorName) {
  const signatures = <String, String>{
    '김도윤': 'assets/doctor_sign/doctor01_signature.png',
    '이서준': 'assets/doctor_sign/doctor02_signature.png',
    '박지훈': 'assets/doctor_sign/doctor03_signature.png',
    '최현우': 'assets/doctor_sign/doctor04_signature.png',
    '정민재': 'assets/doctor_sign/doctor05_signature.png',
    '강태윤': 'assets/doctor_sign/doctor06_signature.png',
    '조성민': 'assets/doctor_sign/doctor07_signature.png',
    '윤재호': 'assets/doctor_sign/doctor08_signature.png',
    '장우진': 'assets/doctor_sign/doctor09_signature.png',
    '임현석': 'assets/doctor_sign/doctor10_signature.png',
  };

  final name = doctorName?.trim();

  if (name == null || name.isEmpty) {
    return null;
  }

  return signatures[name];
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();

  return '${local.year}.'
      '${local.month.toString().padLeft(2, '0')}.'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
