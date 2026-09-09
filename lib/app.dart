import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/skin_catalog.dart';
import 'screens/boot_screen.dart';
import 'screens/home_shelf_screen.dart';
import 'screens/roll_list_screen.dart';
import 'state/archive_store.dart';
import 'theme/app_skin_extension.dart';
import 'theme/app_theme.dart';
import 'widgets/device_icons.dart';

class CameraArchiveApp extends StatelessWidget {
  const CameraArchiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ArchiveStore>();
    final equipped = store.equippedCameraId;
    final skin = (equipped != null ? store.ownedById(equipped)?.customization.skinId.skin : null) ??
        CameraSkinId.nightVision.skin;
    return MaterialApp(
      title: 'Camera Archive',
      debugShowCheckedModeBanner: false,
      // A camera-body swap is a hard cut, not a re-lit theme — disable
      // Material's implicit ~200ms cross-fade between ThemeDatas.
      theme: AppTheme.themeFor(skin),
      themeAnimationDuration: Duration.zero,
      home: const _RootGate(),
    );
  }
}

class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool _bootDone = false;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ArchiveStore>();
    if (store.isLoaded && _bootDone) {
      return const RootShell();
    }
    // The boot animation and the real store load run concurrently — real
    // load finishing early never skips the boot sequence's fixed cadence,
    // and if it somehow runs long the READY frame just holds statically
    // (no spinner is ever shown).
    return BootScreen(onDone: () => setState(() => _bootDone = true));
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tab = 0;

  static const _screens = [HomeShelfScreen(), RollListScreen()];

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: skin.graphite)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: [
            NavigationDestination(
              icon: DeviceIcon(DeviceGlyph.cameraBody, color: skin.mutedText),
              selectedIcon: DeviceIcon(DeviceGlyph.cameraBody, color: skin.amber),
              label: 'Cameras',
            ),
            NavigationDestination(
              icon: DeviceIcon(DeviceGlyph.filmRoll, color: skin.mutedText),
              selectedIcon: DeviceIcon(DeviceGlyph.filmRoll, color: skin.amber),
              label: 'Rolls',
            ),
          ],
        ),
      ),
    );
  }
}
