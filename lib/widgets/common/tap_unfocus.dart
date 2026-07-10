import 'package:flutter/material.dart';

/// Small wrapper that unfocuses any focused input on pointer-down so
/// buttons receive the tap immediately (prevents first-tap being consumed
/// by a TextField losing focus).
class TapUnfocus extends StatelessWidget {
  final Widget child;
  const TapUnfocus({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
