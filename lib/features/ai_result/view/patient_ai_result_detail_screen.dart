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
    this.title = 'AI 분석 결과',
  });

  final PatientAIResultRepository repository;
  final int resultId;
  final String title;

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
            onPressed: _retry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
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

    final analysisType = result.analysisType.trim().toUpperCase();
    final isXca = analysisType == 'ANGIO_2D';
    final isCcta = analysisType == 'CCTA';
    final isClinical = analysisType == 'CLINICAL';
    final clinical = result.clinical;
    final hasXcaFindings =
        result.lesions.isNotEmpty || result.detections.isNotEmpty;
    final cacScore = result.cacScores.isNotEmpty
        ? result.cacScores.first
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: 17,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '분석일시',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dateText(result.generatedAt),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '공개 완료',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Divider(
          height: 1,
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        const SizedBox(height: 14),

        if (isXca && hasXcaFindings) ...[
          _XcaResultCard(result: result),
          const SizedBox(height: 16),
        ],

        if (isCcta && cacScore != null) ...[
          _CctaCalciumCard(score: cacScore),
          const SizedBox(height: 16),
        ],

        if ((isXca || isCcta) && result.images.isNotEmpty) ...[
          _SectionCard(
            title: isXca
                ? '혈관조영술 대표 이미지'
                : '관상동맥 CT 대표 이미지',
            icon: Icons.image_outlined,
            subtitle: '의료진 확인 후 공개된 대표 이미지를 확인할 수 있어요.',
            child: Column(
              children: [
                for (var index = 0;
                    index < result.images.length;
                    index++) ...[
                  if (index > 0) const SizedBox(height: 16),
                  _PatientAIImageCard(
                    image: result.images[index],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (isClinical && clinical != null) ...[
          _ClinicalRiskCard(clinical: clinical),
          const SizedBox(height: 16),
        ],

        // Clinical은 작업 완료 문구 대신 전용 예측 결과만 표시
        if (!isClinical)
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
            subtitle: 'AI 분석 내용을 이해하기 쉬운 문장으로 정리한 설명이에요.',
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

// 결과 요약과 XAI 설명에 사용하는 공통 카드

// ?? ? XCA/CCTA ?? UI? ?? API ?? ???? ?? ?? Preview wrapper.
// ?? ????? ???? ???.
class PatientAIResultPreviewBody extends StatelessWidget {
  const PatientAIResultPreviewBody({super.key, required this.result});

  final PatientAIResult result;

  @override
  Widget build(BuildContext context) {
    return _ResultContent(result: result);
  }
}

class _XcaResultCard extends StatelessWidget {
  const _XcaResultCard({required this.result});

  final PatientAIResult result;

  @override
  Widget build(BuildContext context) {
    final stenosisValues = result.lesions
        .map((item) => item.stenosisPercent)
        .whereType<double>()
        .toList();

    final maxStenosis = stenosisValues.isEmpty
        ? null
        : stenosisValues.reduce((a, b) => a > b ? a : b);

    final vessels = <String>{
      for (final lesion in result.lesions)
        if (lesion.arteryName.trim().isNotEmpty) lesion.arteryName.trim(),
    };

    final findingCount = result.lesions.isNotEmpty
        ? result.lesions.length
        : result.detections.length;

    return _SectionCard(
      title: '\ud608\uad00\uc870\uc601\uc220 \uc8fc\uc694 \uacb0\uacfc',
      icon: Icons.monitor_heart_outlined,
      subtitle:
          '\uacf5\uac1c\ub41c \ubd84\uc11d \uacb0\uacfc\uc5d0\uc11c \ud611\ucc29\uacfc \ubcd1\ubcc0 \uc815\ubcf4\ub97c \uc815\ub9ac\ud588\uc5b4\uc694.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ResultMetricTile(
                  label: '\ucd5c\ub300 \ud611\ucc29\ub960',
                  value: _percentText(maxStenosis),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ResultMetricTile(
                  label: '\ubcd1\ubcc0 \uc218',
                  value: '$findingCount\uac74',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ResultMetricTile(
                  label: '\ud655\uc778 \ud608\uad00',
                  value: vessels.isEmpty ? '-' : '${vessels.length}\uacf3',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(
            height: 1,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 14),
          Text(
            result.lesions.isNotEmpty
                ? '\ud611\ucc29 \ubc0f \ubcd1\ubcc0 \uc815\ubcf4'
                : '\ud0d0\uc9c0 \uc815\ubcf4',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),

          if (result.lesions.isNotEmpty)
            for (var index = 0; index < result.lesions.length; index++) ...[
              if (index > 0)
                Divider(
                  height: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              _LesionResultRow(lesion: result.lesions[index]),
            ]
          else
            for (var index = 0; index < result.detections.length; index++) ...[
              if (index > 0)
                Divider(
                  height: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              _DetectionResultRow(detection: result.detections[index]),
            ],
        ],
      ),
    );
  }
}

class _CctaCalciumCard extends StatelessWidget {
  const _CctaCalciumCard({required this.score});

  final PatientAICacScore score;

  @override
  Widget build(BuildContext context) {
    final risk = _riskLabel(score.riskCategory);

    return _SectionCard(
      title: '\uad00\uc0c1\ub3d9\ub9e5 \uc11d\ud68c\ud654 \ubd84\uc11d',
      icon: Icons.view_in_ar_rounded,
      subtitle:
          '\ucd1d CAC \uc810\uc218\uc640 \ud608\uad00\ubcc4 \uc11d\ud68c\ud654 \uc815\ubcf4\ub97c \uc815\ub9ac\ud588\uc5b4\uc694.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '\ucd1d CAC \uc810\uc218',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                _numberText(score.scoreValue),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          if (risk.isNotEmpty || score.percentile != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (risk.isNotEmpty)
                  _ResultTag(
                    icon: Icons.health_and_safety_outlined,
                    text: risk,
                  ),
                if (score.percentile != null)
                  _ResultTag(
                    icon: Icons.stacked_line_chart_rounded,
                    text: '\ubc31\ubd84\uc704 ${_numberText(score.percentile)}',
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Divider(
            height: 1,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 14),
          Text(
            '\ud608\uad00\ubcc4 CAC \uc810\uc218',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ResultMetricTile(
                  label: 'LAD',
                  value: _numberText(score.ladScore),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ResultMetricTile(
                  label: 'LCX',
                  value: _numberText(score.lcxScore),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ResultMetricTile(
                  label: 'RCA',
                  value: _numberText(score.rcaScore),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'CAC \uc810\uc218\ub294 \uad00\uc0c1\ub3d9\ub9e5 \uc11d\ud68c\ud654 \uc815\ub3c4\ub97c '
            '\ub098\ud0c0\ub0b4\ub294 \uc9c0\ud45c\uc785\ub2c8\ub2e4. '
            '\ucd5c\uc885 \ud310\ub2e8\uc740 \uc758\ub8cc\uc9c4\uc758 \uc124\uba85\uacfc \ud568\uaed8 '
            '\ud655\uc778\ud574 \uc8fc\uc138\uc694.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultMetricTile extends StatelessWidget {
  const _ResultMetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _LesionResultRow extends StatelessWidget {
  const _LesionResultRow({required this.lesion});

  final PatientAILesion lesion;

  @override
  Widget build(BuildContext context) {
    final artery = _arteryLabel(lesion.arteryName);
    final segment = lesion.segmentName.trim();
    final location = [
      if (artery.isNotEmpty) artery,
      if (segment.isNotEmpty) segment,
    ].join(' \u00b7 ');

    final severity = _severityLabel(lesion.severityGrade);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.isEmpty ? '\ud608\uad00 \ubd80\uc704' : location,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (severity.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    severity,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _percentText(lesion.stenosisPercent),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectionResultRow extends StatelessWidget {
  const _DetectionResultRow({required this.detection});

  final PatientAIDetection detection;

  @override
  Widget build(BuildContext context) {
    final segment = detection.arterySegment.trim();
    final finding = _findingLabel(detection.findingType);
    final severity = _severityLabel(detection.severity);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  segment.isEmpty
                      ? '\uad00\uc0c1\ub3d9\ub9e5 \ubd80\uc704'
                      : segment,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (finding.isNotEmpty) finding,
                    if (severity.isNotEmpty) severity,
                  ].join(' \u00b7 '),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _ResultTag extends StatelessWidget {
  const _ResultTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

String _numberText(double? value) {
  if (value == null) return '-';

  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(1);
}

String _percentText(double? value) {
  if (value == null) return '-';
  return '${_numberText(value)}%';
}

String _arteryLabel(String raw) {
  final value = raw.trim();
  final upper = value.toUpperCase();

  return switch (upper) {
    'LAD' => 'LAD (\uc88c\uc804\ud558\ud589\uc9c0)',
    'LCX' => 'LCX (\uc88c\ud68c\uc120\uc9c0)',
    'RCA' => 'RCA (\uc6b0\uad00\uc0c1\ub3d9\ub9e5)',
    'LM' || 'LMCA' => 'LM (\uc88c\uc8fc\uad00\uc0c1\ub3d9\ub9e5)',
    _ => value,
  };
}

String _severityLabel(String raw) {
  final value = raw.trim();
  final upper = value.toUpperCase();

  return switch (upper) {
    'MILD' => '\uacbd\ub3c4',
    'MODERATE' => '\uc911\ub4f1\ub3c4',
    'SEVERE' => '\uc911\uc99d',
    'CRITICAL' => '\uace0\ub3c4',
    'LOW' => '\ub0ae\uc74c',
    'HIGH' => '\ub192\uc74c',
    _ => value,
  };
}

String _findingLabel(String raw) {
  final value = raw.trim();
  final upper = value.toUpperCase();

  return switch (upper) {
    'STENOSIS' => '\ud611\ucc29',
    'PLAQUE' => '\ud50c\ub77c\ud06c',
    'LESION' => '\ubcd1\ubcc0',
    _ => value,
  };
}

String _riskLabel(String raw) {
  final value = raw.trim();
  final upper = value.toUpperCase();

  return switch (upper) {
    'NONE' || 'ZERO' => '\uc11d\ud68c\ud654 \uc704\ud5d8 \ub0ae\uc74c',
    'LOW' => '\uc11d\ud68c\ud654 \uc704\ud5d8 \ub0ae\uc74c',
    'MODERATE' => '\uc11d\ud68c\ud654 \uc704\ud5d8 \uc911\uac04',
    'HIGH' => '\uc11d\ud68c\ud654 \uc704\ud5d8 \ub192\uc74c',
    'VERY_HIGH' ||
    'VERY HIGH' => '\uc11d\ud68c\ud654 \uc704\ud5d8 \ub9e4\uc6b0 \ub192\uc74c',
    _ => value,
  };
}

// Clinical AI 예측값을 환자에게 이해하기 쉬운 형태로 표시
class _ClinicalRiskCard extends StatelessWidget {
  const _ClinicalRiskCard({
    required this.clinical,
  });

  final PatientAIClinical clinical;

  @override
  Widget build(BuildContext context) {
    final probability = clinical.probability;

    final probabilityText = probability == null
        ? '-'
        : '${(probability.clamp(0.0, 1.0) * 100).toStringAsFixed(1)}%';

    return _SectionCard(
      title: 'AI 예측 결과',
      icon: Icons.favorite_outline_rounded,
      subtitle:
          '임상정보와 검사 데이터를 바탕으로 산출한 참고용 AI 예측 결과예요.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI 예측 점수',
            style: TextStyle(
              fontSize: 12,
              color:
                  Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            probabilityText,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'AI 모델이 입력된 건강 정보를 바탕으로 산출한 '
            '참고용 예측값입니다. 질환의 확진이나 실제 발병 '
            '확률을 의미하지 않으며, 의료진의 설명과 함께 '
            '확인해 주세요.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color:
                  Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}


// 공개된 XCA/CCTA 대표 이미지를 표시
class _PatientAIImageCard extends StatelessWidget {
  const _PatientAIImageCard({required this.image});

  final PatientAIImage image;

  @override
  Widget build(BuildContext context) {
    final url = image.url.trim();
    final label = image.label.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: ColoredBox(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              child: url.isEmpty
                  ? const _PatientAIImageFallback()
                  : Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (
                        context,
                        child,
                        progress,
                      ) {
                        if (progress == null) {
                          return child;
                        }

                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const _PatientAIImageFallback();
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}


// 이미지 URL 만료 또는 네트워크 오류 시 안내
class _PatientAIImageFallback extends StatelessWidget {
  const _PatientAIImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '이미지를 불러오지 못했어요.\n'
          '새로고침 후 다시 확인해 주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 1.45,
            color: AppColors.mutedText,
          ),
        ),
      ),
    );
  }
}


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
  final hour = kst.hour.toString().padLeft(2, '0');
  final minute = kst.minute.toString().padLeft(2, '0');

  return '${kst.year}.$month.$day $hour:$minute';
}
