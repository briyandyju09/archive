import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_skin_extension.dart';

/// The standard "machined into the body" panel surface for FIELD UNIT 04 —
/// a hairline border plus a one-pixel bezel highlight/shadow, never a
/// blurred boxShadow. Stands in for every Material `Card`/elevated surface
/// in the redesign. [raised] uses the control-face fill (one step lighter)
/// for a panel that itself sits on top of another panel.
class DevicePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool raised;
  final Color? borderColor;

  const DevicePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.md),
    this.raised = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: context.skin.panelDecoration(raised: raised, borderColor: borderColor),
      padding: padding,
      child: child,
    );
  }
}
