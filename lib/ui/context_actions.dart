import 'package:flutter/material.dart';

class ContextAction {
  final String label;
  final VoidCallback? run;
  const ContextAction(this.label, this.run);
}

Future<void> showActions(
    BuildContext context, Offset position, List<ContextAction> actions) async {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final selected = await showMenu<int>(
      context: context,
      position: RelativeRect.fromRect(
          position & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        for (var i = 0; i < actions.length; i++)
          PopupMenuItem(
              value: i,
              enabled: actions[i].run != null,
              child: Text(actions[i].label))
      ]);
  if (selected != null) actions[selected].run?.call();
}

class ContextActions extends StatelessWidget {
  final Widget child;
  final List<ContextAction> actions;
  final bool desktop;
  const ContextActions(
      {super.key,
      required this.child,
      required this.actions,
      required this.desktop});
  @override
  Widget build(BuildContext context) => actions.isEmpty || !desktop
      ? child
      : GestureDetector(
          behavior: HitTestBehavior.translucent,
          onSecondaryTapUp: desktop
              ? (d) => showActions(context, d.globalPosition, actions)
              : null,
          child: Material(type: MaterialType.transparency, child: child));
}
