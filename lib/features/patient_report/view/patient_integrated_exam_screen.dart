import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/patient_report.dart';
import '../repository/patient_report_repository.dart';
import 'patient_xca_composite_image.dart';
import 'patient_ccta_image.dart';

enum PatientIntegratedExamType { xca, ct }

class PatientIntegratedExamListScreen extends StatefulWidget {
  const PatientIntegratedExamListScreen({
    super.key,
    required this.repository,
    required this.type,
  });

  final PatientReportRepository repository;
  final PatientIntegratedExamType type;

  @override
  State<PatientIntegratedExamListScreen> createState() =>
      _PatientIntegratedExamListScreenState();
}

class _PatientIntegratedExamListScreenState
    extends State<PatientIntegratedExamListScreen> {
  late Future<List<_IntegratedEntry>> _future;

  bool get _isXca => widget.type == PatientIntegratedExamType.xca;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _load();
  }

  Future<List<_IntegratedEntry>> _load() async {
    final released = await widget.repository.getResults();

    final entries = await Future.wait(
      released.map((item) async {
        final integrated = await widget.repository.getIntegratedResult(
          item.medicalResult.id,
        );

        return _IntegratedEntry(released: item, integrated: integrated);
      }),
    );

    entries.sort(
      (a, b) => b.released.releasedAt.compareTo(a.released.releasedAt),
    );

    if (_isXca) {
      return entries.where((entry) => entry.integrated.xca.available).toList();
    }

    return entries.where((entry) => entry.integrated.ct.available).toList();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isXca ? '혈관조영술' : '혈관 CT';

    return Scaffold(
      appBar: AppBar(primary: false, title: Text(title)),
      body: FutureBuilder<List<_IntegratedEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorView(
              message: patientReportErrorMessage(snapshot.error!),
              onRetry: () {
                setState(_reload);
              },
            );
          }

          final entries = snapshot.data ?? const <_IntegratedEntry>[];

          if (entries.isEmpty) {
            return _EmptyView(isXca: _isXca);
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _future;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = entries[index];

                return _ResultCard(
                  entry: entry,
                  isXca: _isXca,
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => PatientIntegratedExamDetailScreen(
                          repository: widget.repository,
                          integrated: entry.integrated,
                          releasedAt: entry.released.releasedAt,
                          type: widget.type,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class PatientIntegratedExamDetailScreen extends StatelessWidget {
  const PatientIntegratedExamDetailScreen({
    super.key,
    required this.repository,
    required this.integrated,
    required this.releasedAt,
    required this.type,
  });

  final PatientReportRepository repository;
  final PatientIntegratedResult integrated;
  final DateTime releasedAt;
  final PatientIntegratedExamType type;

  bool get _isXca => type == PatientIntegratedExamType.xca;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        primary: false,
        title: Text(_isXca ? '혈관조영술 결과' : '혈관 CT 결과'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _ApprovalHeader(integrated: integrated, releasedAt: releasedAt),
          const SizedBox(height: 16),
          if (_isXca)
            _XcaDetail(repository: repository, xca: integrated.xca)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CtDetail(ct: integrated.ct),
                if (integrated.ct.available) ...[
                  const SizedBox(height: 16),
                  PatientCctaImage(
                    repository: repository,
                    resultId: integrated.medicalResultId,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _IntegratedEntry {
  const _IntegratedEntry({required this.released, required this.integrated});

  final PatientReleasedResult released;
  final PatientIntegratedResult integrated;
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.entry,
    required this.isXca,
    required this.onTap,
  });

  final _IntegratedEntry entry;
  final bool isXca;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final integrated = entry.integrated;
    final xca = integrated.xca;
    final ct = integrated.ct;

    final statusText = isXca
        ? '${xca.findings.length}건 확인'
        : ct.isPending
        ? '분석 대기 중'
        : ct.available
        ? '분석 완료'
        : '결과 없음';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  isXca
                      ? Icons.monitor_heart_outlined
                      : Icons.view_in_ar_outlined,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isXca ? '혈관조영술 결과' : '혈관 CT 결과',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatDate(entry.released.releasedAt),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprovalHeader extends StatelessWidget {
  const _ApprovalHeader({required this.integrated, required this.releasedAt});

  final PatientIntegratedResult integrated;
  final DateTime releasedAt;

  @override
  Widget build(BuildContext context) {
    final approval = integrated.approval;
    final doctor = approval.doctorName?.trim();
    final department = approval.department?.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: AppColors.blue,
                size: 21,
              ),
              SizedBox(width: 8),
              Text(
                '리포트 승인·공개 완료',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            [
              if (doctor != null && doctor.isNotEmpty) doctor,
              if (department != null && department.isNotEmpty) department,
            ].join(' · '),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            '공개일 ${_formatDate(releasedAt)}'
            '${approval.version == null ? '' : ' · ${approval.version}'}',
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _XcaDetail extends StatelessWidget {
  const _XcaDetail({required this.repository, required this.xca});

  final PatientReportRepository repository;
  final PatientIntegratedXca xca;

  @override
  Widget build(BuildContext context) {
    if (!xca.available || xca.findings.isEmpty) {
      return const _MessageCard(
        icon: Icons.monitor_heart_outlined,
        title: '공개된 혈관조영술 결과가 없습니다.',
        message: '의료진이 최종 확인해 공개한 결과만 표시됩니다.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoCard(
          title: '검사 요약',
          children: [
            _InfoRow(
              label: 'Series',
              value: xca.seriesCount?.toString() ?? '-',
            ),
            _InfoRow(
              label: '전체 Frame',
              value: xca.frameCount?.toString() ?? '-',
            ),
            _InfoRow(label: '공개 소견', value: '${xca.findings.length}건'),
          ],
        ),
        const SizedBox(height: 16),
        ...xca.findings.indexed.map((indexed) {
          final index = indexed.$1;
          final finding = indexed.$2;
          final opinion = finding.doctorOpinion?.trim();

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == xca.findings.length - 1 ? 0 : 16,
            ),
            child: _FindingCard(
              repository: repository,
              finding: finding,
              number: index + 1,
              opinion: opinion,
            ),
          );
        }),
      ],
    );
  }
}

class _FindingCard extends StatelessWidget {
  const _FindingCard({
    required this.repository,
    required this.finding,
    required this.number,
    required this.opinion,
  });

  final PatientReportRepository repository;
  final PatientIntegratedXcaFinding finding;
  final int number;
  final String? opinion;

  @override
  Widget build(BuildContext context) {
    final original = finding.originalImageUrl?.trim();
    final overlay = finding.overlayImageUrl?.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '확인 영상 $number',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          Text(
            [
              if (finding.captureNo != null) '촬영 ${finding.captureNo}',
              if (finding.frameIndex != null) 'Frame ${finding.frameIndex}',
            ].join(' · '),
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
          if (opinion != null && opinion!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '의료진 확인 내용',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(opinion!, style: const TextStyle(fontSize: 14, height: 1.5)),
          ],
          if (original != null && original.isNotEmpty) ...[
            const SizedBox(height: 16),
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

class _CtDetail extends StatelessWidget {
  const _CtDetail({required this.ct});

  final PatientIntegratedCt ct;

  @override
  Widget build(BuildContext context) {
    if (ct.isPending) {
      return const _MessageCard(
        icon: Icons.schedule_rounded,
        title: '혈관 CT 분석 대기 중',
        message: '분석이 완료되고 의료진이 확인한 뒤 결과가 표시됩니다.',
      );
    }

    if (!ct.available) {
      return const _MessageCard(
        icon: Icons.view_in_ar_outlined,
        title: '공개된 혈관 CT 결과가 없습니다.',
        message: '의료진이 최종 확인해 공개한 결과만 표시됩니다.',
      );
    }

    final summary = ct.summary;

    return _InfoCard(
      title: '혈관 CT 분석 결과',
      children: [
        const _InfoRow(label: '상태', value: '분석 완료'),
        if (summary is String && summary.trim().isNotEmpty)
          _InfoRow(label: '결과 요약', value: summary.trim()),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
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
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.mutedText),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.isXca});

  final bool isXca;

  @override
  Widget build(BuildContext context) {
    return _MessageCard(
      icon: isXca ? Icons.monitor_heart_outlined : Icons.view_in_ar_outlined,
      title: isXca ? '공개된 혈관조영술 결과가 없어요.' : '공개된 혈관 CT 결과가 없어요.',
      message: '의료진 검토와 공개가 완료된 결과만 표시됩니다.',
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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

String _formatDate(DateTime value) {
  final local = value.toLocal();

  return '${local.year}.'
      '${local.month.toString().padLeft(2, '0')}.'
      '${local.day.toString().padLeft(2, '0')}';
}
