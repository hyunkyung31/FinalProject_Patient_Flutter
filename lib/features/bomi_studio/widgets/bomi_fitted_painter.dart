import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 에셋과 JSON을 로드한 뒤 전달하는 스튜디오 착용 보정용 Painter.
/// 이미지 맵의 키는 경로 접두어 없이 PNG 파일명으로 사용합니다.
class BomiFittedPainter extends CustomPainter {
  BomiFittedPainter({
    required this.images,
    required this.manifest,
    this.outfit,
    this.accessory,
    this.background,
    this.leftProp,
    this.rightProp,
    this.decorations = const [],
    this.applyFit = true,
  });

  final Map<String, ui.Image> images;
  final Map<String, dynamic> manifest;
  final String? outfit, accessory, background, leftProp, rightProp;
  final List<String> decorations;
  final bool applyFit;

  Map<String, dynamic> asset(String name) => Map<String, dynamic>.from(
    (manifest['assets'] as List).firstWhere((a) => a['file'] == name) as Map,
  );
  double number(dynamic n) => (n as num).toDouble();
  Rect rect(dynamic v) {
    final a = v as List;
    return Rect.fromLTWH(
      number(a[0]),
      number(a[1]),
      number(a[2]),
      number(a[3]),
    );
  }

  final Paint _paint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high;

  void drawAsset(Canvas canvas, String name, {Rect? target}) {
    final a = asset(name);
    canvas.drawImageRect(
      images[name]!,
      rect(a['source_rect']),
      target ?? rect(a['target_rect']),
      _paint,
    );
  }

  // 매니페스트에 기록된 머리 경로만 읽습니다(M/H/V/L/Q/Z 지원).
  Path headPath() {
    final rendering = manifest['rendering'] as Map;
    final tokens = RegExp(r'[MHVLQZ]|-?\d+(?:\.\d+)?')
        .allMatches(rendering['dressed_base_visible_head_path'] as String)
        .map((m) => m.group(0)!)
        .toList();
    final path = Path();
    var i = 0;
    double x = 0, y = 0;
    double next() => double.parse(tokens[i++]);
    while (i < tokens.length) {
      switch (tokens[i++]) {
        case 'M':
          x = next();
          y = next();
          path.moveTo(x, y);
          break;
        case 'H':
          x = next();
          path.lineTo(x, y);
          break;
        case 'V':
          y = next();
          path.lineTo(x, y);
          break;
        case 'L':
          x = next();
          y = next();
          path.lineTo(x, y);
          break;
        case 'Q':
          final cx = next(), cy = next();
          x = next();
          y = next();
          path.quadraticBezierTo(cx, cy, x, y);
          break;
        case 'Z':
          path.close();
          break;
        default:
          throw const FormatException('Unsupported head path command');
      }
    }
    return path;
  }

  void drawBase(Canvas canvas, Path? visible) {
    canvas.save();
    // 모자 착용 시 분홍 머리 장식이 겹치지 않도록 동일하게 가립니다.
    final capY = accessory == null
        ? null
        : asset(accessory!)['hide_base_above_y'];
    if (capY != null) {
      final y = number(capY);
      canvas.clipRect(Rect.fromLTWH(0, y, 1254, 1254 - y));
    }
    if (visible != null) canvas.clipPath(visible);
    final base = images['bomi_base_default.png']!;
    canvas.drawImageRect(
      base,
      Rect.fromLTWH(0, 0, base.width.toDouble(), base.height.toDouble()),
      const Rect.fromLTWH(0, 0, 1254, 1254),
      _paint,
    );
    canvas.restore();
  }

  void drawCharacter(Canvas canvas) {
    final dressed = outfit != null && applyFit;
    final head = headPath();
    Path? visible;
    if (dressed) {
      visible = Path()..addPath(head, Offset.zero);
      // 어깨·몸통은 옷 뒤에서 숨기고 목·손끝·다리는 유지합니다.
      for (final r
          in (manifest['rendering'] as Map)['dressed_base_visible_rects']
              as List) {
        visible.addRect(rect(r));
      }
    }
    drawBase(canvas, visible);
    if (outfit != null) drawAsset(canvas, outfit!);
    // 머리를 의상 앞에 다시 그려 목선 겹침을 정리합니다.
    if (dressed) drawBase(canvas, head);
    if (accessory != null) drawAsset(canvas, accessory!);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 1254, size.height / 1254);
    canvas.save();
    canvas.translate(
      (size.width - 1254 * scale) / 2,
      (size.height - 1254 * scale) / 2,
    );
    canvas.scale(scale);
    if (background == null) {
      drawCharacter(canvas);
    } else {
      drawAsset(canvas, background!);
      for (final name in decorations) {
        drawAsset(canvas, name);
      }
      canvas.drawOval(
        const Rect.fromLTWH(471, 1040, 312, 40),
        Paint()..color = const Color(0x20785B43),
      );
      final c = rect(manifest['scene_character_rect']);
      canvas.save();
      canvas.translate(c.left, c.top);
      canvas.scale(c.width / 1254, c.height / 1254);
      drawCharacter(canvas);
      canvas.restore();
      void prop(String? name, double slotX) {
        if (name == null) return;
        final r = rect(asset(name)['target_rect']);
        drawAsset(
          canvas,
          name,
          target: Rect.fromLTWH(
            slotX + (300 - r.width) / 2,
            r.top,
            r.width,
            r.height,
          ),
        );
      }

      prop(leftProp, 95);
      prop(rightProp, 890);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BomiFittedPainter oldDelegate) =>
      images != oldDelegate.images ||
      manifest != oldDelegate.manifest ||
      outfit != oldDelegate.outfit ||
      accessory != oldDelegate.accessory ||
      background != oldDelegate.background ||
      leftProp != oldDelegate.leftProp ||
      rightProp != oldDelegate.rightProp ||
      decorations != oldDelegate.decorations ||
      applyFit != oldDelegate.applyFit;
}
