import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/patient_ai_result.dart';
import '../repository/patient_ai_result_repository.dart';
import 'patient_ai_result_detail_screen.dart';

// 의료진이 공개한 환자 AI 결과 목록 화면
class PatientAIResultListScreen extends StatefulWidget {
  const PatientAIResultListScreen({
    super.key,
    required this.repository,
    this.analysisType,
    this.title = 'AI 분석 결과',
    this.emptyTitle = '공개된 AI 분석 결과가 없어요.',
    this.emptyMessage = '의료진 검토 후 공개된 결과가 있으면 이곳에서 확인할 수 있어요.',
  });

  final PatientAIResultRepository repository;

  // 검사결과 허브에서 XCA/CCTA 결과만 선택적으로 표시한다.
  final String? analysisType;
  final String title;
  final String emptyTitle;
  final String emptyMessage;

  @override
  State<PatientAIResultListScreen> createState() =>
      _PatientAIResultListScreenState();
}

class _PatientAIResultListScreenState extends State<PatientAIResultListScreen> {
  late Future<List<PatientAIResult>> _results;

  @override
  void initState() {
    super.initState();
    _results = _loadResults();
  }

  // 전체 공개 결과 중 요청된 분석 유형만 선택적으로 남긴다.
  Future<List<PatientAIResult>> _loadResults() async {
    final results = await widget.repository.getResults();
    final analysisType = widget.analysisType?.trim().toUpperCase();

    if (analysisType == null || analysisType.isEmpty) {
      return results;
    }

    final filtered = results
        .where(
          (result) => result.analysisType.trim().toUpperCase() == analysisType,
        )
        .toList();

    if (analysisType != 'CLINICAL') {
      return filtered;
    }

    // 새 API에서는 examination_id 기준으로 정확히 재실행 결과를 묶는다.
    // 구 API에서는 같은 날짜의 최신 Clinical 결과만 표시한다.
    final seenClinicalResults = <String>{};

    return filtered.where((result) {
      final examinationId = result.examinationId;
      final generatedAt = result.generatedAt;

      final key = examinationId != null
          ? 'exam:$examinationId'
          : 'date:${generatedAt.year}-'
                '${generatedAt.month}-'
                '${generatedAt.day}';

      return seenClinicalResults.add(key);
    }).toList();
  }

  // AI 결과 목록 새로고침
  IconData get _emptyIcon {
    final type = widget.analysisType?.trim().toUpperCase();

    return switch (type) {
      'ANGIO_2D' => Icons.monitor_heart_outlined,
      'CCTA' => Icons.view_in_ar_rounded,
      _ => Icons.insights_outlined,
    };
  }

  Future<void> _reload() async {
    final future = _loadResults();

    setState(() {
      _results = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder에서 오류 상태 표시
    }
  }

  // 선택한 AI 결과의 실제 상세 API 화면으로 이동
  void _openDetail(PatientAIResult result) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PatientAIResultDetailScreen(
          repository: widget.repository,
          resultId: result.id,
          title: widget.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        primary: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<PatientAIResult>>(
        future: _results,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorView(
              message: patientAIResultErrorMessage(snapshot.error!),
              onRetry: _reload,
            );
          }

          final results = snapshot.data ?? const <PatientAIResult>[];

          if (results.isEmpty) {
            return _EmptyView(
              title: widget.emptyTitle,
              message: widget.emptyMessage,
              icon: _emptyIcon,
              onRefresh: _reload,
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: results.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final result = results[index];

                return Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _openDetail(result),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              color: AppColors.lightBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.insights_outlined,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.title} 결과',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _dateText(result.generatedAt),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _summaryText(result),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '공개 완료',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.blue,
                                ),
                              ),
                              SizedBox(height: 12),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.mutedText,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// 공개된 AI 결과가 없을 때 표시
class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.title,
    required this.message,
    required this.icon,
    required this.onRefresh,
  });

  final String title;
  final String message;
  final IconData icon;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 100),
          Icon(icon, size: 56, color: AppColors.mutedText),
          SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.5, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

// AI 결과 목록 조회 오류 및 재시도 화면
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

// 목록에서 사용할 환자용 결과 요약 선택
String _summaryText(PatientAIResult result) {
  if (
    result.analysisType.trim().toUpperCase() == 'CLINICAL'
  ) {
    final probability =
        result.clinical?.probability ?? result.confidence;

    if (probability != null) {
      final score =
          (probability.clamp(0.0, 1.0) * 100)
              .toStringAsFixed(1);

      return 'AI 예측 점수 $score%';
    }

    return '심혈관 위험도 분석 결과를 확인해보세요.';
  }

  final summary = result.summaryText.trim();

  if (summary.isNotEmpty) {
    return summary;
  }

  for (final explanation in result.explanations) {
    final text = explanation.summaryText.trim();

    if (text.isNotEmpty) {
      return text;
    }
  }

  return 'AI 분석 결과가 확인되었습니다.';
}

// 분석 시간을 한국 날짜 형식으로 표시
String _dateText(DateTime date) {
  final kst = date.toUtc().add(const Duration(hours: 9));
  final month = kst.month.toString().padLeft(2, '0');
  final day = kst.day.toString().padLeft(2, '0');

  return '${kst.year}.$month.$day';
}
