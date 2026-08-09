import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/pricing_policy.dart';
import '../../core/providers/country_filter_provider.dart';
import '../../core/providers/pricing_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class PricingScreen extends StatefulWidget {
  final bool showHeader;
  final bool showBackButton;

  const PricingScreen({
    super.key,
    this.showHeader = true,
    this.showBackButton = false,
  });

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final _searchController = TextEditingController();
  final _currencyController = TextEditingController();

  String? _scope;
  int? _cityId;
  String? _orderType;
  String? _vehicleType;
  bool? _isActive;
  bool _filtersExpanded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<CountryFilterProvider>().loadCountries();
      context.read<PricingProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PricingProvider>();
    final countryFilter = context.watch<CountryFilterProvider>();
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.fromLTRB(28, widget.showHeader ? 28 : 0, 28, 0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showHeader) _buildHeader(provider, theme, l),
              _buildToolbar(provider, theme, l),
              const SizedBox(height: 14),
              _buildSearchBar(provider, l),
              const SizedBox(height: 10),
              _buildFilters(provider, countryFilter, theme, l),
              const SizedBox(height: 18),
              _buildContent(provider, theme, l),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    PricingProvider provider,
    ThemeData theme,
    AppLocalizations l,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          if (widget.showBackButton) ...[
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.pricingPolicies,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.pricingPoliciesSubtitle(provider.total),
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(
    PricingProvider provider,
    ThemeData theme,
    AppLocalizations l,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!widget.showHeader)
          Text(
            l.pricingPolicies,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        FilledButton.icon(
          onPressed: provider.isMutating ? null : () => _openEditor(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l.addPricingPolicy),
        ),
        IconButton.filledTonal(
          onPressed: provider.isLoading ? null : provider.fetchPolicies,
          icon: const Icon(Icons.refresh_rounded, size: 19),
          tooltip: l.refresh,
        ),
      ],
    );
  }

  Widget _buildSearchBar(PricingProvider provider, AppLocalizations l) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: TextField(
          controller: _searchController,
          onSubmitted: (_) => _applyFilters(provider),
          decoration: InputDecoration(
            labelText: l.searchPricingPolicies,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: IconButton(
              onPressed: provider.isLoading
                  ? null
                  : () => _applyFilters(provider),
              icon: const Icon(Icons.arrow_forward_rounded, size: 19),
              tooltip: l.applyFilters,
            ),
            isDense: true,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(
    PricingProvider provider,
    CountryFilterProvider countryFilter,
    ThemeData theme,
    AppLocalizations l,
  ) {
    final countryOptions = countryFilter.countries.isNotEmpty
        ? countryFilter.countries
        : provider.countries;
    final selectedCountry =
        countryOptions.any(
          (country) => country.id == countryFilter.selectedCountryId,
        )
        ? countryFilter.selectedCountryId
        : null;
    final selectedCity = provider.cities.any((c) => c.id == _cityId)
        ? _cityId
        : null;

    final activeFilterCount = _activeFilterCount();
    final filterSummary = activeFilterCount == 0
        ? l.filterPolicies
        : '$activeFilterCount ${l.activeFilters}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSmall,
                        ),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.filters,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            filterSummary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                    Icon(
                      _filtersExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _filtersExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.spacingM,
                      0,
                      AppSpacing.spacingM,
                      AppSpacing.spacingM,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final fieldWidth = constraints.maxWidth >= 1000
                            ? 190.0
                            : constraints.maxWidth >= 650
                            ? 220.0
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: fieldWidth,
                              child: _dropdown<String>(
                                label: l.scope,
                                value: _scope ?? '_all',
                                items: [
                                  DropdownMenuItem(
                                    value: '_all',
                                    child: Text(l.allScopes),
                                  ),
                                  DropdownMenuItem(
                                    value: 'GLOBAL',
                                    child: Text(l.globalScope),
                                  ),
                                  DropdownMenuItem(
                                    value: 'COUNTRY',
                                    child: Text(l.countryScope),
                                  ),
                                  DropdownMenuItem(
                                    value: 'CITY',
                                    child: Text(l.cityScope),
                                  ),
                                ],
                                onChanged: (value) => setState(
                                  () => _scope = value == '_all' ? null : value,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _dropdown<int>(
                                label: l.country,
                                value: selectedCountry ?? -1,
                                hint: l.country,
                                items: [
                                  DropdownMenuItem<int>(
                                    value: -1,
                                    child: Text(l.allCountries),
                                  ),
                                  ...countryOptions.map(
                                    (country) => DropdownMenuItem<int>(
                                      value: country.id,
                                      child: Text(country.name),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _cityId = null;
                                  });
                                  countryFilter.selectCountry(
                                    value == -1 ? null : value,
                                  );
                                },
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _dropdown<int>(
                                label: l.city,
                                value: selectedCity ?? -1,
                                hint: l.city,
                                items: [
                                  DropdownMenuItem<int>(
                                    value: -1,
                                    child: Text(l.allCities),
                                  ),
                                  ...provider.cities.map(
                                    (city) => DropdownMenuItem<int>(
                                      value: city.id,
                                      child: Text(city.displayName),
                                    ),
                                  ),
                                ],
                                onChanged: (value) => setState(
                                  () => _cityId = value == -1 ? null : value,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _dropdown<String>(
                                label: l.orderType,
                                value: _orderType ?? '_all',
                                items: [
                                  DropdownMenuItem(
                                    value: '_all',
                                    child: Text(l.allOrderTypes),
                                  ),
                                  DropdownMenuItem(
                                    value: 'FOOD',
                                    child: Text(l.food),
                                  ),
                                  DropdownMenuItem(
                                    value: 'SHIPPING',
                                    child: Text(l.shipping),
                                  ),
                                  DropdownMenuItem(
                                    value: 'TAXI',
                                    child: Text(l.taxi),
                                  ),
                                ],
                                onChanged: (value) => setState(
                                  () => _orderType = value == '_all'
                                      ? null
                                      : value,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _dropdown<String>(
                                label: l.vehicleType,
                                value: _vehicleType ?? '_all',
                                items: [
                                  DropdownMenuItem(
                                    value: '_all',
                                    child: Text(l.allVehicles),
                                  ),
                                  DropdownMenuItem(
                                    value: 'BIKE',
                                    child: Text(l.bike),
                                  ),
                                  DropdownMenuItem(
                                    value: 'MOTOR',
                                    child: Text(l.motorcycle),
                                  ),
                                  DropdownMenuItem(
                                    value: 'CAR',
                                    child: Text(l.car),
                                  ),
                                  DropdownMenuItem(
                                    value: 'VAN',
                                    child: Text(l.van),
                                  ),
                                ],
                                onChanged: (value) => setState(
                                  () => _vehicleType = value == '_all'
                                      ? null
                                      : value,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _dropdown<String>(
                                label: l.status,
                                value: _isActive == null
                                    ? '_all'
                                    : _isActive!
                                    ? 'true'
                                    : 'false',
                                items: [
                                  DropdownMenuItem(
                                    value: '_all',
                                    child: Text(l.allActiveStates),
                                  ),
                                  DropdownMenuItem(
                                    value: 'true',
                                    child: Text(l.activeOnly),
                                  ),
                                  DropdownMenuItem(
                                    value: 'false',
                                    child: Text(l.inactiveOnly),
                                  ),
                                ],
                                onChanged: (value) => setState(() {
                                  _isActive = value == '_all'
                                      ? null
                                      : value == 'true';
                                }),
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: TextField(
                                controller: _currencyController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                onSubmitted: (_) => _applyFilters(provider),
                                decoration: InputDecoration(
                                  labelText: l.currency,
                                  hintText: 'EUR',
                                  isDense: true,
                                ),
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: provider.isLoading
                                  ? null
                                  : () => _applyFilters(provider),
                              icon: const Icon(
                                Icons.filter_alt_outlined,
                                size: 18,
                              ),
                              label: Text(l.applyFilters),
                            ),
                            TextButton(
                              onPressed: provider.isLoading
                                  ? null
                                  : () => _clearFilters(provider),
                              child: Text(l.clear),
                            ),
                            if (provider.locationsLoading)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hint,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, isDense: true),
      hint: hint == null ? null : Text(hint),
      items: items,
      onChanged: onChanged,
    );
  }

  Future<void> _applyFilters(PricingProvider provider) async {
    await provider.applyFilters(
      search: _searchController.text,
      scope: _scope,
      countryId: context.read<CountryFilterProvider>().selectedCountryId,
      cityId: _cityId,
      orderType: _orderType,
      vehicleType: _vehicleType,
      isActive: _isActive,
      currency: _currencyController.text,
    );
  }

  Future<void> _clearFilters(PricingProvider provider) async {
    _searchController.clear();
    _currencyController.clear();
    setState(() {
      _scope = null;
      _cityId = null;
      _orderType = null;
      _vehicleType = null;
      _isActive = null;
    });
    await provider.clearFilters();
    await provider.loadCities();
  }

  int _activeFilterCount() {
    final countryId = context.read<CountryFilterProvider>().selectedCountryId;
    return [
      _searchController.text.trim().isNotEmpty,
      _scope != null,
      countryId != null,
      _cityId != null,
      _orderType != null,
      _vehicleType != null,
      _isActive != null,
      _currencyController.text.trim().isNotEmpty,
    ].where((active) => active).length;
  }

  Widget _buildContent(
    PricingProvider provider,
    ThemeData theme,
    AppLocalizations l,
  ) {
    if (provider.isLoading && provider.policies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null && provider.policies.isEmpty) {
      return _errorState(provider, theme, l);
    }

    if (provider.policies.isEmpty) {
      return _emptyState(theme, l);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (provider.error != null) ...[
          _inlineError(l.resolvePricingError(provider.error!), theme),
          const SizedBox(height: 10),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 900) {
              return Column(
                children: provider.policies
                    .map((policy) => _policyCard(policy, theme, l))
                    .toList(),
              );
            }
            return _policyTable(provider.policies, theme, l);
          },
        ),
        const SizedBox(height: 14),
        _pagination(provider, theme, l),
      ],
    );
  }

  Widget _errorState(
    PricingProvider provider,
    ThemeData theme,
    AppLocalizations l,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 42, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              l.resolvePricingError(provider.error!),
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: provider.fetchPolicies,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ThemeData theme, AppLocalizations l) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(42),
        child: Column(
          children: [
            Icon(
              Icons.price_change_outlined,
              size: 44,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              l.noPricingPolicies,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inlineError(String error, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(
        error,
        style: TextStyle(color: AppColors.error, fontSize: 13),
      ),
    );
  }

  Widget _policyTable(
    List<PricingPolicy> policies,
    ThemeData theme,
    AppLocalizations l,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.035),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    l.pricingName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    l.policyLocation,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    l.baseAmount,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    l.perKmRate,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 92,
                  child: Text(
                    l.status,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 76),
              ],
            ),
          ),
          ...policies.map((policy) => _desktopPolicyRow(policy, theme, l)),
        ],
      ),
    );
  }

  Widget _desktopPolicyRow(
    PricingPolicy policy,
    ThemeData theme,
    AppLocalizations l,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetails(policy),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      policy.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_orderLabel(policy.orderType, l)} · ${_vehicleLabel(policy.vehicleType, l)} · v${policy.version}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.48,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${_scopeLabel(policy.scope, l)} · ${_locationLabel(policy, l)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${policy.baseAmount} ${policy.currency}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Text(
                  '${policy.perKmRate} ${policy.currency}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(width: 92, child: _statusChip(policy.isActive, l)),
              SizedBox(
                width: 76,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => _openEditor(policy),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: l.editPricingPolicy,
                      visualDensity: VisualDensity.compact,
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _policyCard(
    PricingPolicy policy,
    ThemeData theme,
    AppLocalizations l,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetails(policy),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            policy.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'v${policy.version} · ${policy.currency}',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statusChip(policy.isActive, l),
                    IconButton(
                      onPressed: () => _openEditor(policy),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: l.editPricingPolicy,
                      visualDensity: VisualDensity.compact,
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _metric(
                      l.baseAmount,
                      '${policy.baseAmount} ${policy.currency}',
                    ),
                    _metric(l.baseDistance, '${policy.baseDistance} km'),
                    _metric(
                      l.perKmRate,
                      '${policy.perKmRate} ${policy.currency}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _contextChip(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.045),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        active ? l.active : l.inactive,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _pagination(
    PricingProvider provider,
    ThemeData theme,
    AppLocalizations l,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${provider.policies.length} / ${provider.total} · ${l.pageNumber(provider.page)}',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: provider.previous == null || provider.isLoading
                  ? null
                  : () => provider.fetchPage(provider.page - 1),
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: l.previousPage,
            ),
            IconButton(
              onPressed: provider.next == null || provider.isLoading
                  ? null
                  : () => provider.fetchPage(provider.page + 1),
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: l.nextPage,
            ),
          ],
        ),
      ],
    );
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

  void _openDetails(PricingPolicy policy) {
    context.push('/profile/pricing-policies/${policy.id}');
  }

  Future<void> _openEditor([PricingPolicy? policy]) async {
    final location = policy == null
        ? '/profile/pricing-policies/new'
        : '/profile/pricing-policies/${policy.id}/edit';
    final saved = await context.push<bool>(location, extra: policy);
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).policySaved)),
    );
  }
}

