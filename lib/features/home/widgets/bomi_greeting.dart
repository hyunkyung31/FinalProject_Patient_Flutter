import 'package:flutter/material.dart';

class BomiGreeting extends StatelessWidget {
  const BomiGreeting({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: '손을 흔들며 인사하는 보미',
    image: true,
    child: SizedBox(
      width: 110,
      height: 150,
      child: FittedBox(
        fit: BoxFit.contain,
        // The source has wide transparent margins around the character.
        child: ClipRect(
          child: Align(
            widthFactor: 0.34,
            heightFactor: 0.44,
            child: Image.asset(
              'assets/images/bomi/bomi_13_greeting.png',
              width: 1024,
              height: 1024,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    ),
  );
}
