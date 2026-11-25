import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/admin_gift_card.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class AdminGiftCardsScreen extends StatefulWidget {
  final bool showBackButton;

  const AdminGiftCardsScreen({super.key, this.showBackButton = true});

  @override
  State<AdminGiftCardsScreen> createState() => _AdminGiftCardsScreenState();
}

class _AdminGiftCardsScreenState extends State<AdminGiftCardsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<AdminGiftCard> _cards = const [];
  bool _loading = false;
  String? _error;
  String? _selectedStatus;

  static const _statuses = ['CREATED', 'ACTIVE', 'DEPLETED', 'VOID', 'EXPIRED'];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AdminProvider>().apiService;
      final list = await api.getAdminGiftCards(
        search: _searchController.text,
        status: _selectedStatus,
      );
      if (!mounted) return;
      setState(() => _cards = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    return switch (status) {
      'ACTIVE' => AppColors.success,
      'CREATED' => AppColors.warning,
      'VOID' => AppColors.error,
      'EXPIRED' => AppColors.offline,
      _ => AppColors.info,
    };
  }

  Future<void> _copyCode(String code) async {
    final l = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.giftCardCodeCopied)));
  }

  Future<void> _showIssueDialog() async {
    final issued = await showDialog<AdminGiftCardIssueResult>(
      context: context,
      builder: (_) => const _IssueGiftCardDialog(),
    );

    if (issued == null || !mounted) return;
    final l = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.giftCardIssued),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${issued.balance} ${issued.currency} (${issued.status})'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      issued.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l.copyCode,
                    onPressed: () => _copyCode(issued.code),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.done),
          ),
        ],
      ),
    );
    await _load();
  }

  Future<void> _showCardDetail(AdminGiftCard summary) async {
    final l = AppLocalizations.of(context);
    final api = context.read<AdminProvider>().apiService;
    AdminGiftCard detail;
    try {
      detail = await api.getAdminGiftCardDetail(summary.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.failed('$e')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${l.giftCard} #${detail.id} (${detail.maskedCode})'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 460),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (detail.code != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            detail.code!,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          tooltip: l.copyCode,
                          onPressed: () => _copyCode(detail.code!),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text('${l.status}: ${detail.status}'),
                Text(
                  '${l.balance}: €${detail.balance} / €${detail.initialAmount}',
                ),
                if (detail.purchasedBy != null)
                  Text('${l.purchasedBy}: ${detail.purchasedBy!.name}'),
                if (detail.ownedBy != null)
                  Text('${l.ownedBy}: ${detail.ownedBy!.name}'),
                const SizedBox(height: 14),
                Text(
                  l.ledgerHistory,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                if (detail.history.isEmpty)
                  Text(l.noHistory)
                else
                  ...detail.history.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(entry.label)),
                          Text(
                            '€${entry.amount}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          if (detail.canVoid)
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _confirmVoid(detail);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(l.voidGiftCard),
            ),
          if (detail.canAdjust)
            OutlinedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _showAdjustDialog(detail);
              },
              child: Text(l.adjustBalance),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }

  Future<void> _showAdjustDialog(AdminGiftCard card) async {
    final updated = await showDialog<AdminGiftCardOperationResult>(
      context: context,
      builder: (_) => _AdjustGiftCardDialog(card: card),
    );

    if (updated == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${updated.maskedCode}: €${updated.balance}'),
        backgroundColor: AppColors.success,
      ),
    );
    await _load();
  }

  Future<void> _confirmVoid(AdminGiftCard card) async {
    final l = AppLocalizations.of(context);
    final result = await showDialog<_VoidConfirmationResult>(
      context: context,
      builder: (_) => _VoidGiftCardDialog(card: card),
    );

    if (result == null || !mounted) return;
    try {
      await context.read<AdminProvider>().apiService.voidAdminGiftCard(
        card.id,
        reason: result.reason.isEmpty ? null : result.reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.giftCardVoided),
          backgroundColor: AppColors.success,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.failed('$e')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(l.giftCards),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: l.refresh,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              key: const Key('issue-gift-card-button'),
              onPressed: _showIssueDialog,
              icon: const Icon(Icons.add_card_rounded, size: 18),
              label: Text(l.issue),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 280,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: l.searchGiftCardsHint,
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _load(),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        initialValue: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: l.status,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l.allStatuses),
                          ),
                          ..._statuses.map(
                            (s) => DropdownMenuItem<String?>(
                              value: s,
                              child: Text(s),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedStatus = v);
                          _load();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _loading && _cards.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null && _cards.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _load,
                                child: Text(l.retry),
                              ),
                            ],
                          ),
                        )
                      : _cards.isEmpty
                      ? Center(
                          child: Text(
                            l.noGiftCardsFound,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _cards.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final card = _cards[index];
                            final color = _statusColor(card.status);
                            return InkWell(
                              onTap: () => _showCardDetail(card),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMedium,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.cardTheme.color,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMedium,
                                  ),
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '#${card.id} · ${card.maskedCode}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: color.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  card.status,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: color,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '€${card.balance} / €${card.initialAmount}'
                                            '${card.ownedBy != null ? ' · ${l.ownedBy}: ${card.ownedBy!.name}' : ''}'
                                            '${card.purchasedBy != null ? ' · ${l.purchasedBy}: ${card.purchasedBy!.name}' : ''}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.65),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoidConfirmationResult {
  final String reason;

  const _VoidConfirmationResult(this.reason);
}

class _IssueGiftCardDialog extends StatefulWidget {
  const _IssueGiftCardDialog();

  @override
  State<_IssueGiftCardDialog> createState() => _IssueGiftCardDialogState();
}

class _IssueGiftCardDialogState extends State<_IssueGiftCardDialog> {
  final _amountController = TextEditingController(text: '25.00');
  final _ownedByController = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _amountController.dispose();
    _ownedByController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final parsed = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    if (parsed == null || parsed <= 0) {
      setState(() => _error = l.invalidAmount);
      return;
    }
    final ownerText = _ownedByController.text.trim();
    final ownerId = ownerText.isEmpty ? null : int.tryParse(ownerText);
    if (ownerText.isNotEmpty && ownerId == null) {
      setState(() => _error = l.invalidUserId);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await context
          .read<AdminProvider>()
          .apiService
          .issueAdminGiftCard(
            amount: parsed.toStringAsFixed(2),
            currency: 'EUR',
            ownedBy: ownerId,
          );
      if (!mounted) return;
      Navigator.pop(context, res);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.issueGiftCard),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('issue-gift-card-amount'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: '${l.amount} (EUR)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('issue-gift-card-owner'),
              controller: _ownedByController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '${l.ownerUserId} (${l.optional})',
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('issue-gift-card-submit'),
          onPressed: _busy ? null : _submit,
          child: Text(l.issue),
        ),
      ],
    );
  }
}

