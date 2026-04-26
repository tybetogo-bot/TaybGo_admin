import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/home_response.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class RestaurantsScreen extends StatefulWidget {
  final String initialFilter;

  const RestaurantsScreen({super.key, this.initialFilter = 'all'});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  late String _filter;
  String _search = '';
  String? _selectedStatus;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _filter = _normalizeFilter(widget.initialFilter);
    final admin = context.read<AdminProvider>();
    if (admin.homeData == null) {
      Future.microtask(() => admin.fetchHome());
    }
  }

  @override
  void didUpdateWidget(covariant RestaurantsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() => _filter = _normalizeFilter(widget.initialFilter));
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final now = DateTime.now();

    final restaurants = admin.restaurants;
    final activeCount = restaurants.where((r) => r.isActive).length;
    final inactiveCount = restaurants.length - activeCount;
    final openCount = restaurants.where((r) => r.isOpenNow(now)).length;
    final filtered = _apply(restaurants, now);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
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
                        l.restaurants,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.restaurantsScreenSub(
                          restaurants.length,
                          activeCount,
                          openCount,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (admin.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: admin.refreshHome,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: l.refresh,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 80,
              child: Row(
                children: [
                  _MiniStat(
                    label: l.total,
                    value: '${restaurants.length}',
                    color: theme.colorScheme.onSurface,
                    selected: _filter == 'all',
                    onTap: () => _setFilter('all'),
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    label: l.active,
                    value: '$activeCount',
                    color: AppColors.success,
                    selected: _filter == 'active',
                    onTap: () => _setFilter('active'),
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    label: l.openNow,
                    value: '$openCount',
                    color: AppColors.online,
                    selected: _filter == 'open',
                    onTap: () => _setFilter('open'),
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    label: l.inactive,
                    value: '$inactiveCount',
                    color: AppColors.offline,
                    selected: _filter == 'inactive',
                    onTap: () => _setFilter('inactive'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  height: 40,
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: l.searchRestaurants,
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.35,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                _filterChipBtn(l.all, 'all'),
                _filterChipBtn(l.active, 'active'),
                _filterChipBtn(l.inactive, 'inactive'),
                _filterChipBtn(l.openNow, 'open'),
                _filterChipBtn(l.closedNow, 'closed'),
                _dropdown(
                  value: _selectedStatus ?? '_all',
                  icon: Icons.verified_outlined,
                  items: _statusItems(restaurants, l),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value == '_all' ? null : value;
                    });
                  },
                ),
                _dropdown(
                  value: _selectedCity ?? '_all',
                  icon: Icons.location_city_outlined,
                  items: _cityItems(restaurants, l),
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value == '_all' ? null : value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildContent(admin, filtered, now, theme, l)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    AdminProvider admin,
    List<HomeRestaurant> filtered,
    DateTime now,
    ThemeData theme,
    AppLocalizations l,
  ) {
    if (admin.isLoading && admin.homeData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (admin.error != null && admin.restaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              admin.error!,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: admin.fetchHome, child: Text(l.retry)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return _buildCardList(filtered, now, theme, l);
        }
        return _buildTable(filtered, now, theme, l);
      },
    );
  }

  Widget _buildTable(
    List<HomeRestaurant> filtered,
    DateTime now,
    ThemeData theme,
    AppLocalizations l,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              _Col(l.restaurant, flex: 3),
              _Col(l.status, flex: 2),
              _Col(l.openingHours, flex: 3),
              _Col(l.phone, flex: 2),
              _Col(l.city, flex: 2),
            ],
          ),
        ),
        Divider(color: theme.dividerColor, height: 1),
        Expanded(
          child: filtered.isEmpty
              ? _emptyState(theme, l)
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final restaurant = filtered[i];
                    return _RestaurantTableRow(
                      restaurant: restaurant,
                      now: now,
                      onTap: () => _openRestaurant(restaurant),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCardList(
    List<HomeRestaurant> filtered,
    DateTime now,
    ThemeData theme,
    AppLocalizations l,
  ) {
    if (filtered.isEmpty) return _emptyState(theme, l);

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final restaurant = filtered[i];
        return _RestaurantCard(
          restaurant: restaurant,
          now: now,
          onTap: () => _openRestaurant(restaurant),
        );
      },
    );
  }

  Widget _emptyState(ThemeData theme, AppLocalizations l) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 40,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          Text(
            l.noRestaurantsMatchFilters,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  void _openRestaurant(HomeRestaurant restaurant) {
    context.go('/restaurants/${restaurant.id}');
  }

  List<HomeRestaurant> _apply(List<HomeRestaurant> restaurants, DateTime now) {
    var result = restaurants;

    switch (_filter) {
      case 'active':
        result = result.where((r) => r.isActive).toList();
      case 'inactive':
        result = result.where((r) => !r.isActive).toList();
      case 'open':
        result = result.where((r) => r.isOpenNow(now)).toList();
      case 'closed':
        result = result.where((r) => !r.isOpenNow(now)).toList();
    }

    if (_selectedStatus != null) {
      result = result.where((r) => r.status == _selectedStatus).toList();
    }

    if (_selectedCity != null) {
      result = result.where((r) => r.city == _selectedCity).toList();
    }

    if (_search.trim().isNotEmpty) {
      final query = _search.trim().toLowerCase();
      result = result.where((r) {
        return r.name.toLowerCase().contains(query) ||
            r.phone.toLowerCase().contains(query) ||
            r.displayAddress.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  void _setFilter(String filter) {
    setState(() => _filter = _normalizeFilter(filter));
  }

  String _normalizeFilter(String value) {
    const allowed = {'all', 'active', 'inactive', 'open', 'closed'};
    return allowed.contains(value) ? value : 'all';
  }

  List<DropdownMenuItem<String>> _statusItems(
    List<HomeRestaurant> restaurants,
    AppLocalizations l,
  ) {
    final statuses =
        restaurants
            .map((r) => r.status)
            .where((status) => status.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return [
      DropdownMenuItem(value: '_all', child: Text(l.allStatuses)),
      ...statuses.map(
        (status) => DropdownMenuItem(
          value: status,
          child: Text(localizedRestaurantStatus(l, status)),
        ),
      ),
    ];
  }

  List<DropdownMenuItem<String>> _cityItems(
    List<HomeRestaurant> restaurants,
    AppLocalizations l,
  ) {
    final cities =
        restaurants
            .map((r) => r.city)
            .where((city) => city.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return [
      DropdownMenuItem(value: '_all', child: Text(l.allCities)),
      ...cities.map((city) => DropdownMenuItem(value: city, child: Text(city))),
    ];
  }

  Widget _dropdown({
    required String value,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    final selected = value != '_all';

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.3)
              : theme.dividerColor,
        ),
        color: selected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          isDense: true,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? AppColors.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      const SizedBox(width: 6),
                      item.child,
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _filterChipBtn(String label, String value) {
    final selected = _filter == value;
    return FilterChip(
      selected: selected,
      showCheckmark: false,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      side: BorderSide(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.3)
            : Theme.of(context).dividerColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _RestaurantTableRow extends StatefulWidget {
  final HomeRestaurant restaurant;
  final DateTime now;
  final VoidCallback onTap;

  const _RestaurantTableRow({
    required this.restaurant,
    required this.now,
    required this.onTap,
  });

  @override
  State<_RestaurantTableRow> createState() => _RestaurantTableRowState();
}

class _RestaurantTableRowState extends State<_RestaurantTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final openColor = restaurant.isOpenNow(widget.now)
        ? AppColors.online
        : AppColors.offline;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              color: _hovered
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.02)
                  : Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        RestaurantAvatar(restaurant: restaurant, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurant.name,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (restaurant.displayAddress.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  restaurant.displayAddress,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusBadge(
                          label: restaurant.isActive ? l.active : l.inactive,
                          color: restaurant.isActive
                              ? AppColors.success
                              : AppColors.offline,
                        ),
                        if (shouldShowRestaurantStatusBadge(restaurant))
                          StatusBadge(
                            label: localizedRestaurantStatus(
                              l,
                              restaurant.status,
                            ),
                            color: restaurantStatusColor(restaurant.status),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: openColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            restaurantHoursSummary(restaurant, widget.now, l),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.65,
                              ),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      restaurant.phone.isNotEmpty
                          ? restaurant.phone
                          : l.notProvided,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.65,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      restaurant.city.isNotEmpty
                          ? restaurant.city
                          : l.notProvided,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.65,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: theme.dividerColor, height: 1),
          ],
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final HomeRestaurant restaurant;
  final DateTime now;
  final VoidCallback onTap;

  const _RestaurantCard({
    required this.restaurant,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final openNow = restaurant.isOpenNow(now);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RestaurantAvatar(restaurant: restaurant, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        restaurant.displayAddress.isNotEmpty
                            ? restaurant.displayAddress
                            : l.notProvided,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.45,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge(
                  label: openNow ? l.openNow : l.closedNow,
                  color: openNow ? AppColors.online : AppColors.offline,
                ),
                StatusBadge(
                  label: restaurant.isActive ? l.active : l.inactive,
                  color: restaurant.isActive
                      ? AppColors.success
                      : AppColors.offline,
                ),
                if (shouldShowRestaurantStatusBadge(restaurant))
                  StatusBadge(
                    label: localizedRestaurantStatus(l, restaurant.status),
                    color: restaurantStatusColor(restaurant.status),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoLine(
              icon: Icons.schedule_rounded,
              text: restaurantHoursSummary(restaurant, now, l),
            ),
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.phone_outlined,
              text: restaurant.phone.isNotEmpty
                  ? restaurant.phone
                  : l.notProvided,
            ),
          ],
        ),
      ),
    );
  }
}

class RestaurantAvatar extends StatelessWidget {
  final HomeRestaurant restaurant;
  final double size;

  const RestaurantAvatar({
    super.key,
    required this.restaurant,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final initials = restaurantInitials(restaurant.name);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.13),
              AppColors.info.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: restaurant.logo != null
            ? Image.network(
                restaurant.logo!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _Initials(initials: initials),
              )
            : _Initials(initials: initials),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String initials;

  const _Initials({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.08)
                  : theme.cardTheme.color,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.45)
                    : theme.dividerColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? color
                        : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Col extends StatelessWidget {
  final String label;
  final int flex;

  const _Col(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

String restaurantHoursSummary(
  HomeRestaurant restaurant,
  DateTime now,
  AppLocalizations l,
) {
  if (!restaurant.isActive) return l.inactive;

  final opening = restaurant.openingStatus(now);
  if (opening.isOpenNow && opening.currentRange != null) {
    return l.openUntil(opening.currentRange!.close);
  }

  if (!restaurant.workHours.hasAnyHours) {
    return l.noHoursAvailable;
  }

  if (opening.nextRange != null && opening.nextDayKey != null) {
    if (opening.nextDaysAhead == 0) {
      return l.opensTodayAt(opening.nextRange!.open);
    }
    return l.opensDayAt(
      l.weekdayName(opening.nextDayKey!),
      opening.nextRange!.open,
    );
  }

  return l.closedNow;
}

String localizedRestaurantStatus(AppLocalizations l, String status) {
  return switch (status.toUpperCase()) {
    'PENDING' => l.pending,
    'APPROVED' => l.approved,
    'ACTIVE' => l.active,
    'INACTIVE' => l.inactive,
    'SUSPENDED' => l.suspended,
    'CLOSED' => l.closed,
    _ =>
      status
          .replaceAll('_', ' ')
          .toLowerCase()
          .split(' ')
          .where((word) => word.isNotEmpty)
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' '),
  };
}

Color restaurantStatusColor(String status) {
  return switch (status.toUpperCase()) {
    'APPROVED' || 'ACTIVE' => AppColors.success,
    'PENDING' => AppColors.warning,
    'SUSPENDED' || 'INACTIVE' || 'CLOSED' => AppColors.offline,
    _ => AppColors.info,
  };
}

bool shouldShowRestaurantStatusBadge(HomeRestaurant restaurant) {
  final status = restaurant.status.toUpperCase();
  if (status.isEmpty) return false;
  if (status == 'ACTIVE' || status == 'INACTIVE') return false;
  return true;
}

String restaurantInitials(String name) {
  final initials = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join();
  return initials.isNotEmpty ? initials.toUpperCase() : 'R';
}
