import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../chatbot/repository/chatbot_repository.dart';
import '../model/lab_display_info.dart';
import '../model/lab_result.dart';
import '../repository/lab_result_repository.dart';
import 'lab_chatbot_navigation.dart';

class LabResultTrendScreen extends StatefulWidget {
  const LabResultTrendScreen({
    super.key,
    required this.repository,
    required this.code,
    required this.fallbackName,
    this.referenceMin,
    this.referenceMax,
    this.referenceText,
    this.chatbotRepository,
  });

  final LabResultDetailRepository repository;
  final String code;
  final String fallbackName;
  final double? referenceMin;
  final double? referenceMax;
  final String? referenceText;
  final ChatbotRepository? chatbotRepository;

  @override
  State<LabResultTrendScreen> createState() => _LabResultTrendScreenState();
}

class _LabResultTrendScreenState extends State<LabResultTrendScreen> {
  late Future<LabTrend> _trend;

  @override
  void initState() {
    super.initState();
    _trend = widget.repository.getLabTrend(widget.code);
  }

  Future<void> _reload() async {
    final future = widget.repository.getLabTrend(widget.code);

    setState(() {
      _trend = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder에서 오류 상태를 표시합니다.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('검사 수치 추이'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<LabTrend>(
        future: _trend,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _TrendErrorView(error: snapshot.error!, onRetry: _reload);
          }

          final trend = snapshot.data;

          if (trend == null) {
            return _TrendErrorView(
              error: const FormatException('검사 수치 추이 응답이 비어 있습니다.'),
              onRetry: _reload,
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: _TrendContent(
              trend: trend,
              code: widget.code,
              fallbackName: widget.fallbackName,
              referenceMin: widget.referenceMin,
              referenceMax: widget.referenceMax,
              referenceText: widget.referenceText,
              chatbotRepository: widget.chatbotRepository,
            ),
          );
        },
      ),
    );
  }
}

class _TrendContent extends StatelessWidget {
  const _TrendContent({
    required this.trend,
    required this.code,
    required this.fallbackName,
    required this.referenceMin,
    required this.referenceMax,
    required this.referenceText,
    required this.chatbotRepository,
  });

  final LabTrend trend;
  final String code;
  final String fallbackName;
  final double? referenceMin;
  final double? referenceMax;
  final String? referenceText;
  final ChatbotRepository? chatbotRepository;

  Future<void> _askBomi(
    BuildContext context,
    LabDisplayInfo info,
    String unit,
  ) async {
    final chatbot = chatbotRepository;

    if (chatbot == null) {
      return;
    }

    final numericPoints = trend.results
        .where((point) => point.value != null)
        .toList();

    final recent = numericPoints.length <= 3
        ? numericPoints
        : numericPoints.sublist(numericPoints.length - 3);

    String message;

    if (recent.isEmpty) {
      message = '${info.koreanName}(${info.code}) 검사 수치 추이를 쉽게 설명해줘.';
    } else {
      final values = recent
          .map((point) => _compactValue(point.value!))
          .join(' → ');

      final valueText = unit.isEmpty ? values : '$values $unit';

      final range = _referenceLabel(
        referenceMin: referenceMin,
        referenceMax: referenceMax,
        referenceText: referenceText,
        unit: unit,
      );

      final rangeSentence = range == '-' ? '' : ' 정상범위는 $range야.';

      message =
          '${info.koreanName}(${info.code})이 최근 '
          '$valueText로 변했어. '
          '이 변화가 어떤 의미인지 쉽게 설명해줘.'
          '$rangeSentence';
    }

    await openLabChatbot(
      context: context,
      repository: chatbot,
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = labDisplayInfo(code: code, fallbackName: fallbackName);

    final unit = trend.unit?.trim() ?? '';

    final rangeLabel = _referenceLabel(
      referenceMin: referenceMin,
      referenceMax: referenceMax,
      referenceText: referenceText,
      unit: unit,
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.koreanName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      info.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
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

        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '수치 변화',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 17,
                      color: Color(0xFF067647),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '정상 범위 $rangeLabel',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (trend.results.isEmpty)
                  const SizedBox(
                    height: 180,
                    child: Center(
                      child: Text(
                        '표시할 추이 데이터가 없습니다.',
                        style: TextStyle(color: AppColors.mutedText),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 270,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _TrendChartPainter(
                        points: trend.results,
                        referenceMin: referenceMin,
                        referenceMax: referenceMax,
                      ),
                    ),
                  ),

                if (unit.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '단위: $unit',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        if (chatbotRepository != null && trend.results.isNotEmpty) ...[
          const SizedBox(height: 14),
          _TrendBomiCard(onPressed: () => _askBomi(context, info, unit)),
        ],

        const SizedBox(height: 22),

        Row(
          children: [
            const Expanded(
              child: Text(
                '검사 기록',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ),
            Text(
              '${trend.results.length}건',
              style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (trend.results.isEmpty)
          const Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Center(
                child: Text(
                  '검사 기록이 없습니다.',
                  style: TextStyle(color: AppColors.mutedText),
                ),
              ),
            ),
          )
        else
          ...trend.results.reversed.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TrendRecordCard(point: point, unit: unit),
            ),
          ),
      ],
    );
  }
}

class _TrendRecordCard extends StatelessWidget {
  const _TrendRecordCard({required this.point, required this.unit});

  final LabTrendPoint point;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final valueText = _trendValueText(point.value, unit);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dateOnlyText(point.measuredAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    valueText,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            _TrendFlagBadge(flag: point.normalizedFlag),
          ],
        ),
      ),
    );
  }
}

