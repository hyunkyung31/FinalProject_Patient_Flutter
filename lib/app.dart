import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/view/startup_screen.dart';
import 'features/onboarding/repository/onboarding_repository.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.onboardingRepository});
  final OnboardingRepository? onboardingRepository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BOMI',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: StartupScreen(repository: onboardingRepository),
  );
}
