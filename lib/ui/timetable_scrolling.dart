import 'package:flutter/material.dart';
import '../domain/schedule.dart';

class WeeklyPager extends StatefulWidget {
  final DateTime week;
  final ValueChanged<DateTime> onChanged;
  final Widget Function(DateTime) builder;
  final bool swipeEnabled;
  const WeeklyPager(
      {super.key,
      required this.week,
      required this.onChanged,
      required this.builder,
      this.swipeEnabled = true});
  @override
  State<WeeklyPager> createState() => _WeeklyPagerState();
}

class _WeeklyPagerState extends State<WeeklyPager> {
  static const origin = 10000;
  late final DateTime anchor;
  late final PageController controller;
  late DateTime shown;
  @override
  void initState() {
    super.initState();
    anchor = shown = widget.week;
    controller = PageController(initialPage: origin);
  }

  @override
  void didUpdateWidget(WeeklyPager old) {
    super.didUpdateWidget(old);
    if (widget.week != shown) {
      shown = widget.week;
      final page =
          origin + dateOnly(shown).difference(dateOnly(anchor)).inDays ~/ 7;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && controller.hasClients) controller.jumpToPage(page);
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollEndNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis == Axis.horizontal &&
                shown != widget.week) {
              widget.onChanged(shown);
            }
            return false;
          },
          child: PageView.builder(
            controller: controller,
            physics: widget.swipeEnabled
                ? const PageScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemCount: origin * 2 + 1,
            onPageChanged: (page) {
              shown = shiftDay(anchor, (page - origin) * 7);
            },
            itemBuilder: (_, page) =>
                widget.builder(shiftDay(anchor, (page - origin) * 7)),
          ));
}

class DayStrip extends StatefulWidget {
  final DateTime week;
  final List<int> offsets;
  final double columnWidth;
  final ValueChanged<DateTime> onChanged;
  final Widget Function(DateTime) builder;
  const DayStrip(
      {super.key,
      required this.week,
      required this.offsets,
      required this.columnWidth,
      required this.onChanged,
      required this.builder});
  @override
  State<DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<DayStrip> {
  static const origin = 10000;
  late final DateTime anchor;
  late final ScrollController controller;
  late DateTime shown;
  @override
  void initState() {
    super.initState();
    anchor = shown = widget.week;
    controller = ScrollController(
        initialScrollOffset:
            origin * widget.offsets.length * widget.columnWidth)
      ..addListener(changed);
  }

  void changed() {
    final index =
        (controller.offset / (widget.offsets.length * widget.columnWidth))
            .floor();
    final week = shiftDay(anchor, (index - origin) * 7);
    if (week != shown) {
      shown = week;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && week == shown) widget.onChanged(week);
      });
    }
  }

  @override
  void didUpdateWidget(DayStrip old) {
    super.didUpdateWidget(old);
    if (widget.week != shown) {
      shown = widget.week;
      final index =
          origin + dateOnly(shown).difference(dateOnly(anchor)).inDays ~/ 7;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && controller.hasClients) {
          controller.jumpTo(index * widget.offsets.length * widget.columnWidth);
        }
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        primary: false,
        itemExtent: widget.columnWidth,
        itemCount: (origin * 2 + 1) * widget.offsets.length,
        itemBuilder: (_, index) => widget.builder(shiftDay(
            anchor,
            (index ~/ widget.offsets.length - origin) * 7 +
                widget.offsets[index % widget.offsets.length])),
      );
}
