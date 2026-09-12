import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_preferences.dart';
import 'features/splash/view/startup_screen.dart';
import 'features/onboarding/repository/onboarding_repository.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.onboardingRepository});
  final OnboardingRepository? onboardingRepository;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppPreferences.instance,
    builder: (context, _) {
      final settings = AppPreferences.instance;
      final brightness = settings.dark ? Brightness.dark : Brightness.light;
      return MaterialApp(
        title: 'BOMI',
        debugShowCheckedModeBanner: false,
        theme: (settings.dark
                ? ThemeData(useMaterial3: true, brightness: Brightness.dark)
                : AppTheme.light)
            .copyWith(
          brightness: brightness,
          scaffoldBackgroundColor: settings.dark
              ? const Color(0xFF111827)
              : const Color(0xFFF8FAFC),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E3A8A),
            brightness: brightness,
            contrastLevel: settings.highContrast ? 1 : 0,
          ),
        ),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(
                media.textScaler.scale(1) * settings.textScale,
              ),
              disableAnimations:
                  media.disableAnimations || settings.reduceMotion,
            ),
            child: child!,
          );
        },
        home: StartupScreen(repository: onboardingRepository),
      );
    },
  );
}
