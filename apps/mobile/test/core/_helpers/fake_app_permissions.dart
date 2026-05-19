import 'package:roteirizador_pro/core/services/permissions.dart';

class FakeAppPermissions implements AppPermissions {
  FakeAppPermissions({
    this.locationResult = PermissionOutcome.granted,
    this.micResult = PermissionOutcome.granted,
    this.cameraResult = PermissionOutcome.granted,
  });

  PermissionOutcome locationResult;
  PermissionOutcome micResult;
  PermissionOutcome cameraResult;

  int locationCalls = 0;
  int micCalls = 0;
  int cameraCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<PermissionOutcome> requestLocation() async {
    locationCalls++;
    return locationResult;
  }

  @override
  Future<PermissionOutcome> requestMicrophone() async {
    micCalls++;
    return micResult;
  }

  @override
  Future<PermissionOutcome> requestCamera() async {
    cameraCalls++;
    return cameraResult;
  }

  @override
  Future<void> openSettings() async {
    openSettingsCalls++;
  }
}
