import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../chatbot/repository/chatbot_repository.dart';
import '../model/lab_display_info.dart';
import '../model/lab_result.dart';
import '../repository/lab_result_repository.dart';
import 'lab_result_trend_screen.dart';

class LabResultOverallTrendScreen extends StatefulWidget {
  const LabResultOverallTrendScreen({
    super.key,
    required this.repository,
    required this.measurements,
    this.chatbotRepository,
  });

  final LabResultDetailRepository repository;
  final List<LabMeasurement> measurements;
  final ChatbotRepository? chatbotRepository;

  @override
  State<LabResultOverallTrendScreen> createState() =>
      _LabResultOverallTrendScreenState();
}

class _LabResultOverallTrendScreenState
    extends State<LabResultOverallTrendScreen> {
  late Future<List<_OverallTrendItem>> _items;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _items = _loadItems();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<List<_OverallTrendItem>> _loadItems() async {
    final seen = <String>{};
    final measurements = widget.measurements.where((measurement) {
      final code = measurement.code.trim();
      if (code.isEmpty || !seen.add(code)) {
        return false;
      }
      return true;
    }).toList();

    return Future.wait(
      measurements.map((measurement) async {
        try {
          final trend = await widget.repository.getLabTrend(
            measurement.code.trim(),
          );

          return _OverallTrendItem(measurement: measurement, trend: trend);
        } catch (error) {
          return _OverallTrendItem(measurement: measurement, error: error);
        }
      }),
    );
  }

  Future<void> _reload() async {
    final future = _loadItems();

    setState(() {
      _items = future;
    });

    await future;
  }

  Future<void> _openTrend(_OverallTrendItem item) async {
    final measurement = item.measurement;
    final code = measurement.code.trim();

    if (code.isEmpty) {
      return;
    }

    final info = labDisplayInfo(
      code: measurement.code,
      fallbackName: measurement.name,
    );

    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LabResultTrendScreen(
          repository: widget.repository,
          code: code,
          fallbackName: info.koreanName,
          referenceMin: measurement.referenceMin,
          referenceMax: measurement.referenceMax,
          referenceText: measurement.displayReference,
          chatbotRepository: widget.chatbotRepository,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('\uC804\uCCB4 \uC218\uCE58 \uCD94\uC774'),
        actions: [
          IconButton(
            tooltip: '\uC0C8\uB85C\uACE0\uCE68',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<_OverallTrendItem>>(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _OverallErrorView(onRetry: _reload);
          }

          final items = snapshot.data ?? const <_OverallTrendItem>[];

          if (items.isEmpty) {
            return const Center(
              child: Text(
                '\uD45C\uC2DC\uD560 \uAC80\uC0AC \uC218\uCE58\uAC00 \uC5C6\uC5B4\uC694.',
                style: TextStyle(color: AppColors.mutedText),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDCEBFF), Color(0xFFE9E5FF)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.monitor_heart_outlined,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '\uB0B4 \uAC80\uC0AC \uC218\uCE58 \uBCC0\uD654',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${items.length}\uAC1C \uC9C0\uD45C\uC758 \uCD5C\uADFC \uAC80\uC0AC\uB97C \uD55C\uB208\uC5D0 \uBE44\uAD50\uD574\uBCF4\uC138\uC694.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Row(
                            children: [
                              Icon(
                                Icons.touch_app_outlined,
                                size: 17,
                                color: AppColors.blue,
                              ),
                              SizedBox(width: 5),
                              Text(
                                '\uCE74\uB4DC\uB97C \uB204\uB974\uBA74 \uC0C1\uC138 \uCD94\uC774',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = items[index];

                      return _OverallTrendCard(
                        item: item,
                        onTap: item.trend == null
                            ? null
                            : () => _openTrend(item),
                      );
                    }, childCount: items.length),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          mainAxisExtent: 245,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverallTrendItem {
  const _OverallTrendItem({required this.measurement, this.trend, this.error});

  final LabMeasurement measurement;
  final LabTrend? trend;
  final Object? error;
}

class _OverallTrendCard extends StatelessWidget {
  const _OverallTrendCard({required this.item, required this.onTap});

  final _OverallTrendItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final measurement = item.measurement;
    final info = labDisplayInfo(
      code: measurement.code,
      fallbackName: measurement.name,
    );

    final trend = item.trend;
    final numericPoints =
        trend?.results.where((point) => point.value != null).toList() ??
        const <LabTrendPoint>[];

    final recent = numericPoints.length <= 3
        ? numericPoints
        : numericPoints.sublist(numericPoints.length - 3);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE4E9F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.koreanName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        if (info.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            info.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (recent.isNotEmpty)
                    _MiniFlagBadge(flag: recent.last.normalizedFlag),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: item.error != null
                    ? const Center(
                        child: Text(
                          '\uCD94\uC774\uB97C \uBD88\uB7EC\uC624\uC9C0 \uBABB\uD588\uC5B4\uC694.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText,
                          ),
                        ),
                      )
                    : recent.isEmpty
                    ? const Center(
                        child: Text(
                          '\uD45C\uC2DC\uD560 \uC218\uCE58\uAC00 \uC5C6\uC5B4\uC694.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText,
                          ),
                        ),
                      )
                    : CustomPaint(
                        painter: _MiniBarChartPainter(
                          points: recent,
                          referenceMin: measurement.referenceMin,
                          referenceMax: measurement.referenceMax,
                        ),
                        child: const SizedBox.expand(),
                      ),
              ),
              if (recent.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '\uCD5C\uADFC ${_compactValue(recent.last.value!)}'
                        '${trend?.unit?.trim().isNotEmpty == true ? ' ${trend!.unit!.trim()}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 19,
                      color: AppColors.mutedText,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniFlagBadge extends StatelessWidget {
  const _MiniFlagBadge({required this.flag});

  final String flag;

  @override
  Widget build(BuildContext context) {
    final outside = flag == 'HIGH' || flag == 'LOW';
    final unknown = flag != 'NORMAL' && !outside;

    final label = unknown
        ? '\uBBF8\uD310\uC815'
        : outside
        ? '\uC815\uC0C1 \uBC94\uC704 \uC678'
        : '\uC815\uC0C1 \uBC94\uC704';

    final foreground = unknown
        ? AppColors.mutedText
        : outside
        ? const Color(0xFFB42318)
        : const Color(0xFF067647);

    final background = unknown
        ? const Color(0xFFF1F3F5)
        : outside
        ? const Color(0xFFFFE9E7)
        : const Color(0xFFE9F7EF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

class _MiniBarChartPainter extends CustomPainter {
  const _MiniBarChartPainter({
    required this.points,
    required this.referenceMin,
    required this.referenceMax,
  });

  final List<LabTrendPoint> points;
  final double? referenceMin;
  final double? referenceMax;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    const left = 30.0;
    const right = 8.0;
    const top = 16.0;
    const bottom = 28.0;

    final plotWidth = math.max(1.0, size.width - left - right);
    final plotHeight = math.max(1.0, size.height - top - bottom);

    final values = points.map((point) => point.value!).toList();

    var minValue = values.reduce(math.min);
    var maxValue = values.reduce(math.max);

    if (referenceMin != null) {
      minValue = math.min(minValue, referenceMin!);
    }

    if (referenceMax != null) {
      maxValue = math.max(maxValue, referenceMax!);
    }

    var span = maxValue - minValue;

    if (span == 0) {
      span = maxValue == 0 ? 1 : maxValue.abs() * 0.2;
    }

    final padding = span * 0.2;
    minValue -= padding;
    maxValue += padding;

    double yFor(double value) {
      final ratio = (value - minValue) / (maxValue - minValue);
      return top + plotHeight * (1 - ratio);
    }

    final rangePaint = Paint()
      ..color = const Color(0x1834A853)
      ..style = PaintingStyle.fill;

    if (referenceMin != null && referenceMax != null) {
      canvas.drawRect(
        Rect.fromLTRB(
          left,
          yFor(referenceMax!),
          left + plotWidth,
          yFor(referenceMin!),
        ),
        rangePaint,
      );
    } else if (referenceMax != null) {
      canvas.drawRect(
        Rect.fromLTRB(
          left,
          yFor(referenceMax!),
          left + plotWidth,
          top + plotHeight,
        ),
        rangePaint,
      );
    } else if (referenceMin != null) {
      canvas.drawRect(
        Rect.fromLTRB(left, top, left + plotWidth, yFor(referenceMin!)),
        rangePaint,
      );
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE9EDF2)
      ..strokeWidth = 1;

    for (var i = 0; i <= 2; i++) {
      final y = top + plotHeight * i / 2;

      canvas.drawLine(Offset(left, y), Offset(left + plotWidth, y), gridPaint);
    }

    final slotWidth = plotWidth / points.length;
    final barWidth = math.min(34.0, slotWidth * 0.42);

    final barPaint = Paint()
      ..color = AppColors.blue
      ..style = PaintingStyle.fill;

    for (var i = 0; i < points.length; i++) {
      final x = left + slotWidth * (i + 0.5);
      final y = yFor(points[i].value!);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(x - barWidth / 2, y, x + barWidth / 2, top + plotHeight),
        const Radius.circular(5),
      );

      canvas.drawRRect(rect, barPaint);

      _paintCenteredText(
        canvas,
        _compactValue(points[i].value!),
        x,
        math.max(0, y - 17),
        const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      );

      _paintCenteredText(
        canvas,
        _dateLabel(points[i].measuredAt),
        x,
        top + plotHeight + 8,
        const TextStyle(fontSize: 8, color: AppColors.mutedText),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniBarChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.referenceMin != referenceMin ||
        oldDelegate.referenceMax != referenceMax;
  }
}

class _OverallErrorView extends StatelessWidget {
  const _OverallErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('\uB2E4\uC2DC \uC2DC\uB3C4'),
      ),
    );
  }
}

void _paintCenteredText(
  Canvas canvas,
  String text,
  double centerX,
  double y,
  TextStyle style,
) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();

  painter.paint(canvas, Offset(centerX - painter.width / 2, y));
}

String _dateLabel(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$month.$day';
}

String _compactValue(num value) {
  final doubleValue = value.toDouble();

  if (doubleValue == doubleValue.roundToDouble()) {
    return doubleValue.toStringAsFixed(0);
  }

  return doubleValue
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
