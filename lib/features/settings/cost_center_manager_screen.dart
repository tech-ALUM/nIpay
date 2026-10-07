import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    inputFormatters: [LengthLimitingTextInputFormatter(kMaxNameLength)],
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    decoration: InputDecoration(
                      labelText: l10n.newCostCenter,
                      errorText: _error,
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
              child: centers.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noItems,
                        style: TextStyle(color: context.nipay.muted),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final c in centers)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.work_outline, size: 18),
                            title: Text(
                              c.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () async {
                                await ref
                                    .read(costCenterRepositoryProvider)
                                    .softDelete(c.id);
                                ref.invalidate(costCentersProvider);
                              },
                            ),
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
