import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/strings.dart';

class KeyboardDialogRoute<T> extends DialogRoute<T> {
  final bool still;
  KeyboardDialogRoute(
      {required super.context,
      required super.builder,
      super.barrierDismissible = true,
      this.still = false});

  @override
  Duration get transitionDuration =>
      still ? Duration.zero : super.transitionDuration;
  @override
  Duration get reverseTransitionDuration =>
      still ? Duration.zero : super.reverseTransitionDuration;

  @override
  Widget buildModalBarrier() => AnimatedModalBarrier(
      color: animation!
          .drive(ColorTween(begin: Colors.transparent, end: barrierColor)),
      dismissible: barrierDismissible,
      onDismiss: () {
        final view = WidgetsBinding.instance.platformDispatcher.views.first;
        if (view.viewInsets.bottom > 0) {
          FocusManager.instance.primaryFocus?.unfocus();
          SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        } else if (barrierDismissible) {
          navigator?.pop();
        }
      });
}

Future<T?> showAppDialog<T>(
        {required BuildContext context,
        required WidgetBuilder builder,
        bool barrierDismissible = true}) =>
    Navigator.of(context, rootNavigator: true).push(KeyboardDialogRoute<T>(
        context: context,
        still: MediaQuery.disableAnimationsOf(context),
        builder: builder,
        barrierDismissible: barrierDismissible));

class KeyboardBottomSheetRoute<T> extends ModalBottomSheetRoute<T> {
  KeyboardBottomSheetRoute({required super.builder, super.sheetAnimationStyle})
      : super(
            isScrollControlled: true,
            useSafeArea: true,
            isDismissible: true,
            enableDrag: false,
            showDragHandle: true);
  @override
  Widget buildModalBarrier() => AnimatedModalBarrier(
      color: animation!
          .drive(ColorTween(begin: Colors.transparent, end: barrierColor)),
      dismissible: true,
      onDismiss: () {
        if (WidgetsBinding
                .instance.platformDispatcher.views.first.viewInsets.bottom >
            0) {
          FocusManager.instance.primaryFocus?.unfocus();
          SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        } else {
          navigator?.pop();
        }
      });
}

Widget dismissibleDialogTitle(BuildContext context, String title) => Row(children: [
  Expanded(child: Text(title)),
  IconButton(tooltip: strings.close, onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.close)),
]);

Future<T?> showAnchoredBubble<T>({required BuildContext context, required Rect anchor,
    required WidgetBuilder builder, double preferredWidth = 280}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push(_AnchoredBubbleRoute<T>(anchor: anchor, builder: builder, preferredWidth: preferredWidth,
      themes: InheritedTheme.capture(from: context, to: navigator.context)));
}

class _AnchoredBubbleRoute<T> extends PopupRoute<T> {
  final Rect anchor;
  final WidgetBuilder builder;
  final CapturedThemes themes;
  final double preferredWidth;
  _AnchoredBubbleRoute({required this.anchor, required this.builder, required this.themes, required this.preferredWidth});
  @override bool get barrierDismissible => true;
  @override Color? get barrierColor => Colors.transparent;
  @override String? get barrierLabel => strings.close;
  @override Duration get transitionDuration => const Duration(milliseconds: 120);
  @override Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) => themes.wrap(Builder(builder: (ctx) {
    final media = MediaQuery.of(ctx);
    final width = math.min(preferredWidth * math.max(1.0, media.textScaler.scale(14) / 14), media.size.width - 24);
    final aboveRoom = math.max(0.0, anchor.top - media.padding.top - 12);
    final belowRoom = math.max(0.0,
        media.size.height - media.padding.bottom - media.viewInsets.bottom - anchor.bottom - 12);
    final above = aboveRoom > belowRoom;
    return CustomSingleChildLayout(
      delegate: _BubbleLayout(anchor, above, media.size.height,
          BoxConstraints(maxWidth: width, maxHeight: math.max(80.0, above ? aboveRoom : belowRoom))),
      child: IntrinsicWidth(
        child: PhysicalShape(key: const ValueKey('anchored-bubble'),
          clipper: _BubbleClipper(above, anchor.center.dx, media.size.width), elevation: 8,
          color: Theme.of(ctx).dialogTheme.backgroundColor ?? Theme.of(ctx).colorScheme.surface,
          child: Material(type: MaterialType.transparency,
            child: Padding(padding: EdgeInsets.fromLTRB(14, above ? 12 : 20, 14, above ? 20 : 12),
              child: SingleChildScrollView(child: builder(ctx)))))));
  }));
}

class _BubbleLayout extends SingleChildLayoutDelegate {
  final Rect anchor;
  final bool above;
  final double screenHeight;
  final BoxConstraints childConstraints;
  _BubbleLayout(this.anchor, this.above, this.screenHeight, this.childConstraints);
  @override BoxConstraints getConstraintsForChild(BoxConstraints constraints) => childConstraints;
  @override Offset getPositionForChild(Size size, Size childSize) => Offset(
      (anchor.center.dx - childSize.width / 2).clamp(12.0, size.width - childSize.width - 12),
      above ? anchor.top - 6 - childSize.height : anchor.bottom + 6);
  @override bool shouldRelayout(_BubbleLayout old) => old.anchor != anchor || old.above != above ||
      old.screenHeight != screenHeight || old.childConstraints != childConstraints;
}

class _BubbleClipper extends CustomClipper<Path> {
  final bool above;
  final double anchorCenter, screenWidth;
  _BubbleClipper(this.above, this.anchorCenter, this.screenWidth);
  @override Path getClip(Size size) {
    final left = (anchorCenter - size.width / 2).clamp(12.0, screenWidth - size.width - 12);
    final tip = (anchorCenter - left).clamp(20.0, size.width - 20);
    final body = Rect.fromLTRB(0, above ? 0 : 8, size.width, size.height - (above ? 8 : 0));
    final edge = above ? size.height - 8 : 8.0;
    return Path()..addRRect(RRect.fromRectAndRadius(body, const Radius.circular(16)))
      ..addPolygon([Offset(tip - 8, edge), Offset(tip, above ? size.height : 0), Offset(tip + 8, edge)], true);
  }
  @override bool shouldReclip(_BubbleClipper old) => old.above != above || old.anchorCenter != anchorCenter || old.screenWidth != screenWidth;
}
