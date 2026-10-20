import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide ContextAction;
import 'package:flutter/rendering.dart';
import '../domain/schedule.dart';
import '../l10n/strings.dart';
import 'app_palette.dart';
import 'appearance.dart';
import 'calendar_style.dart';
import 'context_actions.dart';

const holidayRed = Color(0xffd45459);
bool isNationalHoliday(DbRow event) =>
    (event['id'] as String).startsWith('jp-holiday-');

class AnnualCalendar extends StatefulWidget {
  final DateTime start;
  final GlobalKey? todayKey;
  final SchoolData data;
  final ScrollController scrollController;
  final int weekStart;
  final bool editing, desktop, selecting;
  final int longPressMilliseconds;
  final ValueChanged<DateTimeRange> onSelected;
  final ValueChanged<DateTime> onDaySettings, onPeriodEdit;
  final List<ContextAction> Function(DateTime) dateActions;
  const AnnualCalendar(
      {super.key,
      required this.start,
      this.todayKey,
      required this.data,
      required this.scrollController,
      required this.onSelected,
      required this.onDaySettings,
      required this.onPeriodEdit,
      required this.dateActions,
      required this.editing,
      this.selecting = false,
      this.longPressMilliseconds = 500,
      required this.desktop,
      required this.weekStart});
  @override
  State<AnnualCalendar> createState() => _AnnualCalendarState();
}

class _AnnualCalendarState extends State<AnnualCalendar> {
  final keys = <String, GlobalKey>{};
  DateTime? anchor, end;
  Offset? pointer;
  Timer? scrolling;
  bool holding = false, showPast = false;
  ScheduleEngine get engine => ScheduleEngine(widget.data);
  DateTime? hitDate(Offset position) {
    for (final entry in keys.entries) {
      final box = entry.value.currentContext?.findRenderObject();
      if (box is RenderBox &&
          box.attached &&
          (box.localToGlobal(Offset.zero) & box.size).contains(position)) {
        return DateTime.parse(entry.key);
      }
    }
    return null;
  }

  void begin(Offset position) {
    final date = hitDate(position);
    setState(() {
      anchor = date;
      end = date;
      pointer = position;
    });
  }

  void move(Offset position) {
    pointer = position;
    final date = hitDate(position);
    if (anchor != null && date != null) setState(() => end = date);
  }

  void autoScroll() {
    final controller = widget.scrollController;
    if (pointer == null || !controller.hasClients) return;
    final viewport = context.findAncestorRenderObjectOfType<RenderViewport>();
    if (viewport == null) return;
    final rect = viewport.localToGlobal(Offset.zero) & viewport.size;
    final delta = pointer!.dy < rect.top + 45
        ? -14.0
        : pointer!.dy > rect.bottom - 45
            ? 14.0
            : 0.0;
    if (delta == 0) return;
    controller.jumpTo((controller.offset + delta)
        .clamp(0.0, controller.position.maxScrollExtent));
    move(pointer!);
  }

  void clear() {
    holding = false;
    scrolling?.cancel();
    scrolling = null;
    setState(() {
      anchor = null;
      end = null;
      pointer = null;
    });
  }

  void finish({bool editSingle = false}) {
    final a = anchor, b = end;
    clear();
    if (a != null && b != null && a != b) {
      widget.onSelected(DateTimeRange(
          start: a.isBefore(b) ? a : b, end: a.isBefore(b) ? b : a));
    } else if (editSingle && a != null) {
      widget.onPeriodEdit(a);
    }
  }

  @override
  void didUpdateWidget(AnnualCalendar old) {
    super.didUpdateWidget(old);
    if (old.start != widget.start) showPast = false;
    if (old.editing != widget.editing ||
        old.start != widget.start ||
        old.selecting != widget.selecting) {
      scrolling?.cancel();
      scrolling = null;
      anchor = null;
      end = null;
      pointer = null;
    }
  }

