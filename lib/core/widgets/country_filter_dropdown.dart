import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/pricing_policy.dart';
import '../providers/country_filter_provider.dart';
import '../theme/app_spacing.dart';
import '../utils/country_flags.dart';

class CountryFilterDropdown extends StatefulWidget {
  final double? width;

  const CountryFilterDropdown({super.key, this.width});

  @override
  State<CountryFilterDropdown> createState() => _CountryFilterDropdownState();
}

class _CountryFilterDropdownState extends State<CountryFilterDropdown> {
  late final MenuController _menuController;

  @override
  void initState() {
    super.initState();
    _menuController = MenuController();
    Future.microtask(() {
      if (mounted) context.read<CountryFilterProvider>().loadCountries();
    });
  }

  @override
  void dispose() {
    _menuController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<CountryFilterProvider>();
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedCountry = filter.selectedCountry;
    final isBusy = filter.isLoading || filter.isRefreshing;

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth =
            widget.width ??
            (constraints.hasBoundedWidth ? constraints.maxWidth : 320.0);
        final menuWidth = math.min(resolvedWidth, 360.0);
        final selectedTitle = selectedCountry?.name ?? l.allCountries;
        final selectedSubtitle = filter.isLoading
            ? l.loadingCountries
            : filter.isRefreshing
            ? l.updatingCountryData
            : selectedCountry == null
            ? l.showingAllCountries
            : l.showingCountry(selectedCountry.name);

        return SizedBox(
          width: resolvedWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MenuAnchor(
                controller: _menuController,
                style: MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(scheme.surface),
                  surfaceTintColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                  elevation: const WidgetStatePropertyAll(10),
                  padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusLarge,
                      ),
                      side: BorderSide(
                        color: scheme.outline.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                ),
                menuChildren: [
                  _CountryMenu(
                    width: menuWidth,
                    countries: filter.countries,
                    selectedCountryId: filter.selectedCountryId,
                    isLoading: filter.isLoading,
                    onSelected: (countryId) {
                      _menuController.close();
                      filter.selectCountry(countryId);
                    },
                    onRetry: filter.loadCountries,
                  ),
                ],
                builder: (context, controller, child) {
                  final isOpen = controller.isOpen;
                  final borderColor = isOpen
                      ? scheme.primary
                      : scheme.outline.withValues(alpha: 0.22);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isBusy
                          ? null
                          : () =>
                                isOpen ? controller.close() : controller.open(),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusLarge,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: resolvedWidth,
                        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLarge,
                          ),
                          gradient: LinearGradient(
                            colors: [
                              scheme.primary.withValues(alpha: 0.07),
                              scheme.surface,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: borderColor,
                            width: isOpen ? 1.4 : 1,
                          ),
                          boxShadow: [
                            if (isOpen)
                              BoxShadow(
                                color: scheme.primary.withValues(alpha: 0.1),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _CountryLeading(
                              isoCode: selectedCountry?.isoCode,
                              countryName: selectedCountry?.name,
                              isAllCountries: selectedCountry == null,
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.countryFilter,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.52,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    selectedTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedSubtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isBusy)
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.primary,
                                ),
                              )
                            else
                              Icon(
                                isOpen
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: scheme.onSurface.withValues(alpha: 0.55),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (filter.error != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 14,
                      color: scheme.error,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        l.failedToLoadCountries,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: scheme.error),
                      ),
                    ),
                    TextButton(
                      onPressed: filter.loadCountries,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(l.retry),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CountryMenu extends StatelessWidget {
  final double width;
  final List<AdminCountry> countries;
  final int? selectedCountryId;
  final bool isLoading;
  final ValueChanged<int?> onSelected;
  final VoidCallback onRetry;

  const _CountryMenu({
    required this.width,
    required this.countries,
    required this.selectedCountryId,
    required this.isLoading,
    required this.onSelected,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final scheme = theme.colorScheme;
    final itemCount = countries.length + 1;
    final listHeight = math.min(360.0, math.max(56.0, itemCount * 52.0));

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Icon(
                    Icons.public_rounded,
                    size: 17,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.countryFilter,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.countryFilterDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outline.withValues(alpha: 0.14)),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: scheme.primary),
              ),
            )
          else if (countries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
              child: Column(
                children: [
                  Text(
                    l.failedToLoadCountries,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: onRetry, child: Text(l.retry)),
                ],
              ),
            )
          else
            SizedBox(
              height: listHeight,
              child: ListView(
                padding: const EdgeInsets.only(top: 6, bottom: 6),
                children: [
                  _CountryMenuItem(
                    title: l.allCountries,
                    subtitle: l.showingAllCountries,
                    isSelected: selectedCountryId == null,
                    isAllCountries: true,
                    onTap: () => onSelected(null),
                  ),
                  ...countries.map(
                    (country) => _CountryMenuItem(
                      title: country.name,
                      subtitle: country.isoCode?.toUpperCase(),
                      isoCode: country.isoCode,
                      isSelected: country.id == selectedCountryId,
                      onTap: () => onSelected(country.id),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CountryMenuItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? isoCode;
  final bool isSelected;
  final bool isAllCountries;
  final VoidCallback onTap;

  const _CountryMenuItem({
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
    this.isoCode,
    this.isAllCountries = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Material(
        color: isSelected
            ? scheme.primary.withValues(alpha: 0.09)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                _CountryLeading(
                  isoCode: isoCode,
                  countryName: title,
                  isAllCountries: isAllCountries,
                  compact: true,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: isAllCountries ? 0 : 0.7,
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 140),
                  child: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          key: const ValueKey('selected'),
                          size: 19,
                          color: scheme.primary,
                        )
                      : const SizedBox(
                          key: ValueKey('unselected'),
                          width: 19,
                          height: 19,
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

class _CountryLeading extends StatelessWidget {
  final String? isoCode;
  final String? countryName;
  final bool isAllCountries;
  final bool compact;

  const _CountryLeading({
    required this.isoCode,
    required this.countryName,
    required this.isAllCountries,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = compact ? 34.0 : 40.0;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: compact ? 0.08 : 0.12),
        shape: BoxShape.circle,
      ),
      child: isAllCountries
          ? Icon(
              Icons.public_rounded,
              size: compact ? 17 : 20,
              color: scheme.primary,
            )
          : Text(
              countryFlagEmoji(isoCode: isoCode, countryName: countryName),
              style: TextStyle(fontSize: compact ? 17 : 20),
            ),
    );
  }
}
