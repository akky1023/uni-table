import 'package:flutter/material.dart';
import 'dialogs.dart';
import 'accessibility.dart';
import '../domain/schedule.dart';

TextEditingController text(dynamic value) =>
    TextEditingController(text: value?.toString() ?? '');
Widget field(TextEditingController controller, String label,
        {bool required = false,
        int lines = 1,
        bool number = false,
        String? hint}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
          controller: controller,
          minLines: lines,
          maxLines: lines == 1 ? 1 : null,
          keyboardType: number
              ? TextInputType.number
              : lines > 1
                  ? TextInputType.multiline
                  : TextInputType.text,
          decoration: InputDecoration(labelText: label, hintText: hint),
          validator: (v) {
            if (required && (v == null || v.trim().isEmpty)) return '入力してください';
            if (number &&
                v != null &&
                v.isNotEmpty &&
                (int.tryParse(v) == null ||
                    int.parse(v) < -1 ||
                    int.parse(v) > 2147483647)) {
              return '-1～2147483647の整数を入力してください';
            }
            return null;
          }),
    );

Widget choice<T>(String label, T value, Map<T, String> values,
        void Function(T) changed) =>
    Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<T>(
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(
                labelText: label,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.fromLTRB(14, 20, 14, 14)),
            items: values.entries
                .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) {
              if (v != null) changed(v);
            }));

String dateTimeLabel(DateTime date) =>
    '${dayKey(date)} ${clock(date.hour * 60 + date.minute)}';

Future<DateTime?> pickDate(BuildContext context, DateTime initial,
    {DateTime? firstDate, DateTime? lastDate}) async {
  var selected = dateOnly(initial);
  return showAppDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
              title: const Text('日付を選択'),
              content: SizedBox(
                  width: 340,
                  height: 320,
                  child: CalendarDatePicker(
                      initialDate: selected,
                      firstDate: firstDate ?? DateTime(1900),
                      lastDate: lastDate ?? DateTime(9999),
                      onDateChanged: (value) => selected = value)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('キャンセル')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, selected),
                    child: const Text('決定'))
              ]));
}

Future<TimeOfDay?> pickTime(BuildContext context, TimeOfDay initial,
        {String? helpText}) =>
    showAppDialog<TimeOfDay>(
        context: context,
        builder: (ctx) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
              child: TimePickerDialog(initialTime: initial, helpText: helpText),
            ));

Future<DateTimeRange?> pickRange(
        {required BuildContext context,
        required DateTime firstDate,
        required DateTime lastDate,
        DateTimeRange? initialDateRange,
        bool barrierDismissible = true}) =>
    showAppDialog<DateTimeRange>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (_) => DateRangePickerDialog(
            firstDate: firstDate,
            lastDate: lastDate,
            initialDateRange: initialDateRange));

Widget dateField(
    BuildContext context, TextEditingController controller, String label,
    {bool optional = false, bool time = false, VoidCallback? onChanged}) {
  Future<void> changeDate() async {
    final old = DateTime.tryParse(controller.text) ?? DateTime.now();
    final day = await pickDate(context, old);
    if (day == null) return;
    controller.text = time
        ? dateTimeLabel(
            DateTime(day.year, day.month, day.day, old.hour, old.minute))
        : dayKey(day);
    onChanged?.call();
  }

  Future<void> changeTime() async {
    final old = DateTime.tryParse(controller.text) ?? DateTime.now();
    final selected = await pickTime(context, TimeOfDay.fromDateTime(old));
    if (selected == null) return;
    controller.text = dateTimeLabel(
        DateTime(old.year, old.month, old.day, selected.hour, selected.minute));
    onChanged?.call();
  }

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      readOnly: !time,
      decoration: InputDecoration(
        labelText: label,
        hintText: time ? 'YYYY-MM-DD HH:mm' : null,
        suffixIcon: time
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    tooltip: '日付を選ぶ',
                    onPressed: changeDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18)),
                IconButton(
                    tooltip: '時刻を選ぶ',
                    onPressed: changeTime,
                    icon: const Icon(Icons.schedule, size: 18)),
              ])
            : optional
                ? IconButton(
                    onPressed: () {
                      controller.clear();
                      onChanged?.call();
                    },
                    icon: const Icon(Icons.clear, size: 18))
                : const Icon(Icons.calendar_today_outlined, size: 18),
      ),
      validator: (v) => time
          ? (parseDeadline(v ?? '') == null
              ? 'YYYY-MM-DD HH:mmで入力してください'
              : null)
          : !optional && (v?.isEmpty ?? true)
              ? '日付を選んでください'
              : null,
      onTap: time ? null : changeDate,
      onChanged: (_) => onChanged?.call(),
    ),
  );
}

DateTime? parseDeadline(String raw) {
  final m = RegExp(
          r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::\d{2}(?:\.\d+)?)?$')
      .firstMatch(raw);
  if (m == null) return null;
  final values = List.generate(5, (i) => int.parse(m[i + 1]!));
  final date = DateTime(values[0], values[1], values[2], values[3], values[4]);
  if (date.year != values[0] ||
      date.month != values[1] ||
      date.day != values[2] ||
      date.hour != values[3] ||
      date.minute != values[4]) {
    return null;
  }
  return date;
}

