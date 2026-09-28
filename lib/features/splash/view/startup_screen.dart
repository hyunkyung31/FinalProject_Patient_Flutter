import 'package:flutter/material.dart';
import '../../onboarding/repository/onboarding_repository.dart';
import '../../onboarding/view/onboarding_screen.dart';
import '../widgets/bomi_startup_splash.dart';
import '../../auth/view/session_gate.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key, this.repository});
  final OnboardingRepository? repository;

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  late final _repository = widget.repository ?? OnboardingRepository();
  late Future<bool> _completed = _loadStartup();
  bool _finished = false;

  Future<bool> _loadStartup() async {
    final completed = _repository.isCompleted();
    await Future<void>.delayed(const Duration(milliseconds: 1900));
    return completed;
  }

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
                          onPressed: () =>
                              setState(() => _completed = _loadStartup()),
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const BomiStartupSplash();
            }
            return snapshot.data!
                ? const SessionGate()
                : OnboardingScreen(onComplete: _finish);
          },
        );
}
