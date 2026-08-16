import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';

enum AppPermission { camera, microphone, bluetooth }

class PermissionsResult {
  final Map<AppPermission, PermissionStatus> statuses;
  const PermissionsResult(this.statuses);

  bool get allGranted =>
      statuses.values.every((s) => s.isGranted || s.isLimited);

  List<AppPermission> get denied => statuses.entries
      .where((e) => !(e.value.isGranted || e.value.isLimited))
      .map((e) => e.key)
      .toList(growable: false);

  bool get anyPermanentlyDenied =>
      statuses.values.any((s) => s.isPermanentlyDenied);
}

class PermissionsService {
  Future<PermissionsResult> requestLiveDebatePermissions() async {
    final toRequest = <Permission>[
      Permission.camera,
      Permission.microphone,
    ];

    if (Platform.isAndroid) {
      toRequest.addAll(<Permission>[
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ]);
    } else if (Platform.isIOS) {
      toRequest.add(Permission.bluetooth);
    }

    final raw = await toRequest.request();

    PermissionStatus aggregateBluetooth() {
      if (Platform.isAndroid) {
        final connect = raw[Permission.bluetoothConnect];
        final scan = raw[Permission.bluetoothScan];
        if (connect == null && scan == null) return PermissionStatus.denied;
        final statuses = [connect, scan].whereType<PermissionStatus>().toList();
        if (statuses.any((s) => s.isPermanentlyDenied)) {
          return PermissionStatus.permanentlyDenied;
        }
        if (statuses.every((s) => s.isGranted)) return PermissionStatus.granted;
        return PermissionStatus.denied;
      }
      return raw[Permission.bluetooth] ?? PermissionStatus.denied;
    }

    return PermissionsResult({
      AppPermission.camera:
          raw[Permission.camera] ?? PermissionStatus.denied,
      AppPermission.microphone:
          raw[Permission.microphone] ?? PermissionStatus.denied,
      AppPermission.bluetooth: aggregateBluetooth(),
    });
  }

  /// Push-notification permission, asked once at first launch.
  /// Deliberately NOT part of [requestLiveDebatePermissions]: that result gates
  /// entry to the app, and push is optional. Folding it in would let a user who
  /// declines notifications be bounced to the "permissions required" screen and
  /// blocked from an app that works perfectly well without them.
  /// On Android 13+ (API 33) this shows the runtime prompt; below that it is
  /// granted at install time and returns immediately. Callers ignore the
  /// result — it is informational only.
  Future<PermissionStatus> requestNotifications() =>
      Permission.notification.request();

  Future<bool> openAppSettingsPage() => openAppSettings();
}
