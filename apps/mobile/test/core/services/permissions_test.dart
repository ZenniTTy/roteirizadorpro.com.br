import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/core/services/permissions.dart';

import '../_helpers/fake_app_permissions.dart';

void main() {
  test('Fake records granted outcomes', () async {
    final p = FakeAppPermissions();
    expect(await p.requestLocation(), PermissionOutcome.granted);
    expect(await p.requestMicrophone(), PermissionOutcome.granted);
    expect(await p.requestCamera(), PermissionOutcome.granted);
  });

  test('Fake can simulate permanent deny', () async {
    final p = FakeAppPermissions(
      locationResult: PermissionOutcome.permanentlyDenied,
    );
    expect(await p.requestLocation(), PermissionOutcome.permanentlyDenied);
  });

  test('Fake records per-permission call counts and outcomes', () async {
    final p = FakeAppPermissions(
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