class PricingPolicyFormPage extends StatefulWidget {
  final int? policyId;
  final PricingPolicy? initialPolicy;

  const PricingPolicyFormPage({super.key, this.policyId, this.initialPolicy});

  @override
  State<PricingPolicyFormPage> createState() => _PricingPolicyFormPageState();
}

class _PricingPolicyFormPageState extends State<PricingPolicyFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _baseAmountController;
  late final TextEditingController _baseDistanceController;
  late final TextEditingController _perKmRateController;
  late final TextEditingController _driverBaseAmountController;
  late final TextEditingController _driverBaseDistanceController;
  late final TextEditingController _driverPricePerKmController;
  late final TextEditingController _weightMultiplierController;
  late final TextEditingController _averageSpeedController;

  String? _scope;
  String? _orderType;
  String? _vehicleType;
  int? _countryId;
  int? _cityId;
  bool _isActive = false;
  DateTime? _effectiveFrom;
  DateTime? _effectiveTo;
  PricingPolicy? _policy;
  bool _loadingPolicy = false;
  bool _checkingConflicts = false;
  String? _loadError;
  Map<String, String> _errors = {};
  String? _formError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _baseAmountController = TextEditingController();
    _baseDistanceController = TextEditingController();
    _perKmRateController = TextEditingController();
    _driverBaseAmountController = TextEditingController();
    _driverBaseDistanceController = TextEditingController();
    _driverPricePerKmController = TextEditingController();
    _weightMultiplierController = TextEditingController();
    _averageSpeedController = TextEditingController();
    _applyPolicy(widget.initialPolicy);
    _policy = widget.initialPolicy;
    _loadingPolicy = widget.policyId != null && widget.initialPolicy == null;

    Future.microtask(() {
      if (!mounted) return;
      final provider = context.read<PricingProvider>();
      if (provider.countries.isEmpty) provider.loadCountries();
      if (provider.cities.isEmpty) provider.loadCities();
    });
    if (_loadingPolicy) Future.microtask(_loadPolicy);
  }

  void _applyPolicy(PricingPolicy? policy) {
    _nameController.text = policy?.name ?? '';
    _baseAmountController.text = policy?.baseAmount ?? '';
    _baseDistanceController.text = policy?.baseDistance ?? '';
    _perKmRateController.text = policy?.perKmRate ?? '';
    _driverBaseAmountController.text = policy?.driverBaseAmount ?? '';
    _driverBaseDistanceController.text = policy?.driverBaseDistance ?? '';
    _driverPricePerKmController.text = policy?.driverPricePerKm ?? '';
    _weightMultiplierController.text = policy?.weightMultiplier ?? '';
    _averageSpeedController.text = policy?.averageSpeedKmh?.toString() ?? '';
    _scope = policy?.scope;
    _orderType = policy?.orderType;
    _vehicleType = policy?.vehicleType;
    _countryId = policy?.countryId;
    _cityId = policy?.cityId;
    _isActive = policy?.isActive ?? false;
    _effectiveFrom = policy?.effectiveFrom?.toLocal();
    _effectiveTo = policy?.effectiveTo?.toLocal();
  }

  Future<void> _loadPolicy() async {
    try {
      final policy = await context.read<PricingProvider>().fetchPolicy(
        widget.policyId!,
      );
      if (!mounted) return;
      setState(() {
        _policy = policy;
        _applyPolicy(policy);
        _loadingPolicy = false;
        _loadError = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingPolicy = false;
        _loadError = AppLocalizations.of(
          context,
        ).resolvePricingError(error.message);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingPolicy = false;
        _loadError = AppLocalizations.of(context).connectionError;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseAmountController.dispose();
    _baseDistanceController.dispose();
    _perKmRateController.dispose();
    _driverBaseAmountController.dispose();
    _driverBaseDistanceController.dispose();
    _driverPricePerKmController.dispose();
    _weightMultiplierController.dispose();
    _averageSpeedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final provider = context.watch<PricingProvider>();
    final editing = widget.policyId != null || _policy != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(editing ? l.editPricingPolicy : l.createPricingPolicy),
      ),
      body: SafeArea(
        child: _loadingPolicy
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? _buildLoadError(l)
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              child: _buildFormFields(provider, l),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              spacing: 10,
                              children: [
                                TextButton(
                                  onPressed:
                                      provider.isMutating || _checkingConflicts
                                      ? null
                                      : () => context.pop(),
                                  child: Text(l.cancel),
                                ),
                                FilledButton(
                                  onPressed:
                                      provider.isMutating || _checkingConflicts
                                      ? null
                                      : _submit,
                                  child:
                                      provider.isMutating || _checkingConflicts
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(editing ? l.save : l.create),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoadError(AppLocalizations l) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                  _loadError ?? l.connectionError,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      child: Text(l.cancel),
                    ),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _loadingPolicy = true;
                          _loadError = null;
                        });
                        _loadPolicy();
                      },
                      child: Text(l.retry),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields(PricingProvider provider, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_formError != null) ...[
          _errorBanner(_formError!),
          const SizedBox(height: 12),
        ],
        _textField(
          controller: _nameController,
          label: l.pricingName,
          errorKey: 'name',
          prefixIcon: Icons.badge_outlined,
        ),
        const SizedBox(height: 24),
        _sectionHeader(icon: Icons.public_rounded, title: l.policyLocation),
        const SizedBox(height: 12),
        _twoColumns([
          _selectField<String>(
            label: l.scope,
            value: _scope,
            prefixIcon: Icons.public_rounded,
            items: [
              DropdownMenuItem(value: 'GLOBAL', child: Text(l.globalScope)),
              DropdownMenuItem(value: 'COUNTRY', child: Text(l.countryScope)),
              DropdownMenuItem(value: 'CITY', child: Text(l.cityScope)),
            ],
            errorKey: 'scope',
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _scope = value;
                if (value != 'COUNTRY') _countryId = null;
                if (value != 'CITY') _cityId = null;
              });
            },
          ),
          if (_scope == 'COUNTRY')
            _countryField(provider, l)
          else if (_scope == 'CITY')
            _cityField(provider, l),
        ]),
        const SizedBox(height: 24),
        _sectionHeader(icon: Icons.tune_rounded, title: l.pricingModel),
        const SizedBox(height: 12),
        _twoColumns([
          _selectField<String>(
            label: l.orderType,
            value: _orderType,
            prefixIcon: Icons.local_shipping_outlined,
            items: [
              DropdownMenuItem(value: 'FOOD', child: Text(l.food)),
              DropdownMenuItem(value: 'SHIPPING', child: Text(l.shipping)),
              DropdownMenuItem(value: 'TAXI', child: Text(l.taxi)),
            ],
            errorKey: 'order_type',
            onChanged: (value) {
              if (value != null) setState(() => _orderType = value);
            },
          ),
          _selectField<String>(
            label: l.vehicleType,
            value: _vehicleType,
            prefixIcon: Icons.directions_car_outlined,
            items: [
              DropdownMenuItem(value: 'BIKE', child: Text(l.bike)),
              DropdownMenuItem(value: 'MOTOR', child: Text(l.motorcycle)),
              DropdownMenuItem(value: 'CAR', child: Text(l.car)),
              DropdownMenuItem(value: 'VAN', child: Text(l.van)),
            ],
            errorKey: 'vehicle_type',
            onChanged: (value) {
              if (value != null) setState(() => _vehicleType = value);
            },
          ),
        ]),
        const SizedBox(height: 12),
        _twoColumns([
          _textField(
            controller: _baseAmountController,
            label: l.baseAmount,
            errorKey: 'base_amount',
            suffixText: 'EUR',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          _textField(
            controller: _baseDistanceController,
            label: l.baseDistance,
            errorKey: 'base_distance',
            suffixText: 'km',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          _textField(
            controller: _perKmRateController,
            label: l.perKmRate,
            errorKey: 'per_km_rate',
            suffixText: 'EUR/km',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          _textField(
            controller: _weightMultiplierController,
            label: l.weightMultiplier,
            errorKey: 'weight_multiplier',
            suffixText: '×',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ]),
        const SizedBox(height: 24),
        _sectionHeader(icon: Icons.payments_outlined, title: l.driverPayout),
        const SizedBox(height: 12),
        _twoColumns([
          _textField(
            controller: _driverBaseAmountController,
            label: l.driverBaseAmount,
            errorKey: 'driver_base_amount',
            suffixText: 'EUR',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          _textField(
            controller: _driverBaseDistanceController,
            label: l.driverBaseDistance,
            errorKey: 'driver_base_distance',
            suffixText: 'km',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          _textField(
            controller: _driverPricePerKmController,
            label: l.driverPricePerKm,
            errorKey: 'driver_price_per_km',
            suffixText: 'EUR/km',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ]),
        const SizedBox(height: 24),
        _sectionHeader(icon: Icons.schedule_rounded, title: l.validity),
        const SizedBox(height: 12),
        _twoColumns([
          _textField(
            controller: _averageSpeedController,
            label: l.averageSpeed,
            errorKey: 'average_speed_kmh',
            suffixText: 'km/h',
            keyboardType: TextInputType.number,
          ),
          _currencyField(l),
        ]),
        const SizedBox(height: 12),
        _twoColumns([
          _dateField(
            label: l.effectiveFrom,
            value: _effectiveFrom,
            errorKey: 'effective_from',
            emptyText: l.selectDate,
            onTap: () => _pickDateTime(isFrom: true),
          ),
          _dateField(
            label: l.effectiveTo,
            value: _effectiveTo,
            errorKey: 'effective_to',
            emptyText: l.notSet,
            onTap: () => _pickDateTime(isFrom: false),
            onClear: _effectiveTo == null
                ? null
                : () => setState(() => _effectiveTo = null),
          ),
        ]),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.25),
            ),
          ),
          child: SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            title: Text(l.active),
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader({required IconData icon, required String title}) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Icon(icon, size: 18, color: scheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(
            color: scheme.outline.withValues(alpha: 0.25),
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _errorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(
        error,
        style: TextStyle(color: AppColors.error, fontSize: 13),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String errorKey,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    IconData? prefixIcon,
    String? suffixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: _inputDecoration(
        label: label,
        errorText: _errors[errorKey],
        prefixIcon: prefixIcon,
        suffixText: suffixText,
      ),
    );
  }

  Widget _currencyField(AppLocalizations l) {
    return TextFormField(
      initialValue: 'EUR',
      readOnly: true,
      showCursor: false,
      decoration: _inputDecoration(
        label: l.currency,
        prefixIcon: Icons.euro_rounded,
        suffixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? errorText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? suffixText,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = scheme.outline.withValues(alpha: 0.35);
    final radius = BorderRadius.circular(AppSpacing.radiusMedium);
    final iconColor = scheme.onSurface.withValues(alpha: 0.58);

    return InputDecoration(
      labelText: label,
      errorText: errorText,
      filled: true,
      fillColor: scheme.surface,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: 20, color: iconColor),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      suffixStyle: TextStyle(
        color: scheme.onSurface.withValues(alpha: 0.56),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
    );
  }

  Widget _selectField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required String errorKey,
    required ValueChanged<T?> onChanged,
    IconData? prefixIcon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      icon: Icon(
        Icons.expand_more_rounded,
        color: scheme.onSurface.withValues(alpha: 0.6),
      ),
      dropdownColor: scheme.surface,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: _inputDecoration(
        label: label,
        errorText: _errors[errorKey],
        prefixIcon: prefixIcon,
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _countryField(PricingProvider provider, AppLocalizations l) {
    final value = provider.countries.any((country) => country.id == _countryId)
        ? _countryId
        : null;
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.expand_more_rounded),
      dropdownColor: Theme.of(context).colorScheme.surface,
      decoration: _inputDecoration(
        label: l.selectCountry,
        errorText: _errors['country'],
        prefixIcon: Icons.flag_outlined,
      ),
      items: provider.countries
          .map(
            (country) => DropdownMenuItem<int>(
              value: country.id,
              child: Text(country.name),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _countryId = value),
    );
  }

  Widget _cityField(PricingProvider provider, AppLocalizations l) {
    final value = provider.cities.any((city) => city.id == _cityId)
        ? _cityId
        : null;
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.expand_more_rounded),
      dropdownColor: Theme.of(context).colorScheme.surface,
      decoration: _inputDecoration(
        label: l.selectCity,
        errorText: _errors['city'],
        prefixIcon: Icons.location_city_outlined,
      ),
      items: provider.cities
          .map(
            (city) => DropdownMenuItem<int>(
              value: city.id,
              child: Text(city.displayName),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _cityId = value),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required String errorKey,
    required String emptyText,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InputDecorator(
      decoration: _inputDecoration(
        label: label,
        errorText: _errors[errorKey],
        prefixIcon: Icons.calendar_month_outlined,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  value == null ? emptyText : _formatDateTime(value),
                  style: TextStyle(
                    color: value == null
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5)
                        : null,
                  ),
                ),
              ),
            ),
          ),
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.clear_rounded, size: 18),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _twoColumns(List<Widget> children) {
    if (children.length == 1) return children.single;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 560
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }

  Future<void> _pickDateTime({required bool isFrom}) async {
    final initial = (isFrom ? _effectiveFrom : _effectiveTo) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted || time == null) return;
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isFrom) {
        _effectiveFrom = value;
      } else {
        _effectiveTo = value;
      }
    });
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final errors = PricingPolicyValidation.validate(
      name: _nameController.text,
      scope: _scope,
      countryId: _countryId,
      cityId: _cityId,
      orderType: _orderType,
      vehicleType: _vehicleType,
      baseAmount: _baseAmountController.text,
      baseDistance: _baseDistanceController.text,
      perKmRate: _perKmRateController.text,
      driverBaseAmount: _driverBaseAmountController.text,
      driverBaseDistance: _driverBaseDistanceController.text,
      driverPricePerKm: _driverPricePerKmController.text,
      weightMultiplier: _weightMultiplierController.text,
      averageSpeedKmh: _averageSpeedController.text,
      currency: 'EUR',
      version: '1',
      effectiveFrom: _effectiveFrom,
      effectiveTo: _effectiveTo,
      messages: _validationMessages(l),
    );
    if (errors.isNotEmpty) {
      setState(() {
        _errors = errors;
        _formError = l.correctHighlightedFields;
      });
      return;
    }

    setState(() {
      _errors = {};
      _formError = null;
      _checkingConflicts = true;
    });

    try {
      final provider = context.read<PricingProvider>();
      final conflicts = await _findPolicyConflicts(provider, l);
      if (!mounted) return;
      if (conflicts.isNotEmpty) {
        setState(() => _formError = conflicts.join('\n'));
        return;
      }

      final payload = {
        'name': _nameController.text.trim(),
        'scope': _scope,
        'country': _scope == 'COUNTRY' ? _countryId : null,
        'city': _scope == 'CITY' ? _cityId : null,
        'order_type': _orderType,
        'vehicle_type': _vehicleType,
        'base_amount': _baseAmountController.text.trim(),
        'base_distance': _baseDistanceController.text.trim(),
        'per_km_rate': _perKmRateController.text.trim(),
        'driver_base_amount': _nullableText(_driverBaseAmountController.text),
        'driver_base_distance': _nullableText(
          _driverBaseDistanceController.text,
        ),
        'driver_price_per_km': _nullableText(_driverPricePerKmController.text),
        'weight_multiplier': _weightMultiplierController.text.trim(),
        'average_speed_kmh': _nullableInt(_averageSpeedController.text),
        'currency': 'EUR',
        'version': 1,
        'effective_from': _effectiveFrom?.toUtc().toIso8601String(),
        'effective_to': _effectiveTo?.toUtc().toIso8601String(),
        'is_active': _isActive,
      };

      if (widget.policyId == null) {
        await provider.createPolicy(payload);
      } else {
        await provider.updatePolicy(widget.policyId!, payload);
      }
      if (mounted) context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      final nonFieldMessages = <String>{};
      final fieldErrors = <String, String>{};
      for (final entry in e.fieldErrors.entries) {
        if (_isNonFieldError(entry.key)) {
          nonFieldMessages.add(l.resolvePricingError(entry.value));
        } else {
          fieldErrors[entry.key] = l.resolvePricingFieldError(
            entry.key,
            entry.value,
          );
        }
      }
      setState(() {
        _errors = fieldErrors;
        _formError = nonFieldMessages.isNotEmpty
            ? nonFieldMessages.join('\n')
            : e.fieldErrors.isEmpty
            ? l.resolvePricingError(e.message)
            : l.serverRejectedFields;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = l.connectionError);
    } finally {
      if (mounted) setState(() => _checkingConflicts = false);
    }
  }

  Future<List<String>> _findPolicyConflicts(
    PricingProvider provider,
    AppLocalizations l,
  ) async {
    final matches = await provider.findPoliciesForTarget(
      scope: _scope!,
      countryId: _scope == 'COUNTRY' ? _countryId : null,
      cityId: _scope == 'CITY' ? _cityId : null,
      orderType: _orderType!,
      vehicleType: _vehicleType!,
    );
    final otherPolicies = matches
        .where((policy) => policy.id != widget.policyId)
        .toList();
    final conflicts = <String>{};

    if (otherPolicies.any((policy) => policy.version == 1)) {
      conflicts.add(l.pricingDuplicateVersion);
    }
    if (_isActive &&
        _effectiveTo == null &&
        otherPolicies.any(
          (policy) => policy.isActive && policy.effectiveTo == null,
        )) {
      conflicts.add(l.pricingActiveOpenEndedConflict);
    }

    return conflicts.toList();
  }

  Map<String, String> _validationMessages(AppLocalizations l) {
    return {
      'name_required': l.pricingNameRequired,
      'invalid_scope': l.pricingInvalidScope,
      'country_required': l.pricingCountryRequired,
      'city_required': l.pricingCityRequired,
      'country_must_be_empty': l.pricingCountryMustBeEmpty,
      'city_must_be_empty': l.pricingCityMustBeEmpty,
      'invalid_order_type': l.pricingInvalidOrderType,
      'invalid_vehicle_type': l.pricingInvalidVehicleType,
      'non_negative_number': l.pricingNonNegativeNumber,
      'positive_speed': l.pricingPositiveSpeed,
      'currency_three_letters': l.pricingCurrencyThreeLetters,
      'version_nonnegative': l.pricingVersionNonnegative,
      'effective_from_required': l.pricingEffectiveFromRequired,
      'effective_to_later': l.pricingEffectiveToLater,
    };
  }

  bool _isNonFieldError(String field) {
    return field == 'non_field_errors' ||
        field == '__all__' ||
        field == 'version';
  }

  String? _nullableText(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  int? _nullableInt(String value) {
    final text = value.trim();
    return text.isEmpty ? null : int.tryParse(text);
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String pad(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${pad(local.month)}-${pad(local.day)} ${pad(local.hour)}:${pad(local.minute)}';
  }
}
