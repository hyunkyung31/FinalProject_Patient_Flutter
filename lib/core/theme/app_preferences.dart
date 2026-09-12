import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences extends ChangeNotifier {
  AppPreferences() {
    ready = _load();
  }
  static final instance = AppPreferences();
  late final Future<void> ready;
  bool dark = false;
  bool highContrast = false;
  bool reduceMotion = false;
  double textScale = 1;
  String? error;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      dark = prefs.getBool('ui.dark') ?? false;
      highContrast = prefs.getBool('ui.high_contrast') ?? false;
      reduceMotion = prefs.getBool('ui.reduce_motion') ?? false;
      textScale = (prefs.getDouble('ui.text_scale') ?? 1).clamp(1.0, 1.5);
    } catch (_) {
      error = '저장된 화면 설정을 불러오지 못했어요.';
    }
    notifyListeners();
  }

  Future<void> save({
    bool? dark,
    bool? highContrast,
    bool? reduceMotion,
    double? textScale,
  }) async {
    await ready;
    final prefs = await SharedPreferences.getInstance();
    bool saved;
    if (dark != null) {
      saved = await prefs.setBool('ui.dark', dark);
      if (!saved) throw StateError('설정을 저장하지 못했어요.');
      this.dark = dark;
    }
    if (highContrast != null) {
      saved = await prefs.setBool('ui.high_contrast', highContrast);
      if (!saved) throw StateError('설정을 저장하지 못했어요.');
      this.highContrast = highContrast;
    }
    if (reduceMotion != null) {
      saved = await prefs.setBool('ui.reduce_motion', reduceMotion);
      if (!saved) throw StateError('설정을 저장하지 못했어요.');
      this.reduceMotion = reduceMotion;
    }
    if (textScale != null) {
      final scale = textScale.clamp(1.0, 1.5);
      saved = await prefs.setDouble('ui.text_scale', scale);
      if (!saved) throw StateError('설정을 저장하지 못했어요.');
      this.textScale = scale;
    }
    error = null;
    notifyListeners();
  }
}