class _AdjustGiftCardDialog extends StatefulWidget {
  final AdminGiftCard card;

  const _AdjustGiftCardDialog({required this.card});

  @override
  State<_AdjustGiftCardDialog> createState() => _AdjustGiftCardDialogState();
}

class _AdjustGiftCardDialogState extends State<_AdjustGiftCardDialog> {
  final _deltaController = TextEditingController();
  final _reasonController = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _deltaController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final delta = double.tryParse(
      _deltaController.text.trim().replaceAll(',', '.'),
    );
    final reason = _reasonController.text.trim();
    if (delta == null || delta == 0) {
      setState(() => _error = l.invalidAmount);
      return;
    }
    if (reason.isEmpty) {
      setState(() => _error = l.requiredField);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await context
          .read<AdminProvider>()
          .apiService
          .adjustAdminGiftCard(
            widget.card.id,
            deltaAmount: delta.toStringAsFixed(2),
            reason: reason,
          );
      if (!mounted) return;
      Navigator.pop(context, res);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text('${l.adjustBalance} (${widget.card.maskedCode})'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('adjust-gift-card-delta'),
              controller: _deltaController,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l.deltaAmountHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('adjust-gift-card-reason'),
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: l.reason,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(l.save),
        ),
      ],
    );
  }
}

class _VoidGiftCardDialog extends StatefulWidget {
  final AdminGiftCard card;

  const _VoidGiftCardDialog({required this.card});

  @override
  State<_VoidGiftCardDialog> createState() => _VoidGiftCardDialogState();
}

class _VoidGiftCardDialogState extends State<_VoidGiftCardDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.voidGiftCard),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.voidGiftCardConfirm(widget.card.maskedCode)),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: '${l.reason} (${l.optional})',
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _VoidConfirmationResult(_reasonController.text.trim()),
          ),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: Text(l.voidGiftCard),
        ),
      ],
    );
  }
}
