import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
  int? _openingReportId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.repository.getResult(widget.resultId);
  }

  Future<void> _openReport(PatientReport report) async {
    if (_openingReportId != null) {
      return;
    }

    setState(() {
      _openingReportId = report.id;
    });

    try {
      final download = await widget.repository.getDownload(report.id);

      if (!download.file.canDownload) {
        _showMessage('현재 보고서 파일을 확인할 수 없습니다.');
        return;
      }

      // 실제 PDF 열기는 저장소 접근 정책 확정 후 연결
      _showMessage('보고서 파일 보기 기능은 연동 준비 중입니다.');
    } catch (error) {
      _showMessage(patientReportErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _openingReportId = null;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('최종 보고서')),
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
            openingReportId: _openingReportId,
            onOpenReport: _openReport,
          );
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.detail,
    required this.openingReportId,
    required this.onOpenReport,
  });

  final PatientReleasedResultDetail detail;
  final int? openingReportId;
  final ValueChanged<PatientReport> onOpenReport;

  @override
  Widget build(BuildContext context) {
    final result = detail.medicalResult;
    final summary = result.summary?.trim();
    final conclusion = result.conclusion?.trim();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _formatDate(result.updatedAt),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '공개 완료',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: '결과 요약',
          icon: Icons.summarize_outlined,
          child: Text(
            summary == null || summary.isEmpty ? '등록된 결과 요약이 없습니다.' : summary,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: '의료진 결론',
          icon: Icons.medical_information_outlined,
          child: Text(
            conclusion == null || conclusion.isEmpty
                ? '등록된 의료진 결론이 없습니다.'
                : conclusion,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: '환자용 보고서',
          icon: Icons.picture_as_pdf_outlined,
          child: detail.reports.isEmpty
              ? const Text(
                  '현재 공개된 환자용 보고서 파일이 없습니다.',
                  style: TextStyle(fontSize: 14, color: AppColors.mutedText),
                )
              : Column(
                  children: [
                    for (final report in detail.reports)
                      _ReportRow(
                        report: report,
                        isOpening: openingReportId == report.id,
                        onTap: () => onOpenReport(report),
                      ),
                  ],
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
                  '본 보고서는 의료진의 검토와 승인 후 환자에게 공개된 결과입니다.',
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

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.report,
    required this.isOpening,
    required this.onTap,
  });

  final PatientReport report;
  final bool isOpening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_outlined, color: AppColors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.reportName.isEmpty ? '최종 결과 보고서' : report.reportName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDate(report.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: isOpening ? null : onTap,
            child: isOpening
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('보고서 보기'),
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
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 21, color: AppColors.blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