class HistoryField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final List<String> history;
  final bool required;
  const HistoryField(
      {super.key,
      required this.controller,
      required this.label,
      required this.history,
      this.required = false});
  @override
  State<HistoryField> createState() => _HistoryFieldState();
}

class _HistoryFieldState extends State<HistoryField> {
  final focus = FocusNode();
  @override
  void initState() {
    super.initState();
    focus.addListener(update);
    widget.controller.addListener(update);
  }

  void update() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(update);
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.history
        .where((v) =>
            v.toLowerCase().contains(widget.controller.text.toLowerCase()))
        .toList();
    return TextFieldTapRegion(
        child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                      controller: widget.controller,
                      focusNode: focus,
                      decoration: InputDecoration(
                          labelText: widget.label,
                          filled: true,
                          fillColor:
                              Theme.of(context).inputDecorationTheme.fillColor),
                      validator: (v) =>
                          widget.required && (v == null || v.trim().isEmpty)
                              ? '入力してください'
                              : null),
                  if (focus.hasFocus && options.isNotEmpty)
                    SizedBox(
                        height: 48,
                        child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: options.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(width: 6),
                            itemBuilder: (_, index) => Center(
                                child: ActionChip(
                                    chipAnimationStyle: chipMotion(context),
                                    label: Text(options[index]),
                                    onPressed: () {
                                      widget.controller.text = options[index];
                                      focus.unfocus();
                                    }))))
                ])));
  }
}

Future<bool?> editor(
    BuildContext context,
    String title,
    Widget Function(BuildContext, StateSetter) body,
    Future<bool> Function() save,
    {Future<void> Function()? delete,
    bool fullScreen = false,
    bool topAligned = false,
    bool bottomSheet = false,
    Future<void> Function()? onBackSaved}) async {
  final key = GlobalKey<FormState>();
  var busy = false, asking = false;
  String? error;
  Widget build(BuildContext ctx) => StatefulBuilder(builder: (ctx, set) {
        Future<void> submit({bool fromBack = false}) async {
          if (busy || !key.currentState!.validate()) return;
          set(() {
            busy = true;
            error = null;
          });
          try {
            if (await save() && ctx.mounted) {
              if (fromBack) await onBackSaved?.call();
              if (ctx.mounted) Navigator.pop(ctx, true);
            } else if (ctx.mounted) {
              set(() => busy = false);
            }
          } catch (e) {
            if (ctx.mounted) {
              set(() {
                busy = false;
                error = e.toString();
              });
            }
          }
        }

        Future<void> back() async {
          if (busy || asking) return;
          asking = true;
          final answer = await showAppDialog<String>(
              context: ctx,
              builder: (c) =>
                  AlertDialog(title: const Text('変更を保存しますか？'), actions: [
                    FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(c).colorScheme.error),
                        onPressed: () => Navigator.pop(c, 'discard'),
                        child: const Text('編集を破棄')),
                    FilledButton(
                        onPressed: () => Navigator.pop(c, 'save'),
                        child: const Text('保存')),
                  ]));
          asking = false;
          if (!ctx.mounted) return;
          if (answer == 'save') {
            await submit(fromBack: true);
          } else if (answer == 'discard') {
            Navigator.pop(ctx, false);
          }
        }

        final content = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
                child: Form(
                    key: key,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          body(ctx, set),
                          if (error != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(error!,
                                    style: TextStyle(
                                        color:
                                            Theme.of(ctx).colorScheme.error)))
                        ]))));
        final actions = <Widget>[
          if (delete != null)
            TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        final approved = await showAppDialog<bool>(
                            context: ctx,
                            builder: (c) => AlertDialog(
                                    title: const Text('削除しますか？'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, false),
                                          child: const Text('戻る')),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, true),
                                          child: const Text('削除')),
                                    ]));
                        if (approved != true || !ctx.mounted) return;
                        set(() {
                          busy = true;
                          error = null;
                        });
                        try {
                          await delete();
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          if (ctx.mounted) {
                            set(() {
                              busy = false;
                              error = e.toString();
                            });
                          }
                        }
                      },
                child: const Text('削除')),
          TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx, false),
              child: const Text('キャンセル')),
          FilledButton(
              onPressed: busy ? null : submit,
              child: Text(busy ? '保存中…' : '保存')),
        ];
        Widget result;
        if (fullScreen) {
          result = Scaffold(
              appBar: AppBar(
                  title: Text(title),
                  leading: IconButton(
                      onPressed: back, icon: const Icon(Icons.arrow_back))),
              body: Align(
                  alignment:
                      topAligned ? Alignment.topCenter : Alignment.center,
                  child: Padding(
                      padding: const EdgeInsets.all(16), child: content)),
              bottomNavigationBar: SafeArea(
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 12,
                          children: actions))));
        } else if (bottomSheet) {
          result = Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, MediaQuery.viewInsetsOf(ctx).bottom + 16),
              child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: (MediaQuery.sizeOf(ctx).height * .88 -
                              MediaQuery.viewInsetsOf(ctx).bottom)
                          .clamp(100, double.infinity)),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 16),
                        Flexible(child: content),
                        const SizedBox(height: 12),
                        Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 12,
                            children: actions),
                      ])));
        } else {
          result = AlertDialog(
              title: Text(title), content: content, actions: actions);
        }
        result = Theme(
            data: Theme.of(ctx).copyWith(
                inputDecorationTheme: Theme.of(ctx)
                    .inputDecorationTheme
                    .copyWith(
                        filled: true,
                        fillColor:
                            Theme.of(context).inputDecorationTheme.fillColor)),
            child: result);
        return PopScope<bool>(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) back();
            },
            child: result);
      });
  final TransitionRoute<bool> route = fullScreen
      ? MaterialPageRoute<bool>(builder: build)
      : bottomSheet
          ? KeyboardBottomSheetRoute<bool>(
              builder: build,
              sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
                  ? AnimationStyle.noAnimation
                  : null)
          : KeyboardDialogRoute<bool>(
              context: context,
              builder: build,
              still: MediaQuery.disableAnimationsOf(context));
  final result = await Navigator.of(context).push(route);
  await route.completed;
  return result;
}

