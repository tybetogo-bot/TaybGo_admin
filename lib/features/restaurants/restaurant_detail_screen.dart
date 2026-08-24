import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/home_response.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../management/reset_password_dialog.dart';
import 'restaurants_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final int restaurantId;

  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  @override
  void initState() {
    super.initState();
    final admin = context.read<AdminProvider>();
    if (admin.homeData == null) {
      Future.microtask(() => admin.fetchHome());
    }
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
    final restaurant = admin.restaurants
        .where((r) => r.id == widget.restaurantId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l.restaurantDetails), centerTitle: false),
      body: admin.isLoading && restaurant == null
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
                    onPressed: admin.fetchHome,
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
              _buildSection(
                context,
                title: l.restaurantInfo,
                icon: Icons.assignment_outlined,
                children: [
                  _buildDetailRow(context, 'ID', '${restaurant.id}'),
                  if (restaurant.ownerUser > 0)
                    _buildDetailRow(
                      context,
                      l.ownerUser,
                      '${restaurant.ownerUser}',
                    ),
                  _buildDetailRow(
                    context,
                    l.status,
                    restaurant.status.isNotEmpty
                        ? localizedRestaurantStatus(l, restaurant.status)
                        : l.notProvided,
                  ),
                  _buildDetailRow(
                    context,
                    l.active,
                    restaurant.isActive ? l.yes : l.no,
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
                      _fmtDateTime(restaurant.createdAt!),
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
              ],
            ),
          ),
        ],
      ),
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

  String _fmtDateTime(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final minute = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year} ${d.hour}:$minute';
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
