import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../chatbot/repository/chatbot_repository.dart';
import '../model/lab_display_info.dart';
import '../model/lab_education_info.dart';
import '../model/lab_result.dart';
import '../repository/lab_result_repository.dart';
import 'lab_chatbot_navigation.dart';
import 'lab_result_trend_screen.dart';

class LabResultDetailScreen extends StatefulWidget {
  const LabResultDetailScreen({
    super.key,
    required this.result,
    this.repository,
    this.chatbotRepository,
  });

  final LabResult result;
  final LabResultDetailRepository? repository;
  final ChatbotRepository? chatbotRepository;

  @override
  State<LabResultDetailScreen> createState() => _LabResultDetailScreenState();
}

class _LabResultDetailScreenState extends State<LabResultDetailScreen> {
  Future<LabResultDetail>? _detail;

  @override
  void initState() {
    super.initState();

    final repository = widget.repository;
    if (repository != null) {
      _detail = repository.getLabResult(widget.result.id);
    }
  }

  Future<void> _reload() async {
    final repository = widget.repository;
    if (repository == null) {
      return;
    }

    final future = repository.getLabResult(widget.result.id);

    setState(() {
      _detail = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder에서 오류 상태를 표시합니다.
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailFuture = _detail;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('혈액검사 결과'),
        actions: [
          if (widget.repository != null)
            IconButton(
              tooltip: '새로고침',
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: detailFuture == null
          ? _DetailContent(
              detail: LabResultDetail(
                result: widget.result,
                measurements: const [],
              ),
              repository: null,
              chatbotRepository: widget.chatbotRepository,
            )
          : FutureBuilder<LabResultDetail>(
              future: detailFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _DetailErrorView(
                    error: snapshot.error!,
                    onRetry: _reload,
                  );
                }

                final detail = snapshot.data;
                if (detail == null) {
                  return _DetailErrorView(
                    error: const FormatException('혈액검사 상세 응답이 비어 있습니다.'),
                    onRetry: _reload,
                  );
                }

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: _DetailContent(
                    detail: detail,
                    repository: widget.repository,
                    chatbotRepository: widget.chatbotRepository,
                  ),
                );
              },
            ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.detail,
    required this.repository,
    required this.chatbotRepository,
  });

  final LabResultDetail detail;
  final LabResultDetailRepository? repository;
  final ChatbotRepository? chatbotRepository;

  Future<void> _askAboutWholeResult(BuildContext context) async {
    final chatbot = chatbotRepository;
    if (chatbot == null) {
      return;
    }

    await openLabChatbot(
      context: context,
      repository: chatbot,
      message: _wholeResultQuestion(detail.measurements),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = detail.result;
    final measurements = [...detail.measurements]
      ..sort(
        (a, b) =>
            labDisplayPriority(a.code).compareTo(labDisplayPriority(b.code)),
      );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.science_outlined,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.displayTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateTimeText(result.collectedAt),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              _ResultStatusBadge(status: result.status),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.fact_check_outlined,
                      size: 20,
                      color: AppColors.blue,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '이번 검사 한눈에',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _overviewText(measurements),
                  style: const TextStyle(height: 1.6, color: AppColors.text),
                ),
              ],
            ),
          ),
        ),

        if (chatbotRepository != null) ...[
          const SizedBox(height: 14),
          _BomiGuideCard(
            imagePath: 'assets/images/bomi/bomi_lab_explain.png',
            title: '검사 결과가 궁금하신가요?',
            description: '보미가 검사 결과를 이해하기 쉽게 설명해드려요.',
            buttonText: '보미에게 물어보기',
            onPressed: () => _askAboutWholeResult(context),
          ),
        ],

        const SizedBox(height: 22),

        Row(
          children: [
            const Expanded(
              child: Text(
                '검사 수치',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ),
            Text(
              '${measurements.length}개 항목',
              style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (measurements.isEmpty)
          const _EmptyMeasurements()
        else
          ...measurements.map(
            (measurement) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MeasurementCard(
                measurement: measurement,
                repository: repository,
                chatbotRepository: chatbotRepository,
              ),
            ),
          ),
      ],
    );
  }
}

class _MeasurementCard extends StatefulWidget {
  const _MeasurementCard({
    required this.measurement,
    required this.repository,
    required this.chatbotRepository,
  });

  final LabMeasurement measurement;
  final LabResultDetailRepository? repository;
  final ChatbotRepository? chatbotRepository;

  @override
  State<_MeasurementCard> createState() => _MeasurementCardState();
}

class _MeasurementCardState extends State<_MeasurementCard> {
  bool _showEducation = false;

  LabMeasurement get measurement => widget.measurement;

  LabResultDetailRepository? get repository => widget.repository;

