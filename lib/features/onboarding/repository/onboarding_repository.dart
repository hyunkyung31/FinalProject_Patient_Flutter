import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepository {
  static const completedKey = 'onboarding_completed_v1';

  Future<bool> isCompleted() async =>
      await SharedPreferencesAsync().getBool(completedKey) ?? false;

  Future<void> complete() =>
      SharedPreferencesAsync().setBool(completedKey, true);
}
