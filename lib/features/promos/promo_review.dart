import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/promo_banner.dart';
import '../../core/providers/promos_provider.dart';
import '../../core/services/api_service.dart';
import 'promo_widgets.dart';

class PromoReview extends StatefulWidget {
  final int id;
  final String? initialAction;
  const PromoReview({super.key, required this.id, this.initialAction});
  @override
  State<PromoReview> createState() => _PromoReviewState();
}

class _PromoReviewState extends State<PromoReview> {
  PromoBanner? _promo;
  bool _loading = true, _next = false;
  String? _error, _action;
  final _priority = TextEditingController(), _reason = TextEditingController();
  final _form = GlobalKey<FormState>();
  late int _id;
  @override
  void initState() {
    super.initState();
    _id = widget.id;
    _load();
  }

  @override
  void dispose() {
    _priority.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _promo = null;
    });
    try {
      final p = await context.read<PromosProvider>().api.getPromo(_id);
      if (!mounted) return;
      setState(() {
        _promo = p;
        _priority.text = '${p.priority}';
        _reason.clear();
        _action = switch (p.status) {
          'PENDING' || 'REJECTED' => 'approve',
          _ => p.isActive ? 'disable' : null,
        };
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException ? e.message : 'promosLoadError',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_action == null || !_form.currentState!.validate()) return;
    final provider = context.read<PromosProvider>(),
        l = AppLocalizations.of(context),
        messenger = ScaffoldMessenger.of(context);
    try {
      await provider.moderate(
        _id,
        action: _action!,
        priority: _action == 'approve'
            ? int.parse(_priority.text.trim())
            : null,
        reason: _action == 'reject' ? _reason.text.trim() : null,
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l.promoUpdated)));
      final remaining = provider.items.where(
        (p) => p.status == 'PENDING' && p.id != _id,
      );
      if (_next && remaining.isNotEmpty) {
        _id = remaining.first.id;
        await _load();
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException ? e.message : l.promoActionError,
        );
      }
    }
  }

  void _selectAction(String value) {
    setState(() {
      _action = value;
      _error = null;
    });
    _form.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        scheme = Theme.of(context).colorScheme;
    final busy = context.watch<PromosProvider>().mutating;
    final p = _promo;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final width = MediaQuery.sizeOf(context).width;
    return PopScope(
      canPop: !busy,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: SizedBox(
          width: wide ? (width * 0.85).clamp(800.0, 1100.0) : width,
          height: double.infinity,
          child: Material(
            color: scheme.surface,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.rate_review_outlined,
                            color: scheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.promoReview,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (p != null)
                                Text(
                                  '${p.restaurantName} · #${p.id}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton.outlined(
                          tooltip: l.close,
                          onPressed: busy ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 19),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  if (_loading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (p == null)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error == 'promosLoadError'
                                    ? l.promosLoadError
                                    : _error ?? l.promosLoadError,
                                textAlign: TextAlign.center,
                              ),
                              TextButton(
                                onPressed: _load,
                                child: Text(l.retry),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Form(
                        key: _form,
                        child: LayoutBuilder(
                          builder: (context, box) {
                            final preview = _preview(context, p);
                            final decision = _decision(context, p, busy);
                            if (box.maxWidth >= 850) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 11,
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(24),
                                      child: preview,
                                    ),
                                  ),
                                  VerticalDivider(
                                    width: 1,
                                    color: scheme.outline.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 10,
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(24),
                                      child: decision,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  preview,
                                  const SizedBox(height: 24),
                                  decision,
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  if (p != null && !_loading) ...[
                    Divider(
                      height: 1,
                      color: scheme.outline.withValues(alpha: 0.3),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Text(
                          _error == 'promosLoadError'
                              ? l.promosLoadError
                              : _error!,
                          style: TextStyle(color: scheme.error, fontSize: 12),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => Navigator.pop(context),
                            child: Text(l.close),
                          ),
                          const Spacer(),
                          if (_action != null)
                            FilledButton.icon(
                              onPressed: busy ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: _action == 'approve'
                                    ? scheme.primary
                                    : _action == 'reject'
                                    ? scheme.error
                                    : scheme.onSurface,
                                foregroundColor: _action == 'disable'
                                    ? scheme.surface
                                    : scheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 16,
                                ),
                              ),
                              icon: busy
                                  ? const SizedBox(
                                      width: 17,
                                      height: 17,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(switch (_action) {
                                      'approve' => Icons.check_rounded,
                                      'reject' => Icons.edit_note_rounded,
                                      _ => Icons.visibility_off_outlined,
                                    }, size: 18),
                              label: Text(switch (_action) {
                                'approve' => l.approve,
                                'reject' => l.promoReject,
                                _ => l.promoDisable,
                              }),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _preview(BuildContext context, PromoBanner p) {
    final l = AppLocalizations.of(context),
        scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.promoPreview,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => Dialog(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: IconButton(
                          tooltip: l.close,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                      Flexible(
                        child: InteractiveViewer(
                          child: AspectRatio(
                            aspectRatio: 1.3,
                            child: PromoImage(
                              url: p.imageUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              icon: const Icon(Icons.open_in_full, size: 13),
              label: Text(
                l.promoImageOpen,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        PromoPreview(promo: p, height: 220),
        const SizedBox(height: 24),
        Text(
          l.promoBannerContent,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        SelectableText(
          p.title,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        if (p.description.isNotEmpty) ...[
          const SizedBox(height: 10),
          SelectableText(
            p.description,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 26),
        Text(
          l.promoDetails,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _DetailRow(label: l.restaurant, value: p.restaurantName),
        _DetailRow(
          label: l.promoSubmitted,
          value: promoDate(context, p.createdAt),
        ),
        _DetailRow(
          label: l.promoReviewed,
          value: promoDate(context, p.reviewedAt),
        ),
        _DetailRow(label: l.promoPriority, value: '${p.priority}'),
        _DetailRow(
          label: l.promoRestaurantActive,
          value: '${p.activeRestaurantPromos}',
        ),
      ],
    );
  }

  Widget _decision(BuildContext context, PromoBanner p, bool busy) {
    final l = AppLocalizations.of(context),
        scheme = Theme.of(context).colorScheme,
        q = bannerQueue(p);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.promoVisibility,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        PromoStatusPill(promo: p),
        const SizedBox(height: 12),
        PromoNotice(
          icon: queueIcon(q),
          title: p.status == 'APPROVED' && p.isActive
              ? l.promoLive
              : l.promoHidden,
          body: switch (q) {
            PromoQueue.pending => l.promoPendingHelp,
            PromoQueue.live => l.promoActiveHelp,
            PromoQueue.inactive => l.promoInactiveHelp,
            _ => l.promoRejectedHint,
          },
          color: queueColor(q, context),
        ),
        if (p.rejectionReason?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          PromoNotice(
            icon: Icons.chat_bubble_outline,
            title: l.promoReason,
            body: p.rejectionReason!,
            color: scheme.error,
          ),
        ],
        const SizedBox(height: 26),
        Text(
          l.promoDecision,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (p.status != 'APPROVED')
              ChoiceChip(
                label: Text(l.approve),
                selected: _action == 'approve',
                onSelected: busy ? null : (_) => _selectAction('approve'),
              ),
            if (p.status != 'REJECTED')
              ChoiceChip(
                label: Text(l.promoRejectTitle),
                selected: _action == 'reject',
                onSelected: busy ? null : (_) => _selectAction('reject'),
              ),
            if (p.isActive)
              ChoiceChip(
                label: Text(l.promoDisableTitle),
                selected: _action == 'disable',
                onSelected: busy ? null : (_) => _selectAction('disable'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (_action == 'approve') ...[
          Text(
            l.promoApproveTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            l.promoActivationHelp,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final preset in [0, 10, 100])
                ActionChip(
                  label: Text(
                    '${switch (preset) {
                      0 => l.promoPriorityNormal,
                      10 => l.promoPriorityFeatured,
                      _ => l.promoPriorityTop,
                    }} · $preset',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onPressed: busy
                      ? null
                      : () => setState(() => _priority.text = '$preset'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _priority,
            enabled: !busy,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            decoration: InputDecoration(
              labelText: l.promoPriority,
              helperText: l.promoPriorityHelp,
              helperMaxLines: 4,
            ),
            validator: (v) {
              final n = int.tryParse(v?.trim() ?? '');
              return n == null || n < -2147483648 || n > 2147483647
                  ? l.promoInvalidNumber
                  : null;
            },
          ),
        ],
        if (_action == 'reject') ...[
          Text(
            l.promoRejectTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _reason,
            enabled: !busy,
            maxLength: 2000,
            minLines: 4,
            maxLines: 7,
            decoration: InputDecoration(
              labelText: l.promoReason,
              helperText: l.promoReasonHelp,
              helperMaxLines: 4,
              alignLabelWithHint: true,
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? l.promoReason : null,
          ),
        ],
        if (_action == 'disable')
          PromoNotice(
            icon: Icons.visibility_off_outlined,
            title: l.promoDisableTitle,
            body: l.promoDisableHelp,
            color: scheme.onSurfaceVariant,
          ),
        if (_action != null && p.status == 'PENDING') ...[
          const SizedBox(height: 18),
          CheckboxListTile(
            value: _next,
            onChanged: busy ? null : (v) => setState(() => _next = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(l.promoContinue, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
