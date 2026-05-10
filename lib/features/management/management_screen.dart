import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'restaurants' ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant ManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tabController.index = widget.initialTab == 'restaurants' ? 1 : 0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 680;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.driversAndRestaurantsTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 24,
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
                    const SizedBox(height: 18),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: compact ? double.infinity : 460,
                        ),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.04,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMedium,
                            ),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSmall,
                              ),
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.25,
                                ),
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
                ),
                RestaurantsScreen(
                  key: ValueKey('restaurants-${widget.restaurantFilter}'),
                  initialFilter: widget.restaurantFilter,
                  showHeader: false,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '$label ($count)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
