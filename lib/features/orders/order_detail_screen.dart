import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/admin_order.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../support/create_support_ticket_dialog.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  AdminOrder? _order;
  List<OrderStatusHistory> _history = [];
  bool _loading = false;
  bool _historyLoading = false;
  bool _permissionDenied = false;
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
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _order == null ? l.orderDetails : l.orderNumber(_order!.id),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
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
    if (_loading && _order == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_order == null) {
      final title = _permissionDenied
          ? l.ordersPermissionDeniedTitle
          : _error ?? l.connectionError;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _permissionDenied
                    ? Icons.lock_outline_rounded
                    : Icons.error_outline_rounded,
                size: 44,
                color: _permissionDenied
                    ? AppColors.warning
                    : theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _permissionDenied
                      ? FontWeight.w800
                      : FontWeight.w400,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              if (_permissionDenied) ...[
                const SizedBox(height: 8),
                Text(
                  l.ordersPermissionDeniedBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.48),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: Text(l.retry)),
            ],
          ),
        ),
      );
    }

    final order = _order!;
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailHeader(order: order),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 940;
                final left = Column(
                  children: [
                    _RoutePanel(order: order),
                    const SizedBox(height: 14),
                    _PeoplePanel(order: order),
                    const SizedBox(height: 14),
                    _OrderContentPanel(order: order),
                    const SizedBox(height: 14),
                    _InstructionsPanel(order: order),
                  ],
                );
                final right = Column(
                  children: [
                    _PricingPanel(order: order),
                    const SizedBox(height: 14),
                    _DispatchPanel(order: order),
                    const SizedBox(height: 14),
                    _HistoryPanel(
                      order: order,
                      history: _history,
                      loading: _historyLoading,
                    ),
                  ],
                );

                if (!wide) {
                  return Column(
                    children: [left, const SizedBox(height: 14), right],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: left),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: right),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _historyLoading = true;
      _error = null;
      _permissionDenied = false;
    });

    try {
      final api = context.read<AdminProvider>().apiService;
      final order = await api.getAdminOrder(widget.orderId);
      if (!mounted) return;
      setState(() => _order = order);

      try {
        final history = await api.getOrderStatusHistory(widget.orderId);
        if (mounted) setState(() => _history = history.results);
      } catch (_) {
        if (mounted) setState(() => _history = const []);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _permissionDenied = e.statusCode == 403;
        _error = _permissionDenied ? null : e.message;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).connectionError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _historyLoading = false;
        });
      }
    }
  }
}

class _DetailHeader extends StatelessWidget {
  final AdminOrder order;

