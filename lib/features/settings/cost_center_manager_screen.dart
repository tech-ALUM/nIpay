import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../core/validation.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';

class CostCenterManagerScreen extends ConsumerStatefulWidget {
  const CostCenterManagerScreen({super.key});

  @override
  ConsumerState<CostCenterManagerScreen> createState() =>
      _CostCenterManagerScreenState();
}

class _CostCenterManagerScreenState
    extends ConsumerState<CostCenterManagerScreen> {
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
      setState(() => _error = l10n.costCenterNameRequired);
      return;
    }
    final active = ref.read(activeWalletProvider);
    if (active == null) return;
    await ref
        .read(costCenterRepositoryProvider)
        .create(name, walletId: active.id);
    _controller.clear();
    ref.invalidate(costCentersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final centers =
        ref.watch(costCentersProvider).valueOrNull ?? const <CostCenter>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageCostCenters)),
      body: CenteredListView(
        bottom: 24,
        children: [
          AddItemField(
            controller: _controller,
            label: l10n.newCostCenter,
            error: _error,
            inputFormatters: [LengthLimitingTextInputFormatter(kMaxNameLength)],
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmit: _add,
          ),
          const SizedBox(height: 16),
          if (centers.isEmpty)
            EmptyState(icon: Icons.work_outline, message: l10n.noItems)
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (i, c) in centers.indexed) ...[
                    if (i > 0) const Divider(indent: 68),
                    ListTile(
                      leading: IconBadge(
                        icon: Icons.work_outline,
                        color: context.nipay.muted,
                        size: 36,
                      ),
                      title: Text(c.name),
                      trailing: IconButton(
                        tooltip: l10n.delete,
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () async {
                          final confirmed = await confirmDeletion(
                            context,
                            title: l10n.deleteItemTitle(c.name),
                          );
                          if (!confirmed) return;
                          await ref
                              .read(costCenterRepositoryProvider)
                              .softDelete(c.id);
                          ref.invalidate(costCentersProvider);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
