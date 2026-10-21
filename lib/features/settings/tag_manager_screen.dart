import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/ui/ui.dart';
import '../../core/validation.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';

class TagManagerScreen extends ConsumerStatefulWidget {
  const TagManagerScreen({super.key});

  @override
  ConsumerState<TagManagerScreen> createState() => _TagManagerScreenState();
}

class _TagManagerScreenState extends ConsumerState<TagManagerScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.tagNameRequired);
      return;
    }
    final tags = ref.read(tagsProvider).valueOrNull ?? const [];
    if (tags.any((t) => t.name.toLowerCase() == name.toLowerCase())) {
      setState(() => _error = l10n.tagNameDuplicate);
      return;
    }
    final active = ref.read(activeWalletProvider);
    if (active == null) return;
    await ref.read(tagRepositoryProvider).create(name, walletId: active.id);
    _controller.clear();
    ref.invalidate(tagsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tags = ref.watch(tagsProvider).valueOrNull ?? const <Tag>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageTags)),
      body: CenteredListView(
        bottom: 24,
        children: [
          AddItemField(
            controller: _controller,
            label: l10n.newTag,
            error: _error,
            inputFormatters: [LengthLimitingTextInputFormatter(kMaxNameLength)],
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmit: _add,
          ),
          const SizedBox(height: 16),
          if (tags.isEmpty)
            EmptyState(icon: Icons.sell_outlined, message: l10n.noItems)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in tags)
                  InputChip(
                    label: Text('#${t.name}'),
                    deleteButtonTooltipMessage: l10n.delete,
                    onDeleted: () async {
                      final confirmed = await confirmDeletion(
                        context,
                        title: l10n.deleteItemTitle('#${t.name}'),
                      );
                      if (!confirmed) return;
                      await ref.read(tagRepositoryProvider).softDelete(t.id);
                      ref.invalidate(tagsProvider);
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