  const _DetailHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final typeColor = _typeColor(order.orderType);
    final statusColor = _statusColor(order.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(color: theme.dividerColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.orderNumber(order.id),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_typeLabel(order.orderType, l)} · ${_formatDateTime(order.createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          );
          final badges = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _Pill(label: _typeLabel(order.orderType, l), color: typeColor),
              _Pill(label: _statusLabel(order.status, l), color: statusColor),
              _Pill(
                label: order.isPaid ? l.paid : l.unpaid,
                color: order.isPaid ? AppColors.success : AppColors.warning,
              ),
            ],
          );
          final amount = Text(
            _formatAmount(order.totalAmount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.7,
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 16),
                badges,
                const SizedBox(height: 16),
                amount,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [badges, const SizedBox(height: 12), amount],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoutePanel extends StatelessWidget {
  final AdminOrder order;

  const _RoutePanel({required this.order});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Panel(
      title: l.route,
      icon: Icons.route_outlined,
      child: Column(
        children: [
          _AddressRow(
            icon: Icons.trip_origin_rounded,
            label: l.pickupAddress,
            address: order.pickupAddress,
            color: AppColors.primary,
          ),
          const SizedBox(height: 14),
          _AddressRow(
            icon: Icons.place_outlined,
            label: l.dropoffAddress,
            address: order.dropoffAddress,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _PeoplePanel extends StatelessWidget {
  final AdminOrder order;

  const _PeoplePanel({required this.order});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Panel(
      title: l.people,
      icon: Icons.people_outline_rounded,
      child: Column(
        children: [
          _PersonRow(
            icon: Icons.person_outline_rounded,
            label: l.customer,
            name: order.customer?.displayName ?? l.unknownCustomer,
            phone: order.customer?.phone,
          ),
          if (order.restaurant != null) ...[
            const _SoftDivider(),
            _PersonRow(
              icon: Icons.storefront_outlined,
              label: l.restaurant,
              name: order.restaurant!.name.isEmpty
                  ? l.unknownRestaurant
                  : order.restaurant!.name,
              phone: order.restaurant!.phone,
            ),
          ],
          const _SoftDivider(),
          _PersonRow(
            icon: Icons.local_shipping_outlined,
            label: l.assignedDriver,
            name: order.driver?.displayName ?? l.unassignedDriver,
            phone: order.driver?.phone,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('order-create-support-ticket'),
              onPressed: () => createSupportTicketFromContext(
                context,
                preset: SupportTicketComposerPreset.order(order),
              ),
              icon: const Icon(Icons.add_comment_outlined, size: 19),
              label: Text(l.createSupportTicket),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderContentPanel extends StatelessWidget {
  final AdminOrder order;

  const _OrderContentPanel({required this.order});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (order.isShipping && order.shippingPackage != null) {
      final package = order.shippingPackage!;
      return _Panel(
        title: l.packageDetails,
        icon: Icons.inventory_2_outlined,
        child: Column(
          children: [
            _InfoRow(label: l.packageSize, value: package.size),
            _InfoRow(label: l.packageWeight, value: package.weightKg),
            _InfoRow(label: l.packageContent, value: package.content),
            if (order.requestedDeliveryType != null)
              _InfoRow(
                label: l.requestedDelivery,
                value: order.requestedDeliveryType!,
              ),
          ],
        ),
      );
    }

    if (order.isTaxi) {
      return _Panel(
        title: l.orderDetails,
        icon: Icons.local_taxi_outlined,
        child: Column(
          children: [
            _InfoRow(
              label: l.requestedVehicle,
              value: order.requestedVehicleType ?? '-',
            ),
            _InfoRow(label: l.carSize, value: order.requestedCarSize ?? '-'),
          ],
        ),
      );
    }

    return _Panel(
      title: l.orderItems,
      icon: Icons.restaurant_menu_outlined,
      child: order.items.isEmpty
          ? _MutedLine(text: l.noItems)
          : Column(
              children: order.items
                  .map((item) => _ItemRow(item: item))
                  .toList(growable: false),
            ),
    );
  }
}

class _InstructionsPanel extends StatelessWidget {
  final AdminOrder order;

  const _InstructionsPanel({required this.order});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Panel(
      title: l.deliveryInstructions,
      icon: Icons.notes_outlined,
      child: Text(
        order.deliveryInstructions?.trim().isNotEmpty == true
            ? order.deliveryInstructions!
            : l.noDeliveryInstructions,
        style: TextStyle(
          fontSize: 13.5,
          height: 1.45,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.68),
        ),
      ),
    );
  }
}

class _PricingPanel extends StatelessWidget {
  final AdminOrder order;

  const _PricingPanel({required this.order});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Panel(
      title: l.pricing,
      icon: Icons.payments_outlined,
      child: Column(
        children: [
          _InfoRow(
            label: l.subtotal,
            value: _formatAmount(order.subtotalAmount),
          ),
          _InfoRow(
            label: l.deliveryFee,
            value: _formatAmount(order.deliveryFee),
          ),
          _InfoRow(
            label: l.discount,
            value: _formatAmount(order.discountAmount),
          ),
          _InfoRow(label: l.tip, value: _formatAmount(order.tip)),
          if (order.coupon != null)
            _InfoRow(label: l.coupon, value: order.coupon!.displayName),
          const _SoftDivider(),
          _InfoRow(
            label: l.totalAmount,
            value: _formatAmount(order.totalAmount),
            emphasized: true,
          ),
          const _SoftDivider(),
          _InfoRow(
            label: l.payment,
            value: _paymentLabel(order.paymentType, l),
          ),
          _InfoRow(label: l.status, value: order.isPaid ? l.paid : l.unpaid),
        ],
      ),
    );
  }
}

class _DispatchPanel extends StatelessWidget {
  final AdminOrder order;

  const _DispatchPanel({required this.order});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Panel(
      title: l.dispatch,
      icon: Icons.alt_route_outlined,
      child: Column(
        children: [
          _InfoRow(
            label: l.orderMode,
            value: order.isManual ? l.manual : l.automatic,
          ),
          _InfoRow(
            label: l.dispatchStarted,
            value: _formatDateTime(order.dispatchStartedAt),
          ),
          _InfoRow(label: l.updatedAt, value: _formatDateTime(order.updatedAt)),
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  final AdminOrder order;
  final List<OrderStatusHistory> history;
  final bool loading;

  const _HistoryPanel({
    required this.order,
    required this.history,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final entries = history.isEmpty
        ? [OrderStatusHistory(status: order.status, timestamp: order.createdAt)]
        : history;

    return _Panel(
      title: l.statusHistory,
      icon: Icons.timeline_outlined,
      trailing: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      child: Column(
        children: entries.map((entry) {
          final color = _statusColor(entry.status);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusLabel(entry.status, l),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _MutedLine(text: _formatDateTime(entry.timestamp)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailingWidget = trailing;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              ?trailingWidget,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final OrderAddress? address;
  final Color color;

  const _AddressRow({
    required this.icon,
    required this.label,
    required this.address,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = address?.displayLine;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                line == null || line.isEmpty ? '-' : line,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String name;
  final String? phone;

  const _PersonRow({
    required this.icon,
    required this.label,
    required this.name,
    this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.36),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TwoLine(label: label, value: name, caption: phone),
        ),
      ],
    );
  }
}

class _TwoLine extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;

  const _TwoLine({required this.label, required this.value, this.caption});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (caption != null && caption!.trim().isNotEmpty) ...[
          const SizedBox(height: 1),
          _MutedLine(text: caption!),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _InfoRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.48),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: emphasized ? 15 : 13,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItemSummary item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final total = item.lineTotal == null
        ? item.itemPrice
        : item.lineTotal!.toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Text(
              '${item.quantity}x',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName.isEmpty ? '#${item.item}' : item.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                _MutedLine(
                  text: '${l.unitPrice}: ${_formatAmount(item.itemPrice)}',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatAmount(total),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _MutedLine extends StatelessWidget {
  final String text;

  const _MutedLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Divider(
        height: 1,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
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

String _formatDateTime(DateTime? date) {
  if (date == null) return '-';
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
