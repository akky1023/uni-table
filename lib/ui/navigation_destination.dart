import 'package:flutter/material.dart';

/// Keep wrapped destination labels centered under their icons.
class CenteredNavigationDestination extends StatelessWidget {
  final Widget icon;
  final String label;
  final String? tooltip;

  const CenteredNavigationDestination({
    super.key,
    required this.icon,
    required this.label,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    textAlign: TextAlign.center,
    child: NavigationDestination(icon: icon, label: label, tooltip: tooltip),
  );
}
