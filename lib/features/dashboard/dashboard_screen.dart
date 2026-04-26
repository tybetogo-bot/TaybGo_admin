import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/models/home_response.dart';
import '../../core/l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('[DashboardScreen] initState — loading home data');
    final admin = context.read<AdminProvider>();
    Future.microtask(() {
      admin.fetchHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: admin.isLoading && admin.homeData == null
          ? const Center(child: CircularProgressIndicator())
          : admin.error != null && admin.homeData == null
          ? _ErrorView(message: admin.error!, onRetry: () => admin.fetchHome())
          : RefreshIndicator(
              onRefresh: () => admin.refreshHome(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(28),
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
                                l.overview,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l.overviewSubtitle,
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
                          ),
                        if (!admin.isLoading)
                          IconButton(
                            onPressed: () {
                              debugPrint(
                                '[DashboardScreen] Manual refresh triggered',
                              );
                              admin.refreshHome();
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            tooltip: l.refresh,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stats cards
                    LayoutBuilder(
                      builder: (context, c) {
                        final cols = c.maxWidth > 1000
                            ? 4
                            : c.maxWidth > 600
                            ? 2
                            : 2;
                        final gap = 14.0;
                        final cardW = (c.maxWidth - gap * (cols - 1)) / cols;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            _StatCard(
                              width: cardW,
                              title: l.totalOrders,
                              value: '${admin.totalOrders}',
                              subtitle: _orderStatusSummary(
                                admin.ordersCountByStatus,
                                l,
                              ),
                              accent: AppColors.primary,
                            ),
                            _StatCard(
                              width: cardW,
                              title: l.driversOnline,
                              value: '${admin.driversCount.online}',
                              subtitle: l.driversStat(
                                admin.driversCount.total,
                                admin.driversCount.offline,
                              ),
                              accent: AppColors.online,
                              onTap: () => context.go('/drivers?filter=online'),
                            ),
                            _StatCard(
                              width: cardW,
                              title: l.restaurants,
                              value: '${admin.restaurantsTotal}',
                              subtitle: _restaurantStatusSummary(
                                admin.restaurants,
                                l,
                              ),
                              accent: const Color(0xFF6366F1),
                              onTap: () => context.go('/restaurants'),
                            ),
                            _StatCard(
                              width: cardW,
                              title: l.pendingItems,
                              value:
                                  '${admin.pendingDriversTotal + admin.pendingRestaurantsTotal}',
                              subtitle: l.pendingItemsSub(
                                admin.pendingDriversTotal,
                                admin.pendingRestaurantsTotal,
                              ),
                              accent: AppColors.warning,
                              onTap: () => context.go('/approvals'),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Orders by status + Fleet status
                    LayoutBuilder(
                      builder: (context, c) {
                        if (c.maxWidth > 720) {
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _OrdersByStatusPanel(
                                    ordersCountByStatus:
                                        admin.ordersCountByStatus,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 2,
                                  child: _FleetPanel(
                                    driversCount: admin.driversCount,
                                    restaurantsTotal: admin.restaurantsTotal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Column(
                          children: [
                            _OrdersByStatusPanel(
                              ordersCountByStatus: admin.ordersCountByStatus,
                            ),
                            const SizedBox(height: 14),
                            _FleetPanel(
                              driversCount: admin.driversCount,
                              restaurantsTotal: admin.restaurantsTotal,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Bottom row: Drivers list + Pending
                    LayoutBuilder(
                      builder: (context, c) {
                        if (c.maxWidth > 720) {
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _DriversListPanel(
                                    drivers: admin.drivers,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _AttentionPanel(
                                    pendingDrivers: admin.pendingDriversTotal,
                                    pendingRestaurants:
                                        admin.pendingRestaurantsTotal,
                                    openTickets: admin.openTickets.length,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Column(
                          children: [
                            _DriversListPanel(drivers: admin.drivers),
                            const SizedBox(height: 14),
                            _AttentionPanel(
                              pendingDrivers: admin.pendingDriversTotal,
                              pendingRestaurants: admin.pendingRestaurantsTotal,
                              openTickets: admin.openTickets.length,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _orderStatusSummary(Map<String, int> counts, AppLocalizations l) {
    if (counts.isEmpty) return l.noOrdersData;
    final entries = counts.entries.take(3).map((e) {
      final label = e.key.replaceAll('_', ' ').toLowerCase();
      return '${e.value} $label';
    });
    return entries.join(' · ');
  }

  String _restaurantStatusSummary(
    List<HomeRestaurant> restaurants,
    AppLocalizations l,
  ) {
    final active = restaurants.where((r) => r.isActive).length;
    final total = restaurants.length;
    if (total == 0) return l.noRestaurantsLoaded;
    return l.activeOfShown(active, total);
  }
}

// ─── Error View ─────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ──────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;

  const _StatCard({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = SizedBox(
      width: width,
      height: 140,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                letterSpacing: -1,
                height: 1,
              ),
            ),
            const Spacer(),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return card;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: card),
    );
  }
}

// ─── Orders by Status Panel ─────────────────────────────────────

class _OrdersByStatusPanel extends StatelessWidget {
  final Map<String, int> ordersCountByStatus;
  const _OrdersByStatusPanel({required this.ordersCountByStatus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final total = ordersCountByStatus.values.fold<int>(0, (s, v) => s + v);
    final entries = ordersCountByStatus.entries.toList();

    final statusColors = <String, Color>{
      'PENDING': AppColors.warning,
      'PREPARING': const Color(0xFF6366F1),
      'READY': const Color(0xFF06B6D4),
      'PICKED_UP': const Color(0xFF8B5CF6),
      'ON_THE_WAY': AppColors.info,
      'DELIVERED': AppColors.success,
      'COMPLETED': AppColors.success,
      'CANCELLED': AppColors.error,
      'REJECTED': AppColors.error,
    };

    final statusIcons = <String, IconData>{
      'PENDING': Icons.schedule_rounded,
      'PREPARING': Icons.restaurant_rounded,
      'READY': Icons.check_circle_outline_rounded,
      'PICKED_UP': Icons.inventory_2_rounded,
      'ON_THE_WAY': Icons.local_shipping_rounded,
      'DELIVERED': Icons.done_all_rounded,
      'COMPLETED': Icons.done_all_rounded,
      'CANCELLED': Icons.cancel_outlined,
      'REJECTED': Icons.block_rounded,
    };

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                l.ordersByStatus,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${_fmt(total)} ${l.total}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stacked bar
          if (entries.isNotEmpty && total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: entries.asMap().entries.map((e) {
                    final color =
                        statusColors[e.value.key.toUpperCase()] ??
                        AppColors.offline;
                    return Expanded(
                      flex: e.value.value.clamp(1, total),
                      child: Container(
                        color: color,
                        margin: EdgeInsets.only(left: e.key > 0 ? 2 : 0),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Items
          if (entries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  l.noOrderData,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            )
          else
            ...entries.map((e) {
              final key = e.key.toUpperCase();
              final color = statusColors[key] ?? AppColors.offline;
              final icon = statusIcons[key] ?? Icons.circle_outlined;
              final pct = total > 0 ? (e.value / total * 100).round() : 0;
              final label = e.key.replaceAll('_', ' ');

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label[0].toUpperCase() +
                                label.substring(1).toLowerCase(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_fmt(e.value)} ${l.orders}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      ),
                      child: Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─── Fleet Panel ────────────────────────────────────────────────

class _FleetPanel extends StatelessWidget {
  final DriversCount driversCount;
  final int restaurantsTotal;
  const _FleetPanel({
    required this.driversCount,
    required this.restaurantsTotal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final total = driversCount.total;
    final onlinePct = total > 0
        ? (driversCount.online / total * 100).round()
        : 0;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.fleetStatus,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Text(
                '$onlinePct%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l.driversOnlineLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: total > 0 ? driversCount.online / total : 0,
                backgroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.08,
                ),
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          _FleetRow(l.totalDrivers, '$total', null),
          _FleetRow(l.online, '${driversCount.online}', AppColors.online),
          _FleetRow(l.offline, '${driversCount.offline}', AppColors.offline),
          const SizedBox(height: 8),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 8),
          _FleetRow(l.restaurants, '$restaurantsTotal', null),
        ],
      ),
    );
  }
}

class _FleetRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? dot;
  const _FleetRow(this.label, this.value, this.dot);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (dot != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Drivers List Panel ─────────────────────────────────────────

class _DriversListPanel extends StatelessWidget {
  final List<DriverWithLocation> drivers;
  const _DriversListPanel({required this.drivers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l.activeDrivers,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${drivers.length} ${l.shown}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (drivers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  l.noDriversAvailable,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            )
          else
            ...drivers.take(5).map((d) => _DriverRow(driver: d)),
        ],
      ),
    );
  }
}

class _DriverRow extends StatelessWidget {
  final DriverWithLocation driver;
  const _DriverRow({required this.driver});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final statusColor = driver.isOnline ? AppColors.online : AppColors.offline;
    final statusLabel = driver.isOnline ? l.online : l.offline;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                driver.name
                    .split(' ')
                    .map((n) => n.isNotEmpty ? n[0] : '')
                    .take(2)
                    .join(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  driver.phone,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
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

// ─── Attention Panel ────────────────────────────────────────────

class _AttentionPanel extends StatelessWidget {
  final int pendingDrivers;
  final int pendingRestaurants;
  final int openTickets;
  const _AttentionPanel({
    required this.pendingDrivers,
    required this.pendingRestaurants,
    required this.openTickets,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.needsAttention,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _AttentionItem(
            icon: Icons.local_shipping_outlined,
            label: l.pendingDriverApprovals,
            count: pendingDrivers,
            color: AppColors.warning,
          ),
          const SizedBox(height: 4),
          _AttentionItem(
            icon: Icons.storefront_outlined,
            label: l.pendingRestaurantApprovals,
            count: pendingRestaurants,
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(height: 4),
          _AttentionItem(
            icon: Icons.forum_outlined,
            label: l.openSupportTickets,
            count: openTickets,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _AttentionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _AttentionItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: count > 0 ? color.withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: count > 0
            ? Border.all(color: color.withValues(alpha: 0.15))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: count > 0
                  ? color
                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared ─────────────────────────────────────────────────────

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: theme.dividerColor),
      ),
      child: child,
    );
  }
}

String _fmt(int n) {
  if (n < 1000) return '$n';
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
