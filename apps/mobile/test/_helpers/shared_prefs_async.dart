import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Backs `SharedPreferencesAsync` with an in-memory store for the current test
/// file, and restores the platform instance afterwards so the static
/// `SharedPreferencesAsyncPlatform.instance` never leaks across test files
/// (a dirty instance from one file would otherwise crash unrelated files with
/// "The SharedPreferencesAsyncPlatform instance must be set").
///
/// Call once inside a test file's `main()` (it registers its own
/// `setUp`/`tearDown`). Needed by any test that touches a provider which reads
/// `activeRouteRepositoryProvider` — i.e. anything calling
/// `ActiveRouteId.setActiveRoute` or mounting `RouteShellPage` without
/// overriding the repo provider.
void useInMemorySharedPreferencesAsync() {
  SharedPreferencesAsyncPlatform? previous;

  setUp(() {
    previous = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = previous;
  });
}
