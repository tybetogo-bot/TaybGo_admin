import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/admin_order.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _searchController = TextEditingController();

  List<AdminOrder> _orders = [];
  int _total = 0;
  int _page = 1;
  String? _next;
  String? _previous;
  String? _error;
  bool _loading = false;
  bool _permissionDenied = false;
  String _search = '';
  String _status = '';
  String _orderType = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_fetchOrders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final restricted = _permissionDenied && _orders.isEmpty;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme, l),
            const SizedBox(height: 20),
            if (restricted)
              Expanded(
                child: _OrdersPermissionState(
                  onRetry: _loading ? null : () => _fetchOrders(page: 1),
                ),
              )
            else ...[
              _buildFilters(theme, l),
              const SizedBox(height: 16),
              _OrderSummary(orders: _orders, total: _total, loading: _loading),
              const SizedBox(height: 16),
              Expanded(child: _buildContent(theme, l)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppLocalizations l) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.ordersTitle,
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
                _permissionDenied && _orders.isEmpty
                    ? l.ordersPermissionDeniedSubtitle
                    : l.ordersSubtitle(_orders.length, _total),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        if (_loading && _orders.isNotEmpty)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          IconButton(
            onPressed: _loading ? null : () => _fetchOrders(page: _page),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: l.refresh,
          ),
      ],
    );
  }

  Widget _buildFilters(ThemeData theme, AppLocalizations l) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final search = TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _applySearch(),
          decoration: InputDecoration(
            hintText: l.searchOrders,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchController.text.trim().isEmpty
                ? null
                : IconButton(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: l.clear,
                  ),
          ),
        );
        final type = _filterDropdown(
          label: l.orderType,
          icon: Icons.category_outlined,
          value: _orderType,
          items: {
            '': l.allTypes,
            'FOOD': l.food,
            'SHIPPING': l.shipping,
            'TAXI': l.taxi,
          },
          onChanged: (value) {
            setState(() => _orderType = value ?? '');
            _fetchOrders(page: 1);
          },
        );
        final status = _filterDropdown(
          label: l.status,
          icon: Icons.tune_rounded,
          value: _status,
          items: {
            '': l.allOrderStatuses,
            'PENDING': l.pending,
            'SEARCHING_FOR_DRIVER': l.searchingForDriver,
            'ACCEPTED': l.accepted,
            'ON_THE_WAY': l.onTheWay,
            'DELIVERED': l.delivered,
            'COMPLETED': l.completed,
            'REJECTED': l.rejected,
            'EXPIRED': l.expired,
            'CANCELLED': l.cancelled,
          },
          onChanged: (value) {
            setState(() => _status = value ?? '');
            _fetchOrders(page: 1);
          },
        );

        if (compact) {
          return Column(
            children: [
              search,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: type),
                  const SizedBox(width: 10),
                  Expanded(child: status),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 12),
            SizedBox(width: 210, child: type),
            const SizedBox(width: 12),
            SizedBox(width: 240, child: status),
          ],
        );
      },
    );
  }

  Widget _filterDropdown({
    required String label,
    required IconData icon,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
      items: items.entries
          .map(
            (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: _loading ? null : onChanged,
    );
  }

  Widget _buildContent(ThemeData theme, AppLocalizations l) {
    if (_loading && _orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _orders.isEmpty) {
      return _OrdersEmptyState(
        icon: Icons.cloud_off_outlined,
        title: _error!,
        action: TextButton(onPressed: _fetchOrders, child: Text(l.retry)),
      );
    }

    if (_orders.isEmpty) {
      return _OrdersEmptyState(
        icon: Icons.receipt_long_outlined,
        title: l.noOrdersFound,
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: _orders.length,
            separatorBuilder: (context, index) =>
                Divider(color: theme.dividerColor, height: 1),
            itemBuilder: (context, index) {
              final order = _orders[index];
              return _OrderRow(
                order: order,
                onTap: () => context.go('/orders/${order.id}'),
              );
            },
          ),
        ),
        _PaginationBar(
          page: _page,
          hasNext: _next != null,
          hasPrevious: _previous != null,
          onNext: _loading ? null : () => _fetchOrders(page: _page + 1),
          onPrevious: _loading || _page <= 1
              ? null
              : () => _fetchOrders(page: _page - 1),
        ),
      ],
    );
  }

  Future<void> _fetchOrders({int? page}) async {
    setState(() {
      _loading = true;
      _error = null;
      _permissionDenied = false;
    });

    try {
      final result = await context
          .read<AdminProvider>()
          .apiService
          .getAdminOrders(
            page: page ?? _page,
            search: _search,
            status: _status,
            orderType: _orderType,
          );
      if (!mounted) return;
      setState(() {
        _orders = result.results;
        _total = result.count;
        _next = result.next;
        _previous = result.previous;
        _page = page ?? _page;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _permissionDenied = e.statusCode == 403;
        if (_permissionDenied) {
          _orders = const [];
          _total = 0;
          _next = null;
          _previous = null;
          _page = 1;
          _error = null;
        } else {
          _error = e.message;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).connectionError);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applySearch() {
    setState(() => _search = _searchController.text.trim());
    _fetchOrders(page: 1);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _search = '');
    _fetchOrders(page: 1);
  }
}

class _OrdersPermissionState extends StatelessWidget {
  final VoidCallback? onRetry;

  const _OrdersPermissionState({this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.ordersPermissionDeniedTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.ordersPermissionDeniedBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final List<AdminOrder> orders;
  final int total;
  final bool loading;

  const _OrderSummary({
    required this.orders,
    required this.total,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final completed = orders.where((o) => o.status == 'COMPLETED').length;
    final active = orders
        .where(
          (o) => const {
            'PENDING',
            'SEARCHING_FOR_DRIVER',
            'DRIVER_NOTIFICATION_SENT',
            'ACCEPTED',
            'ON_THE_WAY',
            'DELIVERED',
          }.contains(o.status),
        )
        .length;
    final revenue = orders.fold<double>(
      0,
      (sum, order) => sum + order.totalValue,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 560
            ? 2
            : 1;
        final gap = 12.0;
        final width = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _MetricTile(
              width: width,
              label: l.totalOrders,
              value: '$total',
              icon: Icons.receipt_long_outlined,
              color: AppColors.primary,
            ),
            _MetricTile(
              width: width,
              label: l.activeOrders,
              value: '$active',
              icon: Icons.local_shipping_outlined,
              color: AppColors.info,
            ),
            _MetricTile(
              width: width,
              label: l.completed,
              value: '$completed',
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.success,
            ),
            _MetricTile(
              width: width,
              label: l.visibleAmount,
              value: _formatAmount(revenue.toStringAsFixed(2)),
              icon: Icons.payments_outlined,
              color: AppColors.warning,
            ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Container(
        height: 86,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatefulWidget {
  final AdminOrder order;
  final VoidCallback onTap;

  const _OrderRow({required this.order, required this.onTap});

  @override
  State<_OrderRow> createState() => _OrderRowState();
}

class _OrderRowState extends State<_OrderRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final statusColor = _statusColor(order.status);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          color: _hovered
              ? theme.colorScheme.onSurface.withValues(alpha: 0.025)
              : Colors.transparent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OrderRowLead(order: order),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SubtleText(
                            '${order.customer?.displayName ?? l.unknownCustomer} · ${order.restaurant?.name ?? order.driver?.displayName ?? l.unassignedDriver}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        _StatusPill(
                          label: _statusLabel(order.status, l),
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _SubtleText(_formatDate(order.createdAt)),
                        const Spacer(),
                        Text(
                          _formatAmount(order.totalAmount),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 3, child: _OrderRowLead(order: order)),
                  Expanded(
                    flex: 2,
                    child: _TwoLineCell(
                      title: order.customer?.displayName ?? l.unknownCustomer,
                      subtitle: order.customer?.phone ?? '',
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _TwoLineCell(
                      title:
                          order.restaurant?.name ??
                          order.driver?.displayName ??
                          l.unassignedDriver,
                      subtitle:
                          order.pickupAddress?.city ??
                          order.dropoffAddress?.city ??
                          '',
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _StatusPill(
                        label: _statusLabel(order.status, l),
                        color: statusColor,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      _formatAmount(order.totalAmount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  SizedBox(
                    width: 96,
                    child: _SubtleText(_formatDate(order.createdAt)),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.28),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OrderRowLead extends StatelessWidget {
  final AdminOrder order;

  const _OrderRowLead({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final color = _typeColor(order.orderType);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Icon(_typeIcon(order.orderType), color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l.orderNumber(order.id)} · ${_typeLabel(order.orderType, l)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              _SubtleText(_paymentLabel(order.paymentType, l)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TwoLineCell extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TwoLineCell({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 3),
          _SubtleText(subtitle.isEmpty ? '-' : subtitle),
        ],
      ),
    );
  }
}

class _SubtleText extends StatelessWidget {
  final String text;

  const _SubtleText(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int page;
  final bool hasNext;
  final bool hasPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const _PaginationBar({
    required this.page,
    required this.hasNext,
    required this.hasPrevious,
    this.onNext,
    this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Text(
            l.pageNumber(page),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: hasPrevious ? onPrevious : null,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: l.previousPage,
          ),
          IconButton(
            onPressed: hasNext ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: l.nextPage,
          ),
        ],
      ),
    );
  }
}

class _OrdersEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? action;

  const _OrdersEmptyState({
    required this.icon,
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 42,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.52),
            ),
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'PENDING':
    case 'SEARCHING_FOR_DRIVER':
    case 'DRIVER_NOTIFICATION_SENT':
      return AppColors.warning;
    case 'ACCEPTED':
    case 'ON_THE_WAY':
    case 'DELIVERED':
      return AppColors.info;
    case 'COMPLETED':
      return AppColors.success;
    case 'REJECTED':
    case 'EXPIRED':
    case 'CANCELLED':
      return AppColors.error;
    default:
      return AppColors.offline;
  }
}

Color _typeColor(String orderType) {
  switch (orderType) {
    case 'FOOD':
      return AppColors.primary;
    case 'SHIPPING':
      return AppColors.info;
    case 'TAXI':
      return const Color(0xFF7C3AED);
    default:
      return AppColors.offline;
  }
}

IconData _typeIcon(String orderType) {
  switch (orderType) {
    case 'FOOD':
      return Icons.restaurant_outlined;
    case 'SHIPPING':
      return Icons.inventory_2_outlined;
    case 'TAXI':
      return Icons.local_taxi_outlined;
    default:
      return Icons.receipt_long_outlined;
  }
}

String _typeLabel(String type, AppLocalizations l) {
  switch (type) {
    case 'FOOD':
      return l.food;
    case 'SHIPPING':
      return l.shipping;
    case 'TAXI':
      return l.taxi;
    default:
      return type;
  }
}

String _statusLabel(String status, AppLocalizations l) {
  switch (status) {
    case 'PENDING':
      return l.pending;
    case 'SEARCHING_FOR_DRIVER':
      return l.searchingForDriver;
    case 'DRIVER_NOTIFICATION_SENT':
      return l.driverNotificationSent;
    case 'ACCEPTED':
      return l.accepted;
    case 'ON_THE_WAY':
      return l.onTheWay;
    case 'DELIVERED':
      return l.delivered;
    case 'COMPLETED':
      return l.completed;
    case 'REJECTED':
      return l.rejected;
    case 'EXPIRED':
      return l.expired;
    case 'CANCELLED':
      return l.cancelled;
    default:
      return status;
  }
}

String _paymentLabel(String paymentType, AppLocalizations l) {
  switch (paymentType) {
    case 'CASH':
      return l.cash;
    case 'CARD':
      return l.card;
    case 'OTHER':
      return l.other;
    default:
      return paymentType.isEmpty ? '-' : paymentType;
  }
}

String _formatAmount(String? amount) {
  if (amount == null || amount.trim().isEmpty) return '-';
  return amount;
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}
