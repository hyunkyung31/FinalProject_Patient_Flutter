import 'dart:io';

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

enum HealthConnectStepsState {
  ready,
  unsupportedPlatform,
  unavailable,
  permissionDenied,
  noData,
  error,
}

class HealthConnectStepsResult {
  const HealthConnectStepsResult({
    required this.state,
    this.steps,
    this.message,
  });

  final HealthConnectStepsState state;
  final int? steps;
  final String? message;

  bool get isReady => state == HealthConnectStepsState.ready;
}

class HealthConnectService {
  HealthConnectService({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) {
      return;
    }

    await _health.configure();
    _configured = true;
  }

  Future<HealthConnectSdkStatus?> getSdkStatus() async {
    if (!Platform.isAndroid) {
      return null;
    }

    await _ensureConfigured();
    return _health.getHealthConnectSdkStatus();
  }

  Future<HealthConnectStepsResult> readTodaySteps({
    bool includeManualEntry = false,
  }) async {
    if (!Platform.isAndroid) {
      return const HealthConnectStepsResult(
        state: HealthConnectStepsState.unsupportedPlatform,
        message: 'Android 기기에서만 Health Connect를 사용할 수 있습니다.',
      );
    }

    try {
      await _ensureConfigured();

      final sdkStatus = await _health.getHealthConnectSdkStatus();

      if (sdkStatus != HealthConnectSdkStatus.sdkAvailable) {
        final message =
            sdkStatus ==
                HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired
            ? 'Health Connect 업데이트가 필요합니다.'
            : '이 기기에서는 Health Connect를 사용할 수 없습니다.';

        return HealthConnectStepsResult(
          state: HealthConnectStepsState.unavailable,
          message: message,
        );
      }

      final activityPermission = await Permission.activityRecognition.request();

      if (!activityPermission.isGranted) {
        return const HealthConnectStepsResult(
          state: HealthConnectStepsState.permissionDenied,
          message: '신체 활동 권한이 필요합니다.',
        );
      }

      const types = <HealthDataType>[HealthDataType.STEPS];

      const permissions = <HealthDataAccess>[HealthDataAccess.READ];

      final hasPermission = await _health.hasPermissions(
        types,
        permissions: permissions,
      );

      final authorized =
          hasPermission == true ||
          await _health.requestAuthorization(types, permissions: permissions);

      if (!authorized) {
        return const HealthConnectStepsResult(
          state: HealthConnectStepsState.permissionDenied,
          message: 'Health Connect 걸음 수 읽기 권한이 필요합니다.',
        );
      }

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final steps = await _health.getTotalStepsInInterval(
        midnight,
        now,
        includeManualEntry: includeManualEntry,
      );

      if (steps == null) {
        return const HealthConnectStepsResult(
          state: HealthConnectStepsState.noData,
          message: '오늘 확인할 수 있는 걸음 기록이 없습니다.',
        );
      }

      return HealthConnectStepsResult(
        state: HealthConnectStepsState.ready,
        steps: steps < 0 ? 0 : steps,
      );
    } catch (error) {
      return HealthConnectStepsResult(
        state: HealthConnectStepsState.error,
        message: error.toString(),
      );
    }
  }
}
