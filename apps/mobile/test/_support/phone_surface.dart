import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Resizes the widget-test surface to a phone-shaped logical viewport.
///
/// Consumers: MS-10 (optimize_route_page_test) and MS-11 (reorder_page_test).
/// The default 800x600 test surface leaves the split-layout sheets clipped
/// and the lasso overlay off-screen; 400x900 (logical px, devicePixelRatio
/// forced to 1.0) approximates a real Android device close to the
/// prototype's 390-wide design canvas.
Future<void> phoneSurface(
  WidgetTester tester, {
  Size size = const Size(400, 900),
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
