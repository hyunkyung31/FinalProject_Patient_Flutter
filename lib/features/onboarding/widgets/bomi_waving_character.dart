import 'package:flutter/material.dart';

/// Two independently clipped layers of the original 1024px sprite.
/// The fixed layer keeps the face/body; only the raised arm rotates.
class BomiWavingCharacter extends StatelessWidget {
  const BomiWavingCharacter({super.key, required this.armAngle});
  final double armAngle;

  static const _asset = 'assets/images/bomi/bomi_13_greeting.png';
  static const shoulder = Offset(591, 574);

  Widget _image() => Image.asset(
    _asset,
    width: 1024,
    height: 1024,
    excludeFromSemantics: true,
    fit: BoxFit.fill,
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 1024,
    height: 1024,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          key: const ValueKey('bomi-fixed-body'),
          clipper: const _BodyClipper(),
          child: _image(),
        ),
        Transform.rotate(
          key: const ValueKey('bomi-waving-arm'),
          angle: armAngle,
          origin: shoulder,
          alignment: Alignment.topLeft,
          child: ClipPath(clipper: const _ArmClipper(), child: _image()),
        ),
      ],
    ),
  );
}

// The cut follows the crease between the raised arm and the head. The
// shoulder overlaps the fixed torso slightly to hide the rotating joint.
Path _armOutline({required bool cutBody}) {
  final inset = cutBody ? 5.0 : 0.0;
  return Path()
    ..moveTo(584 + inset, 569 + inset)
    ..quadraticBezierTo(607, 552, 615, 530)
    ..lineTo(625, 482)
    ..lineTo(700, 482)
    ..lineTo(700, 609)
    ..lineTo(609 + inset, 604)
    ..quadraticBezierTo(591 + inset, 593, 584 + inset, 569 + inset)
    ..close();
}

class _BodyClipper extends CustomClipper<Path> {
  const _BodyClipper();
  @override
  Path getClip(Size size) => Path.combine(
    PathOperation.difference,
    Path()..addRect(Offset.zero & size),
    _armOutline(cutBody: true),
  );
  @override
  bool shouldReclip(covariant _BodyClipper oldClipper) => false;
}

class _ArmClipper extends CustomClipper<Path> {
  const _ArmClipper();
  @override
  Path getClip(Size size) => _armOutline(cutBody: false);
  @override
  bool shouldReclip(covariant _ArmClipper oldClipper) => false;
}
