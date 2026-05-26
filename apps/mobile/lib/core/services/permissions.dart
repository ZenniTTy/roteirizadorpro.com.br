import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permissions.g.dart';

enum PermissionOutcome { granted, denied, permanentlyDenied }

abstract class AppPermissions {
  Future<PermissionOutcome> requestLocation();
  Future<PermissionOutcome> requestMicrophone();
  Future<PermissionOutcome> requestCamera();
  Future<void> openSettings();
}

class _RealAppPermissions implements AppPermissions {
  @override
  Future<PermissionOutcome> requestLocation() =>
      _request(Permission.locationWhenInUse);

  @override
  Future<PermissionOutcome> requestMicrophone() =>
      _request(Permission.microphone);

  @override
  Future<PermissionOutcome> requestCamera() => _request(Permission.camera);

  @override
  Future<void> openSettings() => openAppSettings();

  Future<PermissionOutcome> _request(Permission p) async {
    final status = await p.request();
    if (status.isGranted) return PermissionOutcome.granted;
    if (status.isPermanentlyDenied) return PermissionOutcome.permanentlyDenied;
    return PermissionOutcome.denied;
  }
}

@riverpod
AppPermissions appPermissions(Ref ref) => _RealAppPermissions();
