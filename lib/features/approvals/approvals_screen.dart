import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/models/home_response.dart';
import '../../core/l10n/app_localizations.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    debugPrint('[ApprovalsScreen] initState');
    final admin = context.read<AdminProvider>();
    if (admin.homeData == null) {
      debugPrint('[ApprovalsScreen] No home data cached — fetching');
      Future.microtask(() => admin.fetchHome());
    }
    _tabController.addListener(() {
      final tab = _tabController.index == 0 ? 'Drivers' : 'Restaurants';
      debugPrint('[ApprovalsScreen] Tab switched to: $tab');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final admin = context.watch<AdminProvider>();
    final l = AppLocalizations.of(context);
    final totalPending =
        admin.pendingDriversTotal + admin.pendingRestaurantsTotal;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.approvals,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.applicationsWaitingReview(totalPending),
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    debugPrint('[ApprovalsScreen] Manual refresh triggered');
                    admin.refreshHome();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: l.refresh,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tabs
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerHeight: 0,
                labelColor: theme.colorScheme.onSurface,
                unselectedLabelColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.5),
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w400),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_shipping_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text(l.drivers),
                        if (admin.pendingDrivers.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _Badge(admin.pendingDriversTotal),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storefront_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text(l.restaurants),
                        if (admin.pendingRestaurants.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _Badge(admin.pendingRestaurantsTotal),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _DriversTab(drivers: admin.pendingDrivers),
                  _RestaurantsTab(restaurants: admin.pendingRestaurants),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge(this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.warning,
        ),
      ),
    );
  }
}

// ─── Drivers Tab ─────────────────────────────────────────────────

class _DriversTab extends StatelessWidget {
  final List<PendingDriver> drivers;
  const _DriversTab({required this.drivers});

  @override
  Widget build(BuildContext context) {
    if (drivers.isEmpty) return _emptyState(context);

    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 800 ? 2 : 1;
      if (cols == 1) {
        return ListView.separated(
          itemCount: drivers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _DriverCard(driver: drivers[i]),
        );
      }
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 180,
        ),
        itemCount: drivers.length,
        itemBuilder: (_, i) => _DriverCard(driver: drivers[i]),
      );
    });
  }
}

class _DriverCard extends StatefulWidget {
  final PendingDriver driver;
  const _DriverCard({required this.driver});

  @override
  State<_DriverCard> createState() => _DriverCardState();
}

class _DriverCardState extends State<_DriverCard> {
  bool _busy = false;

  Future<void> _verify(String status) async {
    if (_busy) return;
    debugPrint('[ApprovalsScreen] Verifying driver: '
        'id=${widget.driver.id}, name="${widget.driver.name}", '
        'phone="${widget.driver.phone}", action=$status');
    setState(() => _busy = true);
    final admin = context.read<AdminProvider>();
    final l = AppLocalizations.of(context);
    try {
      await admin.verifyDriver(widget.driver.id, status: status);
      if (!mounted) return;
      final msg = status == 'APPROVED'
          ? l.driverApproved(widget.driver.name)
          : l.driverRejected(widget.driver.name);
      final color = status == 'APPROVED' ? AppColors.success : AppColors.error;
      _snack(context, msg, color);
    } catch (e) {
      if (!mounted) return;
      _snack(context, l.failed('$e'), AppColors.error);
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final driver = widget.driver;
    final l = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Center(
                  child: Text(
                    driver.name
                        .split(' ')
                        .map((n) => n.isNotEmpty ? n[0] : '')
                        .take(2)
                        .join(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      driver.submittedAt != null
                          ? _fmtDate(driver.submittedAt!)
                          : l.pending,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Details
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _InfoTag(Icons.phone_outlined, driver.phone),
              _InfoTag(Icons.badge_outlined, l.statusLabel(driver.status)),
            ],
          ),
          const SizedBox(height: 16),

          // Actions
          if (_busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () => _verify('REJECTED'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        side: BorderSide(color: theme.dividerColor),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      child: Text(l.decline),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () => _verify('APPROVED'),
                      style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      child: Text(l.approve),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Restaurants Tab ─────────────────────────────────────────────

class _RestaurantsTab extends StatelessWidget {
  final List<PendingRestaurant> restaurants;
  const _RestaurantsTab({required this.restaurants});

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) return _emptyState(context);

    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 800 ? 2 : 1;
      if (cols == 1) {
        return ListView.separated(
          itemCount: restaurants.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) =>
              _RestaurantCard(restaurant: restaurants[i]),
        );
      }
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 170,
        ),
        itemCount: restaurants.length,
        itemBuilder: (_, i) =>
            _RestaurantCard(restaurant: restaurants[i]),
      );
    });
  }
}

class _RestaurantCard extends StatefulWidget {
  final PendingRestaurant restaurant;
  const _RestaurantCard({required this.restaurant});

  @override
  State<_RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<_RestaurantCard> {
  bool _busy = false;

  Future<void> _activate() async {
    if (_busy) return;
    debugPrint('[ApprovalsScreen] Activating restaurant: '
        'id=${widget.restaurant.id}, name="${widget.restaurant.name}"');
    setState(() => _busy = true);
    final admin = context.read<AdminProvider>();
    final l = AppLocalizations.of(context);
    try {
      await admin.activateRestaurant(widget.restaurant.id);
      if (!mounted) return;
      _snack(context, l.restaurantActivated(widget.restaurant.name),
          AppColors.success);
    } catch (e) {
      if (!mounted) return;
      _snack(context, l.failed('$e'), AppColors.error);
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final restaurant = widget.restaurant;
    final l = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6366F1).withValues(alpha: 0.15),
                      const Color(0xFF6366F1).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: const Center(
                  child: Icon(Icons.storefront_rounded,
                      size: 20, color: Color(0xFF6366F1)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      restaurant.submittedAt != null
                          ? _fmtDate(restaurant.submittedAt!)
                          : l.pending,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Actions
          if (_busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                onPressed: _activate,
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                child: Text(l.activate),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Shared ──────────────────────────────────────────────────────

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoTag(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

Widget _emptyState(BuildContext context) {
  final theme = Theme.of(context);
  final l = AppLocalizations.of(context);
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline_rounded,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text(
          l.allCaughtUp,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.noPendingApplications,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
          ),
        ),
      ],
    ),
  );
}

void _snack(BuildContext context, String msg, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      width: 300,
    ),
  );
}

String _fmtDate(DateTime d) {
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${m[d.month - 1]} ${d.day}, ${d.year}';
}
