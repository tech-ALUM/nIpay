import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';

class TagManagerScreen extends ConsumerStatefulWidget {
  const TagManagerScreen({super.key});

  @override
  ConsumerState<TagManagerScreen> createState() => _TagManagerScreenState();
}

class _TagManagerScreenState extends ConsumerState<TagManagerScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    await ref.read(tagRepositoryProvider).create(name);
    _controller.clear();
    ref.invalidate(tagsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tags = ref.watch(tagsProvider).valueOrNull ?? const <Tag>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageTags)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: l10n.newTag,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(onPressed: _add, icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: tags.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noItems,
                        style: TextStyle(color: context.nipay.muted),
                      ),
                    )
                  : ListView(
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final t in tags)
                              Chip(
                                label: Text(
                                  '#${t.name}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onDeleted: () async {
                                  await ref
                                      .read(tagRepositoryProvider)
                                      .softDelete(t.id);
                                  ref.invalidate(tagsProvider);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