class _TrendBomiCard extends StatelessWidget {
  const _TrendBomiCard({required this.onPressed});

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
            width: 84,
            height: 84,
            child: Image.asset(
              'assets/images/bomi/bomi_lab_trend.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '수치 변화가 궁금하신가요?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '보미가 이전 검사와 비교해 쉽게 설명해드려요.',
                  style: TextStyle(
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
                    label: const Text('보미에게 물어보기', maxLines: 1),
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

class _TrendFlagBadge extends StatelessWidget {
  const _TrendFlagBadge({required this.flag});

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

class _TrendErrorView extends StatelessWidget {
  const _TrendErrorView({required this.error, required this.onRetry});

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

class _TrendChartPainter extends CustomPainter {
  const _TrendChartPainter({
    required this.points,
    required this.referenceMin,
    required this.referenceMax,
  });

  final List<LabTrendPoint> points;
  final double? referenceMin;
  final double? referenceMax;

  @override
  void paint(Canvas canvas, Size size) {
    final numericPoints = points.where((point) => point.value != null).toList();

    if (numericPoints.isEmpty) {
      return;
    }

    const left = 38.0;
    const right = 12.0;
    const top = 30.0;
    const bottom = 48.0;

    final plotWidth = math.max(1.0, size.width - left - right);
    final plotHeight = math.max(1.0, size.height - top - bottom);

    final values = numericPoints.map((point) => point.value!).toList();

    var minValue = values.first;
    var maxValue = values.first;

    for (final value in values.skip(1)) {
      if (value < minValue) {
        minValue = value;
      }
      if (value > maxValue) {
        maxValue = value;
      }
    }

    if (referenceMin != null && referenceMin! < minValue) {
      minValue = referenceMin!;
    }

    if (referenceMax != null && referenceMax! > maxValue) {
      maxValue = referenceMax!;
    }

    var span = maxValue - minValue;

    if (span == 0) {
      span = maxValue == 0 ? 1 : maxValue.abs() * 0.2;
    }

    final padding = span * 0.18;
    minValue -= padding;
    maxValue += padding;

    double yFor(double value) {
      final ratio = (value - minValue) / (maxValue - minValue);
      return top + plotHeight * (1 - ratio);
    }

    double xFor(int index) {
      if (numericPoints.length == 1) {
        return left + plotWidth / 2;
      }

      return left + plotWidth * index / (numericPoints.length - 1);
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE9EDF2)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = top + plotHeight * i / 4;

      canvas.drawLine(Offset(left, y), Offset(left + plotWidth, y), gridPaint);
    }

    final rangePaint = Paint()
      ..color = const Color(0x1834A853)
      ..style = PaintingStyle.fill;

    if (referenceMin != null && referenceMax != null) {
      final upperY = yFor(referenceMax!);
      final lowerY = yFor(referenceMin!);

      canvas.drawRect(
        Rect.fromLTRB(
          left,
          math.min(upperY, lowerY),
          left + plotWidth,
          math.max(upperY, lowerY),
        ),
        rangePaint,
      );
    } else if (referenceMax != null) {
      final upperY = yFor(referenceMax!);

      canvas.drawRect(
        Rect.fromLTRB(left, upperY, left + plotWidth, top + plotHeight),
        rangePaint,
      );
    } else if (referenceMin != null) {
      final lowerY = yFor(referenceMin!);

      canvas.drawRect(
        Rect.fromLTRB(left, top, left + plotWidth, lowerY),
        rangePaint,
      );
    }

    final linePaint = Paint()
      ..color = AppColors.blue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    for (var i = 0; i < numericPoints.length; i++) {
      final point = Offset(xFor(i), yFor(numericPoints[i].value!));

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()
      ..color = AppColors.blue
      ..style = PaintingStyle.fill;

    final valueLabelIndexes = _labelIndexes(numericPoints.length);

    for (var i = 0; i < numericPoints.length; i++) {
      final x = xFor(i);
      final y = yFor(numericPoints[i].value!);

      canvas.drawCircle(Offset(x, y), 4.5, pointPaint);

      if (valueLabelIndexes.contains(i)) {
        _paintCenteredText(
          canvas: canvas,
          text: _compactValue(numericPoints[i].value!),
          centerX: x,
          y: y - 24,
          maxWidth: size.width,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        );
      }
    }

    final dateLabelIndexes = _labelIndexes(numericPoints.length);

    for (final index in dateLabelIndexes) {
      _paintCenteredText(
        canvas: canvas,
        text: _shortDateText(numericPoints[index].measuredAt),
        centerX: xFor(index),
        y: top + plotHeight + 12,
        maxWidth: size.width,
        style: const TextStyle(fontSize: 9, color: AppColors.mutedText),
      );
    }

    _paintText(
      canvas: canvas,
      text: _compactValue(maxValue),
      x: 0,
      y: top - 6,
      style: const TextStyle(fontSize: 9, color: AppColors.mutedText),
    );

    _paintText(
      canvas: canvas,
      text: _compactValue(minValue),
      x: 0,
      y: top + plotHeight - 6,
      style: const TextStyle(fontSize: 9, color: AppColors.mutedText),
    );
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.referenceMin != referenceMin ||
        oldDelegate.referenceMax != referenceMax;
  }
}

Set<int> _labelIndexes(int count) {
  if (count <= 5) {
    return {for (var i = 0; i < count; i++) i};
  }

  return {0, count ~/ 2, count - 1};
}

void _paintCenteredText({
  required Canvas canvas,
  required String text,
  required double centerX,
  required double y,
  required double maxWidth,
  required TextStyle style,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();

  var x = centerX - painter.width / 2;

  if (x < 0) {
    x = 0;
  }

  if (x + painter.width > maxWidth) {
    x = maxWidth - painter.width;
  }

  painter.paint(canvas, Offset(x, y));
}

void _paintText({
  required Canvas canvas,
  required String text,
  required double x,
  required double y,
  required TextStyle style,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();

  painter.paint(canvas, Offset(x, y));
}

ButtonStyle _bomiButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: const Color(0xFFFFE3EA),
    foregroundColor: const Color(0xFFA42652),
    elevation: 0,
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

String _referenceLabel({
  required double? referenceMin,
  required double? referenceMax,
  required String? referenceText,
  required String unit,
}) {
  String range;

  if (referenceMin != null && referenceMax != null) {
    range = '${_compactValue(referenceMin)} ~ ${_compactValue(referenceMax)}';
  } else if (referenceMin != null) {
    range = '${_compactValue(referenceMin)} 이상';
  } else if (referenceMax != null) {
    range = '${_compactValue(referenceMax)} 이하';
  } else {
    final text = referenceText?.trim();
    range = text == null || text.isEmpty ? '-' : text;
  }

  if (unit.isEmpty || range == '-') {
    return range;
  }

  return '$range $unit';
}

String _trendValueText(double? value, String unit) {
  if (value == null) {
    return '수치 없음';
  }

  final text = _compactValue(value);

  if (unit.isEmpty) {
    return text;
  }

  return '$text $unit';
}

String _compactValue(num value) {
  final doubleValue = value.toDouble();

  if (doubleValue == doubleValue.roundToDouble()) {
    return doubleValue.toInt().toString();
  }

  final text = doubleValue.toStringAsFixed(3);

  return text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

String _dateOnlyText(DateTime date) {
  final kst = date.toUtc().add(const Duration(hours: 9));

  String two(int value) => value.toString().padLeft(2, '0');

  return '${kst.year}.${two(kst.month)}.${two(kst.day)}';
}

String _shortDateText(DateTime date) {
  final kst = date.toUtc().add(const Duration(hours: 9));

  String two(int value) => value.toString().padLeft(2, '0');

  return '${two(kst.month)}.${two(kst.day)}';
}
