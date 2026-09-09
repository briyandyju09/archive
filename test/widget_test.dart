// Smoke test: the app boots to the camera shelf with the starter camera
// already owned, without touching real camera hardware (capture_screen is
// never navigated to here).
import 'dart:io';

import 'package:camera_archive/app.dart';
import 'package:camera_archive/data/app_repository.dart';
import 'package:camera_archive/state/archive_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final Directory dir = Directory.systemTemp.createTempSync('archive_test_');

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

void main() {
  setUp(() {
    PathProviderPlatform.instance = _FakePathProvider();
  });

  testWidgets('boots to the camera shelf with the starter camera', (WidgetTester tester) async {
    // Load the store before pumping so the first frame already has data,
    // rather than racing it against widget build/font-fallback frames.
    // Real dart:io file I/O needs runAsync — testWidgets' fake-async zone
    // never lets a real OS callback resolve otherwise, and it would hang.
    final store = ArchiveStore(AppRepository());
    await tester.runAsync(() => store.load());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: const CameraArchiveApp(),
      ),
    );
    // Fonts are bundled assets now (no google_fonts runtime fetch), so
    // there's no network-retry frame scheduling to work around — the boot
    // sequence's fixed ~1.5s animation is the only thing pumpAndSettle
    // needs to ride out before landing on the camera shelf.
    await tester.pumpAndSettle();

    expect(find.text('My Cameras'), findsOneWidget);
    expect(find.text('Olympus D-360L'), findsOneWidget);
    expect(find.text('Discover Cameras'), findsOneWidget);
  });
}
