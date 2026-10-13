import 'package:flutter/material.dart';

class SelectionCheck extends StatelessWidget {
  final Widget label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  const SelectionCheck(
      {super.key,
      required this.label,
      required this.selected,
      required this.onSelected});
  @override
  Widget build(BuildContext context) => CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: label,
      value: selected,
      onChanged: (v) => onSelected(v ?? false));
}