  ChatbotRepository? get chatbotRepository => widget.chatbotRepository;

  void _openTrend(BuildContext context) {
    final currentRepository = repository;
    final code = measurement.code.trim();

    if (currentRepository == null || code.isEmpty) {
      return;
    }

    final info = labDisplayInfo(
      code: measurement.code,
      fallbackName: measurement.name,
    );

    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LabResultTrendScreen(
          repository: currentRepository,
          code: code,
          fallbackName: info.koreanName,
          referenceMin: measurement.referenceMin,
          referenceMax: measurement.referenceMax,
          referenceText: measurement.displayReference,
          chatbotRepository: chatbotRepository,
        ),
      ),
    );
  }

  Future<void> _askBomi(BuildContext context) async {
    final chatbot = chatbotRepository;
    if (chatbot == null) {
      return;
    }

    final info = labDisplayInfo(
      code: measurement.code,
      fallbackName: measurement.name,
    );

    final unit = measurement.displayUnit;
    final value = unit.isEmpty
        ? measurement.displayValue
        : '${measurement.displayValue} $unit';

    final reference = measurement.displayReference;
    final referenceWithUnit = reference == '-' || unit.isEmpty
        ? reference
        : '$reference $unit';

    final referenceSentence = reference == '-'
        ? ''
        : ' 정상범위는 $referenceWithUnit이야.';

    await openLabChatbot(
      context: context,
      repository: chatbot,
      message:
          '${info.koreanName}(${info.code}) $value 결과를 쉽게 설명해줘.'
          '$referenceSentence',
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = labDisplayInfo(
      code: measurement.code,
      fallbackName: measurement.name,
    );

    final education = labEducationInfo(measurement.code);

    final unit = measurement.displayUnit;
    final value = unit.isEmpty
        ? measurement.displayValue
        : '${measurement.displayValue} $unit';

    final canShowTrend =
        repository != null && measurement.code.trim().isNotEmpty;

    final canAskBomi = chatbotRepository != null;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              info.koreanName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          if (education != null) ...[
                            const SizedBox(width: 3),
                            SizedBox(
                              width: 34,
                              height: 34,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                tooltip: '${info.koreanName} 설명 보기',
                                onPressed: () {
                                  setState(() {
                                    _showEducation = !_showEducation;
                                  });
                                },
                                icon: Icon(
                                  _showEducation
                                      ? Icons.cancel_outlined
                                      : Icons.error_outline_rounded,
                                  size: 18,
                                  color: const Color(0xFF718096),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (info.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          info.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _AbnormalBadge(flag: measurement.normalizedFlag),
              ],
            ),

            if (_showEducation && education != null) ...[
              const SizedBox(height: 10),
              _LabEducationBubble(info: education),
            ],

            const SizedBox(height: 14),

            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 11),

            _InfoRow(label: '정상범위', value: measurement.displayReference),

            if (measurement.measuredAt != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                label: '측정일시',
                value: _dateTimeText(measurement.measuredAt!),
              ),
            ],

            if (canShowTrend || canAskBomi) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  if (canShowTrend)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openTrend(context),
                        icon: const Icon(Icons.show_chart_rounded),
                        label: const Text('추이 보기'),
                      ),
                    ),
                  if (canShowTrend && canAskBomi) const SizedBox(width: 8),
                  if (canAskBomi)
                    Expanded(
                      child: FilledButton.icon(
                        style: _bomiButtonStyle(compact: true),
                        onPressed: () => _askBomi(context),
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                        ),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('보미에게 물어보기', maxLines: 1),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LabEducationBubble extends StatelessWidget {
  const _LabEducationBubble({required this.info});

  final LabEducationInfo info;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(15, 16, 15, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFDCE3EA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${info.title}이란?',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                info.summary,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '왜 확인하나요?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                info.whyItMatters,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.mutedText,
                ),
              ),
              if (info.note != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    info.note!,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.45,
                      color: AppColors.mutedText,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                '출처 · ${info.sourceLabel}',
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.4,
                  color: Color(0xFF8A94A3),
                ),
              ),
            ],
          ),
        ),

        Positioned(
          top: -5,
          left: 24,
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 11,
              height: 11,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  left: BorderSide(color: Color(0xFFDCE3EA)),
                  top: BorderSide(color: Color(0xFFDCE3EA)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}

class _BomiGuideCard extends StatelessWidget {
  const _BomiGuideCard({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onPressed,
  });

  final String imagePath;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD6DC)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            height: 82,
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: _bomiButtonStyle(),
                    onPressed: onPressed,
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                    ),
                    label: Text(buttonText, maxLines: 1),
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

class _AbnormalBadge extends StatelessWidget {
  const _AbnormalBadge({required this.flag});

  final String flag;

