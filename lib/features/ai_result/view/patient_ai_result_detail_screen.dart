import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/patient_ai_result.dart';
import '../repository/patient_ai_result_repository.dart';

// 공개된 AI 결과와 환자용 XAI 설명을 보여주는 상세 화면
class PatientAIResultDetailScreen extends StatefulWidget {
  const PatientAIResultDetailScreen({
    super.key,
    required this.repository,
    required this.resultId,
  });

  final PatientAIResultRepository repository;
  final int resultId;

  @override
  State<PatientAIResultDetailScreen> createState() =>
      _PatientAIResultDetailScreenState();
}

class _PatientAIResultDetailScreenState
    extends State<PatientAIResultDetailScreen> {
  late Future<PatientAIResult> _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // 최신 AI 결과 상세를 API에서 다시 조회
  void _load() {
    _result = widget.repository.getResult(widget.resultId);
  }

  // 상세 조회 실패 시 다시 요청
  void _retry() {
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('AI 분석 결과')),
      body: FutureBuilder<PatientAIResult>(
        future: _result,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _DetailErrorView(
              message: patientAIResultErrorMessage(snapshot.error!),
              onRetry: _retry,
            );
          }

          final result = snapshot.data;

          if (result == null) {
            return _DetailErrorView(
              message: 'AI 결과를 확인하지 못했어요.',
              onRetry: _retry,
            );
          }

          return _ResultContent(result: result);
        },
      ),
    );
  }
}

// 환자에게 필요한 요약과 XAI 설명만 구성
class _ResultContent extends StatelessWidget {
  const _ResultContent({required this.result});

  final PatientAIResult result;

  @override
  Widget build(BuildContext context) {
    final explanations = result.explanations
        .map((item) => item.summaryText.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              _ResultIcon(),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI 분석 결과',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '의료진 검토 후 공개된 결과입니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 분석 날짜와 공개 상태 표시
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _InfoRow(label: '분석일', value: _dateText(result.generatedAt)),
                const Divider(height: 28),
                const _InfoRow(label: '상태', value: '공개 완료'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Backend summary_text를 환자용 결과 요약으로 표시
        _SectionCard(
          title: '결과 요약',
          icon: Icons.assignment_outlined,
          child: Text(
            _summaryText(result),
            style: const TextStyle(height: 1.65, color: AppColors.text),
          ),
        ),

        if (explanations.isNotEmpty) ...[
          const SizedBox(height: 16),

          // XAI 설명 결과를 환자가 이해하기 쉬운 문장 영역에 표시
          _SectionCard(
            title: 'AI가 쉽게 설명해 드려요',
            icon: Icons.auto_awesome_outlined,
            subtitle: 'XAI 분석 근거를 환자가 이해하기 쉬운 문장으로 정리한 내용이에요.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < explanations.length; index++) ...[
                  if (index > 0) const Divider(height: 28),
                  Text(
                    explanations[index],
                    style: const TextStyle(height: 1.65, color: AppColors.text),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (result.keyFactors.isNotEmpty) ...[
          const SizedBox(height: 16),

          // XAI 주요 영향 요인
          _SectionCard(
            title: '주요 영향 요인',
            icon: Icons.bar_chart_rounded,
            subtitle: 'AI 결과에 상대적으로 영향을 준 요인을 쉽게 정리한 내용이에요.',
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < result.keyFactors.length;
                  index++
                ) ...[
                  if (index > 0) const SizedBox(height: 18),
                  _ImpactFactorRow(factor: result.keyFactors[index]),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        // AI 결과가 진료 판단을 대신하지 않음을 안내
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: AppColors.mutedText,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI 분석 결과는 의료진의 진료와 설명을 함께 참고해 주세요.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// AI 결과 화면 공통 아이콘
class _ResultIcon extends StatelessWidget {
  const _ResultIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.insights_outlined, color: AppColors.navy),
    );
  }
}

// 상세 화면의 정보 행
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// 결과 요약과 XAI 설명에 사용하는 공통 카드
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.navy),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 7),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.mutedText,
                ),
              ),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

// AI 결과 상세 오류 및 재시도 화면
// 영향 요인을 상대적인 막대로 표시
class _ImpactFactorRow extends StatelessWidget {
  const _ImpactFactorRow({required this.factor});

  final PatientAIKeyFactor factor;

  @override
  Widget build(BuildContext context) {
    final impact = (factor.impact ?? 0).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                factor.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ),
            if (factor.impactLabel.trim().isNotEmpty)
              Text(
                factor.impactLabel,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: impact,
            minHeight: 8,
            backgroundColor: AppColors.lightBlue,
            color: AppColors.blue,
          ),
        ),
      ],
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

// 요약이 없으면 XAI 설명 또는 기본 안내를 대신 표시
String _summaryText(PatientAIResult result) {
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

// 서버 시간을 한국 시간 기준 날짜로 표시
String _dateText(DateTime date) {
  final kst = date.toUtc().add(const Duration(hours: 9));
  final month = kst.month.toString().padLeft(2, '0');
  final day = kst.day.toString().padLeft(2, '0');

  return '${kst.year}.$month.$day';
}
