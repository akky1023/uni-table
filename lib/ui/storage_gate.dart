import 'package:flutter/material.dart';
import '../data/database.dart';
import '../l10n/strings.dart';
import 'home.dart';

class StorageGate extends StatefulWidget {
  final Storage storage;
  final Object? error;
  const StorageGate({super.key, required this.storage, this.error});
  @override
  State<StorageGate> createState() => _StorageGateState();
}

class _StorageGateState extends State<StorageGate> {
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    error = widget.error?.toString();
  }

  Future<void> choose(bool create) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.storage.selectDatabase(create: create);
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => widget.storage.hasDatabase
      ? Home(storage: widget.storage)
      : Scaffold(
          body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                      strings.appName,
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 16),
                    Text(strings.chooseDatabase),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                                onPressed: busy ? null : () => choose(false),
                                icon: const Icon(Icons.file_open_outlined),
                                label: Text(strings.openUnitable)),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                                onPressed: busy ? null : () => choose(true),
                                icon: const Icon(Icons.add),
                                label: Text(strings.createDatabase)),
                            if (busy) const LinearProgressIndicator(),
                            if (error != null)
                              Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(error!,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error))),
                          ])))));
}
