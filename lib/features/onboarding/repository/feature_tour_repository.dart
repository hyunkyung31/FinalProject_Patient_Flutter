import 'package:shared_preferences/shared_preferences.dart';

class FeatureTourRepository {
  static const completedKey = 'feature_tour_completed_v1';

  Future<bool> isCompleted() async =>
      await SharedPreferencesAsync().getBool(completedKey) ?? false;

  Future<void> complete() =>
      SharedPreferencesAsync().setBool(completedKey, true);
}
