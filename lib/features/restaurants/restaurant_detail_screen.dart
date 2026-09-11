import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/home_response.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../management/reset_password_dialog.dart';
import '../support/create_support_ticket_dialog.dart';
import 'restaurants_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final int restaurantId;

  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  late final AdminProvider _admin;
  bool _statusActionBusy = false;

  @override
  void initState() {
    super.initState();
    _admin = context.read<AdminProvider>();
    Future.microtask(_loadRestaurant);
  }

  @override
  void dispose() {
    Future.microtask(() {
      try {
        _admin.clearRestaurantProfile();
      } catch (_) {}
    });
    super.dispose();
  }

  Future<void> _loadRestaurant() {
    return _admin.fetchRestaurant(widget.restaurantId);
  }

  Future<void> _changeRestaurantStatus(HomeRestaurant restaurant) async {
    if (_statusActionBusy) return;

    final status = restaurant.effectiveStatus;
    final enabling = status == 'INACTIVE';
    if (status != 'ACTIVE' && !enabling) return;

    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(enabling ? l.enableRestaurant : l.disableRestaurant),
        content: Text(
          enabling
              ? l.enableRestaurantConfirmation
              : l.disableRestaurantConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: Key(
              enabling
                  ? 'restaurant-enable-confirm'
                  : 'restaurant-disable-confirm',
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: enabling ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(enabling ? l.enableRestaurant : l.disableRestaurant),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _statusActionBusy = true);
    final expectedStatus = enabling ? 'ACTIVE' : 'INACTIVE';
    try {
      final refreshed = enabling
          ? await _admin.activateRestaurantFromDetail(restaurant.id)
          : await _admin.deactivateRestaurantFromDetail(restaurant.id);
      if (!mounted) return;

      if (refreshed.effectiveStatus != expectedStatus) {
        _showStatusSnack(l.restaurantStatusNotChanged, AppColors.warning);
      } else {
        _showStatusSnack(l.restaurantStatusUpdated, AppColors.success);
      }
    } on ApiException catch (error) {
      if (error.statusCode == 409) {
        // The provider reconciles conflicts too; this second guarded read
        // keeps the detail view authoritative if the first read raced.
        await _admin.tryRefreshRestaurantProfile(restaurant.id);
      }
      if (!mounted) return;
      _showStatusSnack(_restaurantStatusError(error, l), AppColors.error);
    } catch (_) {
      // A timeout can happen after the backend committed the POST. Reconcile
      // before asking the admin to try again so we never submit a blind retry.
      final reconciled = await _admin.tryRefreshRestaurantProfile(
        restaurant.id,
      );
      if (!mounted) return;
      if (reconciled?.effectiveStatus == expectedStatus) {
        _showStatusSnack(l.restaurantStatusUpdated, AppColors.success);
      } else {
        _showStatusSnack(l.restaurantStatusRetry, AppColors.error);
      }
    } finally {
      if (mounted) setState(() => _statusActionBusy = false);
    }
  }

  String _restaurantStatusError(ApiException error, AppLocalizations l) {
    if (error.statusCode == 401) return l.restaurantActionUnauthorized;
    if (error.statusCode == 403) return l.restaurantAdminPermissionDenied;
    if (error.statusCode == 404) return l.restaurantNoLongerExists;
    if (error.statusCode >= 500) return l.restaurantStatusRetry;

    final message = error.message.trim();
    return message.isEmpty ? l.restaurantStatusRetry : message;
  }

  void _showStatusSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _resetPassword(HomeRestaurant restaurant) async {
    final reset = await showResetPasswordDialog(
      context,
      userId: restaurant.ownerUser,
    );
    if (!reset || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).passwordResetSuccessfully),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final restaurant = admin.restaurantProfile;

    return Scaffold(
      appBar: AppBar(title: Text(l.restaurantDetails), centerTitle: false),
      body: admin.restaurantProfileLoading && restaurant == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    l.loadingDetails,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          : restaurant == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.failedToLoadDetails,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _loadRestaurant,
                    child: Text(l.retry),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (admin.isLoading)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(child: _buildContent(context, restaurant)),
              ],
            ),
    );
  }

  Widget _buildContent(BuildContext context, HomeRestaurant restaurant) {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(context, restaurant, now),
              const SizedBox(height: 16),
              _buildRestaurantStatusCard(context, restaurant),
              const SizedBox(height: 16),
              _buildSupportCard(context, restaurant),
              const SizedBox(height: 16),
              _buildSection(
                context,
                title: l.restaurantInfo,
                icon: Icons.assignment_outlined,
                children: [
                  _buildDetailRow(context, l.id, '${restaurant.id}'),
                  if (restaurant.ownerUser > 0)
                    _buildDetailRow(
                      context,
                      l.ownerUser,
                      '${restaurant.ownerUser}',
                    ),
                  _buildDetailRow(
                    context,
                    l.status,
                    localizedRestaurantStatus(l, restaurant.effectiveStatus),
                  ),
                  _buildDetailRow(
                    context,
                    l.active,
                    restaurant.effectiveStatus == 'ACTIVE' ? l.yes : l.no,
                  ),
                  _buildDetailRow(
                    context,
                    l.currentHoursStatus,
                    restaurantHoursSummary(restaurant, now, l),
                  ),
                  if (restaurant.createdAt != null)
                    _buildDetailRow(
                      context,
                      l.registeredDate,
                      _fmtDateTime(l, restaurant.createdAt!),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                title: l.contactInfo,
                icon: Icons.contact_phone_outlined,
                children: [
                  _buildDetailRow(
                    context,
                    l.phone,
                    restaurant.phone.isNotEmpty
                        ? restaurant.phone
                        : l.notProvided,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                title: l.accountInfo,
                icon: Icons.security_outlined,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key('restaurant-reset-password'),
                      onPressed: () => _resetPassword(restaurant),
                      icon: const Icon(Icons.lock_reset_rounded, size: 19),
                      label: Text(l.resetPassword),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (restaurant.address != null) ...[
                const SizedBox(height: 16),
                _buildAddressSection(context, restaurant.address!),
              ],
              const SizedBox(height: 16),
              _buildHoursSection(context, restaurant, now),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    HomeRestaurant restaurant,
    DateTime now,
  ) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final openNow = restaurant.isOpenNow(now);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RestaurantAvatar(restaurant: restaurant, size: 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  restaurant.displayAddress.isNotEmpty
                      ? restaurant.displayAddress
                      : l.notProvided,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(
                      label: openNow ? l.openNow : l.closedNow,
                      color: openNow ? AppColors.online : AppColors.offline,
                    ),
                    StatusBadge(
                      label: localizedRestaurantStatus(
                        l,
                        restaurant.effectiveStatus,
                      ),
                      color: restaurantStatusColor(restaurant.effectiveStatus),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantStatusCard(
    BuildContext context,
    HomeRestaurant restaurant,
  ) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final status = restaurant.effectiveStatus;
    final canDisable = status == 'ACTIVE';
    final canEnable = status == 'INACTIVE';
    final statusDescription = switch (status) {
      'ACTIVE' => l.restaurantActiveStatusDescription,
      'INACTIVE' => l.restaurantInactiveStatusDescription,
      'PENDING' => l.restaurantPendingStatusDescription,
      _ => l.restaurantStatusRetry,
    };

    return _buildSection(
      context,
      title: l.status,
      icon: Icons.toggle_on_outlined,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusBadge(
              label: localizedRestaurantStatus(l, status),
              color: restaurantStatusColor(status),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                statusDescription,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
            ),
          ],
        ),
        if (canDisable || canEnable) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: Key(
                canDisable
                    ? 'restaurant-disable-button'
                    : 'restaurant-enable-button',
              ),
              onPressed: _statusActionBusy
                  ? null
                  : () => _changeRestaurantStatus(restaurant),
              icon: _statusActionBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      canDisable
                          ? Icons.block_outlined
                          : Icons.check_circle_outline,
                      size: 19,
                    ),
              label: Text(
                _statusActionBusy
                    ? l.restaurantStatusUpdating
                    : canDisable
                    ? l.disableRestaurant
                    : l.enableRestaurant,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: canDisable
                    ? AppColors.error
                    : AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSupportCard(BuildContext context, HomeRestaurant restaurant) {
    final l = AppLocalizations.of(context);
    final canContact = restaurant.id > 0 && restaurant.ownerUser > 0;
    return _buildSection(
      context,
      title: l.support,
      icon: Icons.support_agent_outlined,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('restaurant-create-support-ticket'),
            onPressed: canContact
                ? () => createSupportTicketFromContext(
                    context,
                    preset: SupportTicketComposerPreset.restaurant(
                      restaurantId: restaurant.id,
                      recipientUserId: restaurant.ownerUser,
                      restaurantName: restaurant.name,
                    ),
                  )
                : null,
            icon: const Icon(Icons.add_comment_outlined, size: 19),
            label: Text(
              canContact ? l.createSupportTicket : l.noEligibleRecipients,
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection(BuildContext context, RestaurantAddress address) {
    final l = AppLocalizations.of(context);

    return _buildSection(
      context,
      title: l.address,
      icon: Icons.location_on_outlined,
      children: [
        if (address.label.isNotEmpty)
          _buildDetailRow(context, l.label, address.label),
        if (address.fullAddress.isNotEmpty)
          _buildDetailRow(context, l.fullAddress, address.fullAddress),
        if (address.streetName.isNotEmpty)
          _buildDetailRow(context, l.streetName, address.streetName),
        if (address.houseNumber.isNotEmpty)
          _buildDetailRow(context, l.houseNumber, address.houseNumber),
        if (address.city.isNotEmpty)
          _buildDetailRow(context, l.city, address.city),
        if (address.postalCode.isNotEmpty)
          _buildDetailRow(context, l.postalCode, address.postalCode),
        if (address.country.isNotEmpty)
          _buildDetailRow(context, l.country, address.country),
        if (address.hasCoordinates)
          _buildDetailRow(
            context,
            l.coordinates,
            '${address.lat}, ${address.lng}',
          ),
      ],
    );
  }

  Widget _buildHoursSection(
    BuildContext context,
    HomeRestaurant restaurant,
    DateTime now,
  ) {
    final l = AppLocalizations.of(context);
    final opening = restaurant.openingStatus(now);
    final todayKey = RestaurantWorkHours.dayKeyFor(now);

    return _buildSection(
      context,
      title: l.workingHours,
      icon: Icons.schedule_outlined,
      children: [
        ...RestaurantWorkHours.dayKeys.map((dayKey) {
          return _HoursDayRow(
            dayLabel: l.weekdayName(dayKey),
            ranges: restaurant.workHours.rangesFor(dayKey),
            closedText: l.closed,
            isToday: dayKey == todayKey,
            isCurrentOpenDay:
                opening.isOpenNow && opening.currentDayKey == dayKey,
          );
        }),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              Icon(
                icon,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 136,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDateTime(AppLocalizations l, DateTime d) {
    return l.formatDateTime(d);
  }
}

class _HoursDayRow extends StatelessWidget {
  final String dayLabel;
  final List<RestaurantTimeRange> ranges;
  final String closedText;
  final bool isToday;
  final bool isCurrentOpenDay;

  const _HoursDayRow({
    required this.dayLabel,
    required this.ranges,
    required this.closedText,
    required this.isToday,
    required this.isCurrentOpenDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = isCurrentOpenDay ? AppColors.online : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isToday ? accent.withValues(alpha: 0.07) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday
              ? accent.withValues(alpha: 0.2)
              : theme.dividerColor.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              dayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isToday ? accent : theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              ranges.isEmpty
                  ? closedText
                  : ranges.map((range) => range.display).join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: ranges.isEmpty
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
