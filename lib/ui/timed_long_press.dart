import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class TimedLongPress extends StatelessWidget {
  final Widget child;
  final int milliseconds;
  final VoidCallback onLongPress;
  final GestureLongPressStartCallback? onLongPressStart;
  const TimedLongPress(
      {super.key,
      required this.child,
      required this.milliseconds,
      required this.onLongPress,
      this.onLongPressStart});
  @override
  Widget build(BuildContext context) => RawGestureDetector(
      key: ValueKey(milliseconds),
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(
                    duration: Duration(milliseconds: milliseconds)),
                (recognizer) {
                  recognizer.onLongPress = onLongPress;
                  recognizer.onLongPressStart = onLongPressStart;
                }),
      },
      child: child);
}
