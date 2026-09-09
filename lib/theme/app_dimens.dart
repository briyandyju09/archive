/// 2–8px corner-radius scale, replacing the old 10–18px Material rounding.
/// The shutter button is the one deliberate exception (a true circle).
///
/// Lives in its own file (not app_theme.dart) so [CameraSkin] can reference
/// it without an app_theme.dart <-> camera_skin.dart import cycle;
/// app_theme.dart re-exports this file so every existing call site that
/// imports 'theme/app_theme.dart' and reads `AppRadii.*`/`AppSpace.*` keeps
/// compiling unchanged.
class AppRadii {
  AppRadii._();

  static const double none = 0;
  static const double hair = 2;
  static const double tight = 4; // former 999px pills land here
  static const double control = 6; // buttons, chips, choice toggles
  static const double panel = 8; // cards / panels
}

/// 4px-grid spacing scale.
class AppSpace {
  AppSpace._();

  static const double hair = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}
