import 'package:flutter/material.dart';
import '../../onboarding/repository/onboarding_repository.dart';
import '../../onboarding/view/onboarding_screen.dart';
import '../../auth/view/session_gate.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key, this.repository});
  final OnboardingRepository? repository;

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  late final _repository = widget.repository ?? OnboardingRepository();
  late Future<bool> _completed = _repository.isCompleted();
  bool _finished = false;

  Future<void> _finish() async {
    await _repository.complete();
    if (mounted) setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) => _finished
      ? const SessionGate()
      : FutureBuilder<bool>(
          future: _completed,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Scaffold(
                body: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('앱 설정을 불러오지 못했어요.'),
                        FilledButton(
                          onPressed: () => setState(
                            () => _completed = _repository.isCompleted(),
                          ),
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return snapshot.data!
                ? const SessionGate()
                : OnboardingScreen(onComplete: _finish);
          },
        );
}
