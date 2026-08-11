import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/theme/app_colors.dart';
import '../drivers/drivers_screen.dart';
import '../restaurants/restaurants_screen.dart';

class ManagementScreen extends StatefulWidget {
  final String initialTab;
  final String driverFilter;
  final String restaurantFilter;

  const ManagementScreen({
    super.key,
    this.initialTab = 'drivers',
    this.driverFilter = 'all',
    this.restaurantFilter = 'all',
  });

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _tabIndex(widget.initialTab),
    );
  }

  @override
  void didUpdateWidget(covariant ManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tabController.index = _tabIndex(widget.initialTab);
    }
  }

  int _tabIndex(String tab) {
    return tab == 'restaurants' ? 1 : 0;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 10, 28, 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.driversAndRestaurantsNav,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: compact ? 20 : 23,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l.managementSubtitle(
                                  admin.driversTotal,
                                  admin.restaurantsTotal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: compact ? 12 : 14,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleSearch,
                          icon: Icon(
                            _searchOpen
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                            size: 20,
                          ),
                          tooltip: _searchOpen
                              ? l.clear
                              : l.searchByNameOrPhone,
                          style: IconButton.styleFrom(
                            foregroundColor: _searchOpen
                                ? AppColors.primary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                          ),
                        ),
                        IconButton(
                          onPressed: admin.isLoading ? null : admin.refreshHome,
                          icon: const Icon(Icons.refresh_rounded, size: 19),
                          tooltip: l.refresh,
                          style: IconButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            disabledForegroundColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: _searchOpen
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                onChanged: (value) =>
                                    setState(() => _searchQuery = value),
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: l.searchByNameOrPhone,
                                  filled: true,
                                  fillColor: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.035),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    size: 18,
                                  ),
                                  suffixIcon: _searchQuery.isEmpty
                                      ? null
                                      : IconButton(
                                          onPressed: _clearSearch,
                                          icon: const Icon(
                                            Icons.close,
                                            size: 17,
                                          ),
                                        ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    SizedBox(height: _searchOpen ? 8 : 8),
                    Container(
                      height: compact ? 40 : 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.035,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.8),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        dividerColor: Colors.transparent,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: [
                          Tab(
                            child: _ManagementTabLabel(
                              icon: Icons.local_shipping_outlined,
                              label: l.drivers,
                              count: admin.driversTotal,
                            ),
                          ),
                          Tab(
                            child: _ManagementTabLabel(
                              icon: Icons.storefront_outlined,
                              label: l.restaurants,
                              count: admin.restaurantsTotal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                DriversScreen(
                  key: ValueKey('drivers-${widget.driverFilter}'),
                  initialFilter: widget.driverFilter,
                  showHeader: false,
                  showSearchToolbar: false,
                  searchQuery: _searchQuery,
                ),
                RestaurantsScreen(
                  key: ValueKey('restaurants-${widget.restaurantFilter}'),
                  initialFilter: widget.restaurantFilter,
                  showHeader: false,
                  showSearchToolbar: false,
                  searchQuery: _searchQuery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementTabLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _ManagementTabLabel({
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ),
      ],
    );
  }
}
