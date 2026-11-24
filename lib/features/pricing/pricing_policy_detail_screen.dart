import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/pricing_policy.dart';
import '../../core/providers/pricing_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class PricingPolicyDetailScreen extends StatefulWidget {
  final int policyId;

  const PricingPolicyDetailScreen({super.key, required this.policyId});

  @override
  State<PricingPolicyDetailScreen> createState() =>
      _PricingPolicyDetailScreenState();
}

class _PricingPolicyDetailScreenState extends State<PricingPolicyDetailScreen> {
  PricingPolicy? _policy;
  bool _loading = true;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l.pricingPolicyDetails),
        titleSpacing: 0,
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: l.refresh,
          ),
        ],
      ),
      body: _buildBody(theme, l),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l) {
    if (_loading && _policy == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_policy == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 42,
                      color: AppColors.error.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error ?? l.connectionError,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(l.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final policy = _policy!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHero(policy, theme, l),
              const SizedBox(height: 14),
              _buildActions(policy, l),
              const SizedBox(height: 22),
              _buildSection(
                icon: Icons.calculate_outlined,
                title: l.pricingModel,
                child: _valueGrid([
                  _ValueItem(
                    icon: Icons.payments_outlined,
                    label: l.baseAmount,
                    value: '${policy.baseAmount} ${policy.currency}',
                  ),
                  _ValueItem(
                    icon: Icons.straighten_outlined,
                    label: l.baseDistance,
                    value: '${policy.baseDistance} km',
                  ),
                  _ValueItem(
                    icon: Icons.route_outlined,
                    label: l.perKmRate,
                    value: '${policy.perKmRate} ${policy.currency}',
                  ),
                  _ValueItem(
                    icon: Icons.scale_outlined,
                    label: l.weightMultiplier,
                    value: policy.weightMultiplier,
                  ),
                  _ValueItem(
                    icon: Icons.speed_outlined,
                    label: l.averageSpeed,
                    value: policy.averageSpeedKmh == null
                        ? l.notConfigured
                        : '${policy.averageSpeedKmh} km/h',
                  ),
                  _ValueItem(
                    icon: Icons.currency_exchange_rounded,
                    label: l.currency,
                    value: policy.currency,
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              _buildSection(
                icon: Icons.account_balance_wallet_outlined,
                title: l.driverPayout,
                child: _valueGrid([
                  _ValueItem(
                    icon: Icons.payments_outlined,
                    label: l.driverBaseAmount,
                    value: _moneyOrNotConfigured(
                      policy.driverBaseAmount,
                      policy.currency,
                      l,
                    ),
                  ),
                  _ValueItem(
                    icon: Icons.straighten_outlined,
                    label: l.driverBaseDistance,
                    value: policy.driverBaseDistance == null
                        ? l.notConfigured
                        : '${policy.driverBaseDistance} km',
                  ),
                  _ValueItem(
                    icon: Icons.route_outlined,
                    label: l.driverPricePerKm,
                    value: _moneyOrNotConfigured(
                      policy.driverPricePerKm,
                      policy.currency,
                      l,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              _buildSection(
                icon: Icons.schedule_outlined,
                title: l.validity,
                child: _valueGrid([
                  _ValueItem(
                    icon: Icons.play_circle_outline_rounded,
                    label: l.effectiveFrom,
                    value: _formatDateTime(policy.effectiveFrom, l),
                  ),
                  _ValueItem(
                    icon: Icons.stop_circle_outlined,
                    label: l.effectiveTo,
                    value: policy.effectiveTo == null
                        ? l.noEndDate
                        : _formatDateTime(policy.effectiveTo, l),
                  ),
                  _ValueItem(
                    icon: Icons.add_circle_outline_rounded,
                    label: l.createdAt,
                    value: _formatDateTime(policy.createdAt, l),
                  ),
                  _ValueItem(
                    icon: Icons.update_rounded,
                    label: l.updatedAt,
                    value: _formatDateTime(policy.updatedAt, l),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(PricingPolicy policy, ThemeData theme, AppLocalizations l) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.price_change_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        policy.name,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l.pricingPolicyDetails} · #${policy.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.48,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(policy.isActive, l),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _contextChip(
                  Icons.public_outlined,
                  '${_scopeLabel(policy.scope, l)} · ${_locationLabel(policy, l)}',
                  theme,
                ),
                _contextChip(
                  Icons.local_shipping_outlined,
                  '${_orderLabel(policy.orderType, l)} · ${_vehicleLabel(policy.vehicleType, l)}',
                  theme,
                ),
                _contextChip(
                  Icons.layers_outlined,
                  'v${policy.version}',
                  theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(PricingPolicy policy, AppLocalizations l) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: _deleting ? null : () => _edit(policy),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(l.editPricingPolicy),
        ),
        OutlinedButton.icon(
          onPressed: _deleting ? null : () => _delete(policy),
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: Text(l.delete),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.35)),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: theme.dividerColor, height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _valueGrid(List<_ValueItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 620
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map((item) => SizedBox(width: width, child: _valueTile(item)))
              .toList(),
        );
      },
    );
  }

  Widget _valueTile(_ValueItem item) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(
            item.icon,
            size: 17,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contextChip(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _statusChip(bool active, AppLocalizations l) {
    final color = active ? AppColors.success : AppColors.offline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.pause_circle_outline,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            active ? l.active : l.inactive,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final policy = await context.read<PricingProvider>().fetchPolicy(
        widget.policyId,
      );
      if (!mounted) return;
      setState(() => _policy = policy);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = AppLocalizations.of(
          context,
        ).resolvePricingError(error.message),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = AppLocalizations.of(context).connectionError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(PricingPolicy policy) async {
    final saved = await context.push<bool>(
      '/profile/pricing-policies/${policy.id}/edit',
      extra: policy,
    );
    if (!mounted || saved != true) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).policySaved)),
    );
  }

  Future<void> _delete(PricingPolicy policy) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.delete),
        content: Text(l.pricingPolicyDeleteConfirm(policy.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await context.read<PricingProvider>().deletePolicy(policy.id);
      if (!mounted) return;
      context.pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).resolvePricingError(error.message),
          ),
        ),
      );
    }
  }

  String _scopeLabel(String value, AppLocalizations l) {
    return switch (value) {
      'COUNTRY' => l.countryScope,
      'CITY' => l.cityScope,
      _ => l.globalScope,
    };
  }

  String _locationLabel(PricingPolicy policy, AppLocalizations l) {
    switch (policy.scope) {
      case 'COUNTRY':
        return policy.countryName ??
            (policy.countryId == null
                ? '—'
                : l.pricingCountryNumber(policy.countryId!));
      case 'CITY':
        return policy.cityName ??
            (policy.cityId == null ? '—' : l.pricingCityNumber(policy.cityId!));
      default:
        return l.globalScope;
    }
  }

  String _orderLabel(String value, AppLocalizations l) {
    return switch (value) {
      'FOOD' => l.food,
      'TAXI' => l.taxi,
      _ => l.shipping,
    };
  }

  String _vehicleLabel(String value, AppLocalizations l) {
    return switch (value) {
      'BIKE' => l.bike,
      'MOTOR' => l.motorcycle,
      'CAR' => l.car,
      _ => l.van,
    };
  }

  String _moneyOrNotConfigured(
    String? value,
    String currency,
    AppLocalizations l,
  ) {
    return value == null ? l.notConfigured : '$value $currency';
  }

  String _formatDateTime(DateTime? value, AppLocalizations l) {
    if (value == null) return l.notConfigured;
    final local = value.toLocal();
    String pad(int number) => number.toString().padLeft(2, '0');
    final date = MaterialLocalizations.of(context).formatMediumDate(local);
    return '$date · ${pad(local.hour)}:${pad(local.minute)}';
  }
}

class _ValueItem {
  final IconData icon;
  final String label;
  final String value;

  const _ValueItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