  @override
  void dispose() {
    scrolling?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offset = (widget.start.weekday - widget.weekStart + 7) % 7;
    final last = DateTime(widget.start.year + 1, widget.start.month, 0);
    final count = (last.difference(widget.start).inDays + 1 + offset + 6) ~/ 7;
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month);
    final hiddenRows =
        ((monthStart.difference(widget.start).inDays + offset) ~/ 7)
            .clamp(0, count);
    final firstRow = widget.editing || showPast ? 0 : hiddenRows;
    final calendar = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: widget.editing && widget.desktop && !widget.selecting
            ? (d) => begin(d.globalPosition)
            : null,
        onPanStart: widget.editing && widget.desktop && !widget.selecting
            ? (d) {
                move(d.globalPosition);
                if (anchor != null) {
                  scrolling = Timer.periodic(
                      const Duration(milliseconds: 50), (_) => autoScroll());
                }
              }
            : null,
        onPanUpdate: widget.editing && widget.desktop && !widget.selecting
            ? (d) {
                if (anchor == null && widget.scrollController.hasClients) {
                  final c = widget.scrollController;
                  c.jumpTo((c.offset - d.delta.dy)
                      .clamp(0.0, c.position.maxScrollExtent));
                } else {
                  move(d.globalPosition);
                }
              }
            : null,
        onPanEnd: widget.editing && widget.desktop && !widget.selecting
            ? (_) => finish()
            : null,
        onPanCancel: widget.editing && widget.desktop && !widget.selecting
            ? clear
            : null,
        child: Column(children: [
          if (!widget.editing && hiddenRows > 0)
            SizedBox(
                height: 48,
                child: TextButton(
                    onPressed: () {
                      setState(() => showPast = !showPast);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && widget.scrollController.hasClients) {
                          widget.scrollController.jumpTo(0);
                        }
                      });
                    },
                    child: Text(showPast ? strings.hidePast : strings.showPast))),
          Row(children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                  child: Center(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(weekdays[(widget.weekStart - 1 + i) % 7],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)))))
          ]),
          for (var row = firstRow; row < count; row++)
            Row(children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                    child: cell(
                        shiftDay(widget.start, row * 7 + col - offset), last),
                  ),
              ]),
        ],
      ),
    );
    if (!widget.editing || widget.desktop) return calendar;
    return LayoutBuilder(
        builder: (context, size) => RawGestureDetector(
            key: ValueKey(widget.longPressMilliseconds),
            gestures: {
              CalendarLongPress:
                  GestureRecognizerFactoryWithHandlers<CalendarLongPress>(
                      () => CalendarLongPress(
                          Duration(milliseconds: widget.longPressMilliseconds)),
                      (recognizer) {
                recognizer.halfCellWidth = size.maxWidth / 14 - 2;
                recognizer.onLongPressStart = (d) {
                  holding = true;
                  begin(d.globalPosition);
                };
                recognizer.onLongPressMoveUpdate = (d) {
                  move(d.globalPosition);
                  scrolling ??= Timer.periodic(
                      const Duration(milliseconds: 50), (_) => autoScroll());
                };
                recognizer.onLongPressEnd = (_) => finish(editSingle: true);
                recognizer.onLongPressCancel = () {
                  if (holding) clear();
                };
              }),
            },
            child: calendar));
  }

  Widget cell(DateTime date, DateTime last) {
    if (date.isBefore(widget.start) || date.isAfter(last)) {
      return const SizedBox(height: 54);
    }
    final id = dayKey(date);
    final selected = anchor != null &&
        end != null &&
        !date.isBefore(anchor!.isBefore(end!) ? anchor! : end!) &&
        !date.isAfter(anchor!.isBefore(end!) ? end! : anchor!);
    final paint = calendarPaint(widget.data, date,
        editing: widget.editing, dark: isDark(context));
    final darkBackground = paint.colors
                .map((c) => Color.alphaBlend(
                        c, Theme.of(context).scaffoldBackgroundColor)
                    .computeLuminance())
                .reduce((a, b) => a + b) /
            paint.colors.length <
        .2;
    final cellText = paint.textColor == const Color(0xffb93642)
        ? appColor(context, widget.data, 'holiday_text')
        : paint.textColor == const Color(0xffa0a0a0)
            ? mutedText(context,
                stronger: widget.data.setting('dark_text', '0') == '1')
            : darkBackground
                ? (Theme.of(context).colorScheme.onSurface.computeLuminance() >
                        .5
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.white)
                : (Theme.of(context).colorScheme.onSurface.computeLuminance() <
                        .5
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.black);
    final primary = Theme.of(context).colorScheme.primary;
    final marks = calendarMarks(widget.data, date,
        editing: widget.editing, color: darkBackground ? Colors.white : null);
    final markSpace = marks.isEmpty
        ? 0.0
        : widget.editing
            ? (((marks.length + 2) ~/ 3) * 9.0).clamp(0.0, 30.0)
            : 14.0;
    final colors = [
      for (final rawColor in paint.colors)
        ...[
          paint.rule == 'empty'
              ? Theme.of(context).scaffoldBackgroundColor
              : rawColor
        ].map((color) => selected
            ? Color.alphaBlend(primary.withValues(alpha: .18), color)
            : color)
    ];
    final text =
        '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    return KeyedSubtree(
        key: ValueKey('calendar-$id'),
        child: ContextActions(
            desktop: widget.desktop,
            actions: widget.desktop ? widget.dateActions(date) : [],
            child: GestureDetector(
                onTap: () {
                  if (widget.selecting) {
                    if (anchor == null) {
                      setState(() {
                        anchor = date;
                        end = date;
                      });
                    } else {
                      final first = anchor!;
                      clear();
                      widget.onSelected(DateTimeRange(
                          start: first.isBefore(date) ? first : date,
                          end: first.isBefore(date) ? date : first));
                    }
                  } else {
                    widget.onDaySettings(date);
                  }
                },
                onDoubleTap: widget.desktop && widget.editing
                    ? () => widget.onPeriodEdit(date)
                    : null,
                child: Container(
                    key: keys.putIfAbsent(
                        id,
                        () => id == dayKey(DateTime.now()) &&
                                widget.todayKey != null
                            ? widget.todayKey!
                            : GlobalKey()),
                    height: 54,
                    margin: const EdgeInsets.all(2),
                    child: CalendarCellSurface(
                        colors: colors,
                        child: Stack(children: [
                          Positioned.fill(
                              top: markSpace,
                              child: Center(
                                  child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(text,
                                          maxLines: 1,
                                          softWrap: false,
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: cellText,
                                              decoration:
                                                  id == dayKey(DateTime.now())
                                                      ? TextDecoration.underline
                                                      : null,
                                              fontWeight: selected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal))))),
                          Positioned(
                              top: 2,
                              right: 2,
                              child: SizedBox(
                                  width: 28,
                                  child: Wrap(
                                      alignment: WrapAlignment.end,
                                      spacing: 1,
                                      runSpacing: 1,
                                      children: marks))),
                        ]))))));
  }
}

/// Before activation, leaving half a cell rejects this gesture. The enclosing
/// scrollable then keeps the same pointer stream and can continue scrolling.
class CalendarLongPress extends LongPressGestureRecognizer {
  double halfCellWidth = 27;
  Offset? origin;
  bool activated = false;
  CalendarLongPress(Duration duration) : super(duration: duration);
  @override
  double get preAcceptSlopTolerance => double.infinity;
  @override
  void addAllowedPointer(PointerDownEvent event) {
    origin = event.position;
    activated = false;
    super.addAllowedPointer(event);
  }

  @override
  void didExceedDeadline() {
    activated = true;
    super.didExceedDeadline();
  }

  @override
  void handleEvent(PointerEvent event) {
    if (!activated && event is PointerMoveEvent && origin != null) {
      final delta = event.position - origin!;
      if (delta.dx.abs() >= halfCellWidth || delta.dy.abs() >= 27) {
        resolve(GestureDisposition.rejected);
      }
    }
    super.handleEvent(event);
  }
}
