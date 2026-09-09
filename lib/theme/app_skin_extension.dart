import 'package:flutter/material.dart';

import '../models/camera_skin.dart';

/// Carries the current [CameraSkin] through the standard Flutter Theme
/// propagation mechanism, so every `Theme.of(context)` dependent (which is
/// what `context.skin` below resolves through) rebuilds automatically
/// whenever the skin changes — no hand-rolled listener plumbing needed.
class AppSkinExtension extends ThemeExtension<AppSkinExtension> {
  final CameraSkin skin;

  const AppSkinExtension(this.skin);

  @override
  AppSkinExtension copyWith({CameraSkin? skin}) => AppSkinExtension(skin ?? this.skin);

  @override
  AppSkinExtension lerp(ThemeExtension<AppSkinExtension>? other, double t) {
    // A camera-body swap is a hard cut, never a cross-fade — see
    // MaterialApp's themeAnimationDuration: Duration.zero in app.dart.
    if (other is! AppSkinExtension) return this;
    return t < 0.5 ? this : other;
  }
}

/// The single access point every screen/widget uses to read the current
/// skin: `context.skin.amber`, `context.skin.uppercaseLabel(...)`, etc.
extension SkinContext on BuildContext {
  CameraSkin get skin => Theme.of(this).extension<AppSkinExtension>()!.skin;
}
