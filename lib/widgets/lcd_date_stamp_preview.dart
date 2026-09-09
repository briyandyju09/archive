import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_skin_extension.dart';

/// Renders a date-stamp string in the same LCD style the pixel pipeline
/// burns into photos, so the customization screen preview matches what
/// shots will actually look like. [color] should be the *edited camera's
/// own* skin's dateStampColor (not necessarily the app's globally-equipped
/// skin) — callers editing a specific camera's customization should pass
/// it explicitly; it falls back to the ambient skin's accent otherwise.
class LcdDateStampPreview extends StatelessWidget {
  final String text;
  final Color? color;

  const LcdDateStampPreview({super.key, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    if (text.isEmpty) {
      return Text('No date stamp', style: skin.prose(fontSize: 13, color: skin.mutedText));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: skin.black,
        borderRadius: BorderRadius.circular(AppRadii.tight),
        border: Border.all(color: skin.graphite),
      ),
      child: Text(text, style: skin.lcd(fontSize: 14, color: color ?? skin.amber)),
    );
  }
}