String ruleLabel(DbRow r) {
  switch (r['kind']) {
    case 'hours':
      return '${r['amount']}時間前';
    case 'days':
      return '${r['amount']}日前';
    case 'weeks':
      return '${r['amount']}週間前';
    case 'week_clock':
      return '${r['amount']}週間前の ${clock(r['minute'] as int)}';
    case 'day_clock':
      return '${r['amount']}日前の ${clock(r['minute'] as int)}';
    case 'previous_sunday':
      return '直前の日曜日の ${clock(r['minute'] as int)}';
    case 'previous_holiday':
      return r['minute'] != null
          ? '直前の休日の ${clock(r['minute'] as int)}'
          : '${r['amount']}回前の休日';
    case 'absolute':
      return '指定日時 ${r['at']}';
    default:
      return '不明な通知';
  }
}

Future<DbRow?> addRule(BuildContext context,
    {bool allowAbsolute = true}) async {
  var kind = 'hours';
  final amount = text('72'), time = text('');
  DbRow? result;
  await editor(
      context,
      '通知タイミング',
      (ctx, set) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              field(amount, 'n', number: true, required: true),
              RadioGroup<String>(
                  groupValue: kind,
                  onChanged: (value) => set(() {
                        kind = value!;
                      }),
                  child: Column(children: [
                    for (final entry in {
                      'hours': '時間前',
                      'days': '日前',
                      'weeks': '週間前',
                      'previous_holiday': '回前の休日'
                    }.entries)
                      RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: entry.key,
                          title: Text(entry.value)),
                  ])),
              const Text('の'),
              const SizedBox(height: 8),
              TextFormField(
                controller: time,
                enabled: kind == 'days' || kind == 'weeks',
                decoration: InputDecoration(
                    labelText: 'hh:mm',
                    hintText: '省略すると期限と同じ時刻',
                    suffixIcon: IconButton(
                      tooltip: '通知時刻を選ぶ',
                      onPressed: kind == 'days' || kind == 'weeks'
                          ? () async {
                              final match = RegExp(r'^(\d{1,2}):(\d{2})$')
                                  .firstMatch(time.text);
                              final selected = await pickTime(
                                  ctx,
                                  match == null ||
                                          int.parse(match[1]!) > 23 ||
                                          int.parse(match[2]!) > 59
                                      ? const TimeOfDay(hour: 7, minute: 0)
                                      : TimeOfDay(
                                          hour: int.parse(match[1]!),
                                          minute: int.parse(match[2]!)));
                              if (selected != null) {
                                set(() => time.text = clock(
                                    selected.hour * 60 + selected.minute));
                              }
                            }
                          : null,
                      icon: const Icon(Icons.schedule),
                    )),
              ),
              if (kind == 'previous_holiday')
                const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child:
                        Text('期限の日より前の休日を数え、期限と同じ時刻に通知します。休日に含める日は設定で変更できます。')),
            ],
          ), () async {
    final count = int.parse(amount.text);
    if (count < 0 || kind == 'previous_holiday' && count == 0) {
      throw const FormatException('休日は1以上、それ以外は0以上を指定してください');
    }
    int? minute;
    if ((kind == 'days' || kind == 'weeks') && time.text.isNotEmpty) {
      final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(time.text);
      if (match == null ||
          int.parse(match[1]!) > 23 ||
          int.parse(match[2]!) > 59) {
        throw const FormatException('00:00～23:59で入力してください');
      }
      minute = int.parse(match[1]!) * 60 + int.parse(match[2]!);
    }
    result = {
      'kind': minute == null
          ? kind
          : kind == 'days'
              ? 'day_clock'
              : 'week_clock',
      'amount': count,
      if (minute != null) 'minute': minute
    };
    return true;
  });
  amount.dispose();
  time.dispose();
  return result;
}
