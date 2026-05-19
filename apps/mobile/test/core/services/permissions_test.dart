import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/core/services/permissions.dart';

class _FakePermissions implements AppPermissions {
  _FakePermissions({
    this.locationResult = PermissionOutcome.granted,
    this.micResult = PermissionOutcome.granted,
    this.cameraResult = PermissionOutcome.granted,
  });

  final PermissionOutcome locationResult;
  final PermissionOutcome micResult;
  final PermissionOutcome cameraResult;

  int locationCalls = 0;
  int micCalls = 0;
  int cameraCalls = 0;

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
  Future<void> openSettings() async {}
}

void main() {
  test('Fake records granted outcomes', () async {
    final p = _FakePermissions();
    expect(await p.requestLocation(), PermissionOutcome.granted);
    expect(await p.requestMicrophone(), PermissionOutcome.granted);
    expect(await p.requestCamera(), PermissionOutcome.granted);
  });

  test('Fake can simulate permanent deny', () async {
    final p = _FakePermissions(
      locationResult: PermissionOutcome.permanentlyDenied,
    );
    expect(await p.requestLocation(), PermissionOutcome.permanentlyDenied);
  });

  test('Fake records per-permission call counts and outcomes', () async {
    final p = _FakePermissions(
      micResult: PermissionOutcome.denied,
      cameraResult: PermissionOutcome.permanentlyDenied,
    );
    expect(await p.requestMicrophone(), PermissionOutcome.denied);
    expect(await p.requestCamera(), PermissionOutcome.permanentlyDenied);
    await p.requestLocation();
    await p.requestLocation();
    expect(p.locationCalls, 2);
    expect(p.micCalls, 1);
    expect(p.cameraCalls, 1);
  });
}
