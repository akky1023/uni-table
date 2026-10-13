import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
