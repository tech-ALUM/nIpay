import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/ui/ui.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/friends_service.dart';
import '../../l10n/app_localizations.dart';
import '../friends/friends_ui.dart';
import 'chat_ui.dart';

/// Segnala un messaggio ([messageId]) o una persona (M-SOC3, requisito
/// Apple 1.2): motivo, dettagli facoltativi e, come opzione, il blocco.
/// True se la segnalazione è partita.
Future<bool> showReportSheet(
  BuildContext context, {
  required String userId,
  required String? displayName,
  String? messageId,
}) async {
  final sent = await showAppSheet<bool>(
    context,
    builder: (_) => _ReportSheet(
      userId: userId,
      displayName: displayName,
      messageId: messageId,
    ),
  );
  return sent == true;
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({
    required this.userId,
    required this.displayName,
    required this.messageId,
  });

  final String userId;
  final String? displayName;
  final String? messageId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _details = TextEditingController();
  ReportReason? _reason;
  bool _alsoBlock = false;
  bool _sending = false;
  String? _reasonError;
  String? _detailsError;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    final details = _details.text.trim();
    setState(() {
      _reasonError = _reason == null ? l10n.reportChooseReason : null;
      _detailsError = details.length > kMaxReportDetailsLength
          ? l10n.chatErrorInvalidReport
          : null;
    });
    final reason = _reason;
    if (reason == null || _detailsError != null) return;
    setState(() => _sending = true);
    final chat = ref.read(chatServiceProvider);
    try {
      final messageId = widget.messageId;
      if (messageId != null) {
        await chat.reportMessage(
          messageId,
          reason,
          details: details.isEmpty ? null : details,
        );
      } else {
        await chat.reportUser(
          widget.userId,
          reason,
          details: details.isEmpty ? null : details,
        );
      }
      if (_alsoBlock) {
        await ref.read(friendsServiceProvider).block(widget.userId);
        if (mounted) refreshFriends(ref);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ChatException catch (e) {
      _fail(chatErrorText(l10n, e.code));
    } on FriendsException catch (e) {
      // La segnalazione è partita, il blocco no.
      _fail(friendsErrorText(l10n, e.code));
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = personName(l10n, widget.displayName);
    return SheetScaffold(
      title: widget.messageId != null
          ? l10n.reportMessageTitle
          : l10n.reportUserTitle(name),
      actions: [
        FilledButton(
          key: const Key('reportSendButton'),
          onPressed: _sending ? null : _send,
          child: Text(l10n.reportSend),
        ),
      ],
      children: [
        Text(
          l10n.reportReasonLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (_reasonError != null)
          Text(
            _reasonError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        RadioGroup<ReportReason>(
          groupValue: _reason,
          onChanged: (v) => setState(() {
            _reason = v;
            _reasonError = null;
          }),
          child: Column(
            children: [
              for (final r in ReportReason.values)
                RadioListTile<ReportReason>(
                  key: ValueKey('reportReason_${r.name}'),
                  value: r,
                  contentPadding: EdgeInsets.zero,
                  title: Text(reportReasonLabel(l10n, r)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('reportDetailsField'),
          controller: _details,
          minLines: 2,
          maxLines: 5,
          maxLength: kMaxReportDetailsLength,
          decoration: InputDecoration(
            labelText: l10n.reportDetails,
            errorText: _detailsError,
          ),
        ),
        CheckboxListTile(
          key: const Key('reportAlsoBlock'),
          value: _alsoBlock,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(l10n.reportAlsoBlock),
          onChanged: (v) => setState(() => _alsoBlock = v ?? false),
        ),
      ],
    );
  }
}
