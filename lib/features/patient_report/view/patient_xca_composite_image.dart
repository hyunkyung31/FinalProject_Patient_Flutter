import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../repository/patient_report_repository.dart';

class PatientXcaCompositeImage extends StatefulWidget {
  const PatientXcaCompositeImage({
    super.key,
    required this.repository,
    required this.originalPath,
    this.overlayPath,
  });

  final PatientReportRepository repository;
  final String originalPath;
  final String? overlayPath;

  @override
  State<PatientXcaCompositeImage> createState() =>
      _PatientXcaCompositeImageState();
}

class _PatientXcaCompositeImageState extends State<PatientXcaCompositeImage> {
  late Future<_DecodedXcaImages> _future;
  _DecodedXcaImages? _loaded;
  bool _showMask = true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant PatientXcaCompositeImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.originalPath != widget.originalPath ||
        oldWidget.overlayPath != widget.overlayPath) {
      _loaded?.dispose();
      _loaded = null;
      _future = _load();
    }
  }

  Future<_DecodedXcaImages> _load() async {
    final originalBytes = await widget.repository.getProtectedImage(
      widget.originalPath,
    );

    final original = await _decodeImage(originalBytes);

    ui.Image? mask;
    final maskPath = widget.overlayPath?.trim();

    if (maskPath != null && maskPath.isNotEmpty) {
      try {
        final maskBytes = await widget.repository.getProtectedImage(maskPath);
        mask = await _decodeImage(maskBytes);
      } catch (_) {
        // 마스크 로딩에 실패해도 원본은 계속 표시합니다.
      }
    }

    final decoded = _DecodedXcaImages(original: original, mask: mask);

    _loaded = decoded;
    return decoded;
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);

    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  @override
  void dispose() {
    _loaded?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DecodedXcaImages>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AspectRatio(
            aspectRatio: 1,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const AspectRatio(
            aspectRatio: 1,
            child: Center(child: Text('이미지를 불러오지 못했습니다.')),
          );
        }

        final images = snapshot.data!;
        final hasMask = images.mask != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasMask)
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '협착 의심 위치 표시',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showMask = !_showMask;
                      });
                    },
                    icon: Icon(
                      _showMask
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                    label: Text(_showMask ? '위치 표시 숨기기' : '위치 표시 보기'),
                  ),
                ],
              )
            else
              const Text(
                '원본 영상',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: AspectRatio(
                  aspectRatio: images.original.width / images.original.height,
                  child: CustomPaint(
                    painter: _XcaCompositePainter(
                      original: images.original,
                      mask: images.mask,
                      showMask: _showMask,
                    ),
                  ),
                ),
              ),
            ),
            if (hasMask) ...[
              const SizedBox(height: 7),
              Text(
                '강조된 영역은 의료진에게 공개된 분석 위치를 원본 영상 위에 표시한 것입니다.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DecodedXcaImages {
  const _DecodedXcaImages({required this.original, this.mask});

  final ui.Image original;
  final ui.Image? mask;

  void dispose() {
    original.dispose();
    mask?.dispose();
  }
}

class _XcaCompositePainter extends CustomPainter {
  const _XcaCompositePainter({
    required this.original,
    required this.mask,
    required this.showMask,
  });

  final ui.Image original;
  final ui.Image? mask;
  final bool showMask;

  @override
  void paint(Canvas canvas, Size size) {
    final destination = Offset.zero & size;

    canvas.drawImageRect(
      original,
      Rect.fromLTWH(
        0,
        0,
        original.width.toDouble(),
        original.height.toDouble(),
      ),
      destination,
      Paint()..filterQuality = FilterQuality.high,
    );

    final overlay = mask;

    if (!showMask || overlay == null) {
      return;
    }

    // Mask 원본이 검정 배경 + 흰 영역이므로
    // 검정은 원본에 영향을 주지 않고 흰 영역만 붉게 강조합니다.
    final maskPaint = Paint()
      ..filterQuality = FilterQuality.high
      ..blendMode = BlendMode.screen
      ..colorFilter = const ColorFilter.mode(
        Color.fromRGBO(255, 82, 82, 0.60),
        BlendMode.modulate,
      );

    canvas.drawImageRect(
      overlay,
      Rect.fromLTWH(0, 0, overlay.width.toDouble(), overlay.height.toDouble()),
      destination,
      maskPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _XcaCompositePainter oldDelegate) {
    return oldDelegate.original != original ||
        oldDelegate.mask != mask ||
        oldDelegate.showMask != showMask;
  }
}