  @override
  Widget build(BuildContext context) {
    String label;
    Color foreground;
    Color background;

    switch (flag) {
      case 'HIGH':
        label = '높음 HIGH';
        foreground = const Color(0xFFB42318);
        background = const Color(0xFFFFE9E7);
        break;
      case 'LOW':
        label = '낮음 LOW';
        foreground = const Color(0xFF175CD3);
        background = const Color(0xFFEAF2FF);
        break;
      case 'NORMAL':
        label = '정상';
        foreground = const Color(0xFF067647);
        background = const Color(0xFFE9F7EF);
        break;
      default:
        label = '미판정';
        foreground = AppColors.mutedText;
        background = const Color(0xFFF1F3F5);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

class _ResultStatusBadge extends StatelessWidget {
  const _ResultStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.blue,
        ),
      ),
    );
  }
}

class _EmptyMeasurements extends StatelessWidget {
  const _EmptyMeasurements();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Icon(Icons.biotech_outlined, size: 42, color: AppColors.mutedText),
            SizedBox(height: 12),
            Text(
              '등록된 검사 결과가 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailErrorView extends StatelessWidget {
  const _DetailErrorView({required this.error, required this.onRetry});

  final Object error;
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
            Text(
              patientLabResultErrorMessage(error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

String _overviewText(List<LabMeasurement> measurements) {
  if (measurements.isEmpty) {
    return '등록된 검사 수치가 없습니다.';
  }

  final normal = measurements
      .where((item) => item.normalizedFlag == 'NORMAL')
      .length;
  final high = measurements
      .where((item) => item.normalizedFlag == 'HIGH')
      .length;
  final low = measurements.where((item) => item.normalizedFlag == 'LOW').length;

  final unknown = measurements.length - normal - high - low;

  final parts = <String>[
    if (normal > 0) '정상 $normal개',
    if (high > 0) '높음 $high개',
    if (low > 0) '낮음 $low개',
    if (unknown > 0) '미판정 $unknown개',
  ];

  return '${measurements.length}개 검사 항목 중 '
      '${parts.join(', ')}로 표시됐어요. '
      '각 항목의 수치와 이전 검사와의 변화를 함께 확인해 보세요.';
}

String _wholeResultQuestion(List<LabMeasurement> measurements) {
  if (measurements.isEmpty) {
    return '이번 혈액검사 결과를 어떻게 보면 되는지 쉽게 설명해줘.';
  }

  final normal = measurements
      .where((item) => item.normalizedFlag == 'NORMAL')
      .length;

  final high = measurements
      .where((item) => item.normalizedFlag == 'HIGH')
      .length;

  final low = measurements.where((item) => item.normalizedFlag == 'LOW').length;

  final attentionItems = measurements
      .where(
        (item) => item.normalizedFlag == 'HIGH' || item.normalizedFlag == 'LOW',
      )
      .map((item) {
        final info = labDisplayInfo(code: item.code, fallbackName: item.name);

        final unit = item.displayUnit;
        final value = unit.isEmpty
            ? item.displayValue
            : '${item.displayValue} $unit';

        return '${info.koreanName}(${info.code}) $value '
            '${_flagQuestionText(item.normalizedFlag)}';
      })
      .join(', ');

  final attentionSentence = attentionItems.isEmpty
      ? ''
      : ' 정상범위를 벗어난 항목은 $attentionItems이야.';

  return '이번 혈액검사에서 총 ${measurements.length}개 항목 중 '
      '정상 $normal개, 높음 $high개, 낮음 $low개로 표시됐어.'
      '$attentionSentence 결과를 쉽게 설명해줘.';
}

String _flagQuestionText(String flag) {
  return switch (flag) {
    'HIGH' => '높음',
    'LOW' => '낮음',
    'NORMAL' => '정상',
    _ => '미판정',
  };
}

String _statusLabel(String status) {
  return switch (status.toUpperCase()) {
    'FINAL' => '확정 결과',
    'CORRECTED' => '수정됨',
    'DRAFT' => '작성 중',
    _ => status,
  };
}

ButtonStyle _bomiButtonStyle({bool compact = false}) {
  return FilledButton.styleFrom(
    backgroundColor: const Color(0xFFFFE3EA),
    foregroundColor: const Color(0xFFA42652),
    elevation: 0,
    minimumSize: const Size(0, 44),
    padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 11),
    textStyle: TextStyle(
      fontSize: compact ? 12 : 13,
      fontWeight: FontWeight.w800,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

String _dateTimeText(DateTime date) {
  final kst = date.toUtc().add(const Duration(hours: 9));

  String two(int value) => value.toString().padLeft(2, '0');

  return '${kst.year}.${two(kst.month)}.${two(kst.day)} '
      '${two(kst.hour)}:${two(kst.minute)}';
}
