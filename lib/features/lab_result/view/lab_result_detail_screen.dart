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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        primary: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          '혈액검사',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
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
      message: _wholeResultQuestion(
        detail.measurements
            .where((item) => !_isExcludedPatientLabMeasurement(item))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = detail.result;
    final measurements =
        detail.measurements
            .where((item) => !_isExcludedPatientLabMeasurement(item))
            .toList()
          ..sort(
            (a, b) => labDisplayPriority(
              a.code,
            ).compareTo(labDisplayPriority(b.code)),
          );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _dateTimeText(result.collectedAt),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              _ResultStatusBadge(status: result.status),
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

        _LabOverviewRangeCard(measurements: measurements),

        if (chatbotRepository != null) ...[
          const SizedBox(height: 14),
          _BomiGuideCard(
            imagePath: 'assets/images/bomi/bomi_lab_explain.png',
            title: '검사 결과가 궁금하신가요?',
            description: '보미가이해하기 쉽게 설명해드려요.',
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
  Future<LabTrend>? _trendFuture;

  @override
  void initState() {
    super.initState();
    _trendFuture = _buildTrendFuture();
  }

  @override
  void didUpdateWidget(covariant _MeasurementCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.repository != widget.repository ||
        oldWidget.measurement.code != widget.measurement.code) {
      _trendFuture = _buildTrendFuture();
    }
  }

  Future<LabTrend>? _buildTrendFuture() {
    final currentRepository = widget.repository;
    final code = widget.measurement.code.trim();

    if (currentRepository == null || code.isEmpty) {
      return null;
    }

    return currentRepository.getLabTrend(code);
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.55)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: canShowTrend ? () => _openTrend(context) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            info.koreanName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        if (education != null) ...[
                          const SizedBox(width: 2),
                          SizedBox(
                            width: 29,
                            height: 29,
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
                                size: 17,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AbnormalBadge(flag: measurement.normalizedFlag),
                ],
              ),

              if (info.subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  info.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],

              if (_showEducation && education != null) ...[
                const SizedBox(height: 10),
                _LabEducationBubble(info: education),
              ],

              const SizedBox(height: 11),

              LayoutBuilder(
                builder: (context, constraints) {
                  final textScale = MediaQuery.textScalerOf(context).scale(1);

                  final vertical =
                      constraints.maxWidth < 320 || textScale >= 1.3;

                  final valueArea = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 21,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '기준 ${measurement.displayReference}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );

                  if (!canShowTrend) {
                    return valueArea;
                  }

                  final trendArea = _InlineLabTrend(
                    future: _trendFuture,
                    referenceMin: measurement.referenceMin,
                    referenceMax: measurement.referenceMax,
                    fallbackLatestFlag: measurement.normalizedFlag,
                    onOpen: () => _openTrend(context),
                  );

                  if (vertical) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        valueArea,
                        const SizedBox(height: 10),
                        trendArea,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: valueArea),
                      const SizedBox(width: 12),
                      SizedBox(width: 150, child: trendArea),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabOverviewRangeCard extends StatefulWidget {
  const _LabOverviewRangeCard({required this.measurements});

  final List<LabMeasurement> measurements;

  @override
  State<_LabOverviewRangeCard> createState() => _LabOverviewRangeCardState();
}

class _LabOverviewRangeCardState extends State<_LabOverviewRangeCard> {
  bool _expanded = false;

  List<LabMeasurement> get _expandedMeasurements {
    final items = [...widget.measurements];

    items.sort((a, b) {
      final flagCompare = _rangeFlagRank(
        a.normalizedFlag,
      ).compareTo(_rangeFlagRank(b.normalizedFlag));

      if (flagCompare != 0) {
        return flagCompare;
      }

      return labDisplayPriority(a.code).compareTo(labDisplayPriority(b.code));
    });

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final measurements = widget.measurements;

    final preview = measurements.take(5).toList();
    final shown = _expanded ? _expandedMeasurements : preview;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monitor_heart_outlined,
                  size: 20,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '이번 검사 한눈에',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                if (measurements.length > 5)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _expanded = !_expanded;
                      });
                    },
                    child: Text(
                      _expanded ? '간단히 보기' : '전체 ${measurements.length}개 보기',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '각 지표의 현재값이 정상범위에서 어디에 위치하는지 보여줘요.',
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (!_expanded)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < shown.length; index++) ...[
                    if (index > 0) const SizedBox(width: 3),
                    Expanded(
                      child: _RangeGaugeItem(
                        measurement: shown[index],
                        compact: true,
                      ),
                    ),
                  ],
                ],
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 8.0;
                  final width = (constraints.maxWidth - spacing * 2) / 3;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: 16,
                    children: [
                      for (final measurement in shown)
                        SizedBox(
                          width: width,
                          child: _RangeGaugeItem(
                            measurement: measurement,
                            compact: false,
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _RangeGaugeItem extends StatelessWidget {
  const _RangeGaugeItem({required this.measurement, required this.compact});

  final LabMeasurement measurement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final info = labDisplayInfo(
      code: measurement.code,
      fallbackName: measurement.name,
    );

    final geometry = _rangeGaugeGeometry(measurement);
    final status = _shortRangeStatus(measurement.normalizedFlag);

    final Color markerColor = switch (measurement.normalizedFlag) {
      'HIGH' => const Color(0xFFD14B3E),
      'LOW' => const Color(0xFF3976D5),
      'NORMAL' => const Color(0xFF2B8A5E),
      _ => colors.primary,
    };

    final statusColor = switch (measurement.normalizedFlag) {
      'HIGH' => const Color(0xFFB42318),
      'LOW' => const Color(0xFF175CD3),
      'NORMAL' => const Color(0xFF067647),
      _ => colors.onSurfaceVariant,
    };

    final unit = measurement.displayUnit;
    final valueText = unit.isEmpty
        ? measurement.displayValue
        : '${measurement.displayValue} $unit';

    final gaugeHeight = compact ? 88.0 : 100.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: gaugeHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (geometry == null) {
                return Center(
                  child: Text(
                    '-',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                );
              }

              final height = constraints.maxHeight;
              final normalBottom = height * geometry.normalStart;
              final normalHeight =
                  height * (geometry.normalEnd - geometry.normalStart);

              final markerBottom = (height * geometry.markerPosition - 6)
                  .clamp(0.0, height - 12)
                  .toDouble();

              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: compact ? 11 : 13,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: normalBottom,
                    height: normalHeight,
                    child: Container(
                      width: compact ? 11 : 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBFE7CF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: markerBottom,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: markerColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: markerColor.withValues(alpha: 0.20),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 7),
        Text(
          info.koreanName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 9.5 : 11,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valueText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 9 : 10.5,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          geometry == null ? '범위 정보 없음' : status,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 9 : 10,
            fontWeight: FontWeight.w700,
            color: geometry == null ? colors.onSurfaceVariant : statusColor,
          ),
        ),
      ],
    );
  }
}

class _RangeGaugeGeometry {
  const _RangeGaugeGeometry({
    required this.normalStart,
    required this.normalEnd,
    required this.markerPosition,
  });

  final double normalStart;
  final double normalEnd;
  final double markerPosition;
}

_RangeGaugeGeometry? _rangeGaugeGeometry(LabMeasurement measurement) {
  final value = measurement.valueNumeric;

  if (value == null) {
    return null;
  }

  final min = measurement.referenceMin;
  final max = measurement.referenceMax;

  if (min != null && max != null && max > min) {
    const normalStart = 0.24;
    const normalEnd = 0.76;

    final ratio = (value - min) / (max - min);

    final marker = ratio < 0
        ? normalStart - ((-ratio).clamp(0.0, 1.0) * 0.19)
        : ratio > 1
        ? normalEnd + (((ratio - 1).clamp(0.0, 1.0)) * 0.19)
        : normalStart + (ratio * (normalEnd - normalStart));

    return _RangeGaugeGeometry(
      normalStart: normalStart,
      normalEnd: normalEnd,
      markerPosition: marker.clamp(0.05, 0.95).toDouble(),
    );
  }

  if (max != null && max > 0) {
    const normalStart = 0.10;
    const normalEnd = 0.72;

    final ratio = value / max;

    final marker = ratio <= 1
        ? normalStart + (ratio.clamp(0.0, 1.0) * (normalEnd - normalStart))
        : normalEnd + (((ratio - 1).clamp(0.0, 1.0)) * 0.23);

    return _RangeGaugeGeometry(
      normalStart: normalStart,
      normalEnd: normalEnd,
      markerPosition: marker.clamp(0.05, 0.95).toDouble(),
    );
  }

  if (min != null && min > 0) {
    const normalStart = 0.28;
    const normalEnd = 0.90;

    final ratio = value / min;

    final marker = ratio >= 1
        ? normalStart +
              (((ratio - 1).clamp(0.0, 1.0)) * (normalEnd - normalStart))
        : normalStart - (((1 - ratio).clamp(0.0, 1.0)) * 0.23);

    return _RangeGaugeGeometry(
      normalStart: normalStart,
      normalEnd: normalEnd,
      markerPosition: marker.clamp(0.05, 0.95).toDouble(),
    );
  }

  final flag = measurement.normalizedFlag;

  if (flag.isEmpty) {
    return null;
  }

  final marker = switch (flag) {
    'HIGH' => 0.90,
    'LOW' => 0.10,
    _ => 0.50,
  };

  return _RangeGaugeGeometry(
    normalStart: 0.25,
    normalEnd: 0.75,
    markerPosition: marker,
  );
}

int _rangeFlagRank(String flag) {
  return switch (flag) {
    'HIGH' || 'LOW' => 0,
    'NORMAL' => 1,
    _ => 2,
  };
}

String _shortRangeStatus(String flag) {
  return switch (flag) {
    'HIGH' => '높음',
    'LOW' => '낮음',
    'NORMAL' => '정상',
    _ => '미판정',
  };
}

class _InlineLabTrend extends StatelessWidget {
  const _InlineLabTrend({
    required this.future,
    required this.referenceMin,
    required this.referenceMax,
    required this.fallbackLatestFlag,
    required this.onOpen,
  });

  final Future<LabTrend>? future;
  final double? referenceMin;
  final double? referenceMax;
  final String fallbackLatestFlag;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final currentFuture = future;

    if (currentFuture == null) {
      return const SizedBox.shrink();
    }

    final hasNumericRange = referenceMin != null || referenceMax != null;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 7),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(12),
        ),
        child: FutureBuilder<LabTrend>(
          future: currentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return SizedBox(
                height: 66,
                child: Center(
                  child: Text(
                    '불러오는 중...',
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            final trend = snapshot.data;

            final points =
                trend?.results.where((item) => item.value != null).toList() ??
                <LabTrendPoint>[];

            points.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

            if (points.length < 2) {
              return SizedBox(
                height: 66,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart_rounded,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '추이 데이터 부족',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.25,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            final visible = points.length > 5
                ? points.sublist(points.length - 5)
                : points;

            final values = visible.map((item) => item.value!).toList();

            final trendLatestFlag = visible.last.normalizedFlag.isNotEmpty
                ? visible.last.normalizedFlag
                : fallbackLatestFlag;

            final latestColor = switch (trendLatestFlag) {
              'NORMAL' => const Color(0xFF2B8A5E),
              'HIGH' => const Color(0xFFD14B3E),
              'LOW' => const Color(0xFF3976D5),
              _ => colors.primary,
            };

            final normalBandColor = dark
                ? const Color(0xFF53B884).withValues(alpha: 0.15)
                : const Color(0xFFDFF3E7);

            final normalBoundaryColor = dark
                ? const Color(0xFF65C18C).withValues(alpha: 0.45)
                : const Color(0xFF9DD8B5);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.show_chart_rounded,
                      size: 13,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '지난 검사 추이',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    if (hasNumericRange) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: normalBandColor,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: normalBoundaryColor),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '정상범위',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _MiniTrendPainter(
                      values: values,
                      referenceMin: referenceMin,
                      referenceMax: referenceMax,
                      lineColor: colors.primary,
                      guideColor: colors.outlineVariant,
                      normalBandColor: normalBandColor,
                      normalBoundaryColor: normalBoundaryColor,
                      latestPointColor: latestColor,
                      pointFillColor: colors.surface,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _shortTrendDate(visible.first.measuredAt),
                      style: TextStyle(
                        fontSize: 8,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _shortTrendDate(visible.last.measuredAt),
                      style: TextStyle(
                        fontSize: 8,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MiniTrendPainter extends CustomPainter {
  const _MiniTrendPainter({
    required this.values,
    required this.referenceMin,
    required this.referenceMax,
    required this.lineColor,
    required this.guideColor,
    required this.normalBandColor,
    required this.normalBoundaryColor,
    required this.latestPointColor,
    required this.pointFillColor,
  });

  final List<double> values;
  final double? referenceMin;
  final double? referenceMax;
  final Color lineColor;
  final Color guideColor;
  final Color normalBandColor;
  final Color normalBoundaryColor;
  final Color latestPointColor;
  final Color pointFillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) {
      return;
    }

    final domainValues = <double>[...values, ?referenceMin, ?referenceMax];

    var minValue = domainValues.first;
    var maxValue = domainValues.first;

    for (final value in domainValues.skip(1)) {
      if (value < minValue) minValue = value;
      if (value > maxValue) maxValue = value;
    }

    if (maxValue == minValue) {
      final base = maxValue.abs() < 1 ? 1.0 : maxValue.abs() * 0.1;
      minValue -= base;
      maxValue += base;
    } else {
      final range = maxValue - minValue;
      final padding = range * 0.14;
      minValue -= padding;
      maxValue += padding;
    }

    double yFor(double value) {
      final ratio = ((value - minValue) / (maxValue - minValue)).clamp(
        0.0,
        1.0,
      );

      return 4 + (1 - ratio) * (size.height - 8);
    }

    // Shade only when a numeric reference range is available.
    if (referenceMin != null || referenceMax != null) {
      final normalLow = referenceMin ?? minValue;
      final normalHigh = referenceMax ?? maxValue;

      final top = yFor(normalHigh);
      final bottom = yFor(normalLow);

      final bandRect = Rect.fromLTRB(
        0,
        top.clamp(0.0, size.height).toDouble(),
        size.width,
        bottom.clamp(0.0, size.height).toDouble(),
      );

      final bandPaint = Paint()
        ..color = normalBandColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(bandRect, const Radius.circular(5)),
        bandPaint,
      );

      final boundaryPaint = Paint()
        ..color = normalBoundaryColor
        ..strokeWidth = 1;

      if (referenceMin != null) {
        final y = yFor(referenceMin!);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), boundaryPaint);
      }

      if (referenceMax != null) {
        final y = yFor(referenceMax!);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), boundaryPaint);
      }
    }

    final guidePaint = Paint()
      ..color = guideColor.withValues(alpha: 0.30)
      ..strokeWidth = 0.8;

    final centerY = size.height / 2;

    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      guidePaint,
    );

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final offsets = <Offset>[];

    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final y = yFor(values[index]);
      final offset = Offset(x, y);

      offsets.add(offset);

      if (index == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }

    canvas.drawPath(path, linePaint);

    final normalPointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final latestPointPaint = Paint()
      ..color = latestPointColor
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = pointFillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var index = 0; index < offsets.length; index++) {
      final point = offsets[index];
      final latest = index == offsets.length - 1;

      canvas.drawCircle(
        point,
        latest ? 4.5 : 3.2,
        latest ? latestPointPaint : normalPointPaint,
      );

      canvas.drawCircle(point, latest ? 4.5 : 3.2, pointBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniTrendPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.referenceMin != referenceMin ||
        oldDelegate.referenceMax != referenceMax ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.guideColor != guideColor ||
        oldDelegate.normalBandColor != normalBandColor ||
        oldDelegate.normalBoundaryColor != normalBoundaryColor ||
        oldDelegate.latestPointColor != latestPointColor ||
        oldDelegate.pointFillColor != pointFillColor;
  }
}

bool _isExcludedPatientLabMeasurement(LabMeasurement measurement) {
  final code = measurement.code.trim().toUpperCase();
  final name = measurement.name.trim().toUpperCase();

  final normalizedCode = code.replaceAll('_', '-').replaceAll(' ', '');

  return code == 'LVEF' ||
      code.contains('LVEF') ||
      code == 'EF-TTE' ||
      code == 'EF_TTE' ||
      normalizedCode == 'EF-TTE' ||
      normalizedCode == 'EFTTE' ||
      name.contains('LVEF') ||
      name.contains('EJECTION FRACTION') ||
      name.contains('LEFT VENTRICULAR EJECTION FRACTION') ||
      name.contains('좌심실 박출률');
}

String _shortTrendDate(DateTime date) {
  final kst = date.toUtc().add(const Duration(hours: 9));

  String two(int value) => value.toString().padLeft(2, '0');

  return '${two(kst.month)}.${two(kst.day)}';
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: dark
            ? colors.surfaceContainerHighest.withValues(alpha: 0.28)
            : const Color(0xFFFFFCFD),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: dark
              ? colors.outlineVariant.withValues(alpha: 0.42)
              : const Color(0xFFE9DDE1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.3,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: dark
                    ? colors.primary
                    : const Color(0xFFA64D69),
                backgroundColor: dark
                    ? Colors.transparent
                    : const Color(0xFFFFF8FA),
                side: BorderSide(
                  color: dark ? colors.outlineVariant : const Color(0xFFE7CDD5),
                ),
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                textStyle: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(buttonText, maxLines: 1),
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
        label = '정상 범위 외';
        foreground = const Color(0xFFB42318);
        background = const Color(0xFFFFE9E7);
        break;
      case 'LOW':
        label = '정상 범위 외';
        foreground = const Color(0xFF175CD3);
        background = const Color(0xFFEAF2FF);
        break;
      case 'NORMAL':
        label = '정상 범위';
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

String _dateTimeText(DateTime date) {
  final kst = date.toUtc().add(const Duration(hours: 9));

  String two(int value) => value.toString().padLeft(2, '0');

  return '${kst.year}.${two(kst.month)}.${two(kst.day)} '
      '${two(kst.hour)}:${two(kst.minute)}';
}
