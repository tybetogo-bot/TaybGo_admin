import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/home_response.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../management/reset_password_dialog.dart';
import '../support/create_support_ticket_dialog.dart';

class DriverProfileScreen extends StatefulWidget {
  final int driverId;
  final String driverName;
  final String driverPhone;

  const DriverProfileScreen({
    super.key,
    required this.driverId,
    required this.driverName,
    this.driverPhone = '',
  });

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  bool _vehicleSectionExpanded = false;
  bool _documentsSectionExpanded = false;
  bool _statusActionBusy = false;
  late final AdminProvider _admin;

  @override
  void initState() {
    super.initState();
    _admin = context.read<AdminProvider>();
    Future.microtask(_loadProfile);
  }

  @override
  void dispose() {
    Future.microtask(() {
      try {
        _admin.clearDriverProfile();
      } catch (_) {}
    });
    super.dispose();
  }

  Future<void> _loadProfile() {
    return _admin.fetchDriverProfile(
      widget.driverId,
      driverName: widget.driverName,
      driverPhone: widget.driverPhone,
    );
  }

  Future<void> _changeDriverStatus(
    DriverProfile profile, {
    required String status,
  }) async {
    if (_statusActionBusy) return;

    final l = AppLocalizations.of(context);
    final displayName = profile.name.isNotEmpty
        ? profile.name
        : widget.driverName;
    final isSuspending = status == 'SUSPENDED';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isSuspending ? l.suspendDriver : l.activateDriver),
        content: Text(
          isSuspending
              ? l.suspendDriverConfirm(displayName)
              : l.activateDriverConfirm(displayName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: isSuspending
                  ? AppColors.warning
                  : AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text(isSuspending ? l.suspend : l.activate),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _statusActionBusy = true);
    try {
      await context.read<AdminProvider>().updateDriverStatus(
        widget.driverId,
        status: status,
      );
      if (!mounted) return;
      _showSnack(
        context,
        isSuspending
            ? l.driverSuspended(displayName)
            : l.driverActivated(displayName),
        isSuspending ? AppColors.warning : AppColors.success,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(context, l.failed('$e'), AppColors.error);
    } finally {
      if (mounted) {
        setState(() => _statusActionBusy = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final reset = await showResetPasswordDialog(
      context,
      userId: widget.driverId,
    );
    if (!reset || !mounted) return;
    _showSnack(
      context,
      AppLocalizations.of(context).passwordResetSuccessfully,
      AppColors.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final admin = context.watch<AdminProvider>();
    final profile = admin.driverProfile;
    final loading = admin.driverProfileLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l.driver), centerTitle: false),
      body: loading && profile == null
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
          : profile == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
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
                  OutlinedButton(onPressed: _loadProfile, child: Text(l.retry)),
                ],
              ),
            )
          : Column(
              children: [
                if (loading) const LinearProgressIndicator(minHeight: 2),
                Expanded(child: _buildContent(context, profile, admin)),
              ],
            ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DriverProfile profile,
    AdminProvider admin,
  ) {
    final l = AppLocalizations.of(context);
    final contactPhone = profile.phone ?? widget.driverPhone;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(context, profile),
              if (_shouldShowStatusAction(profile)) ...[
                const SizedBox(height: 16),
                _buildActionsCard(context, profile),
              ],
              const SizedBox(height: 16),
              _buildSupportCard(context, profile),
              const SizedBox(height: 16),
              _buildSection(
                context,
                title: l.driverDetails,
                icon: Icons.assignment_outlined,
                children: [
                  _buildDetailRow(context, l.id, '${profile.id}'),
                  if (profile.createdAt != null)
                    _buildDetailRow(
                      context,
                      l.registeredDate,
                      _fmtDateTimeFull(l, profile.createdAt!),
                    ),
                  if (profile.locationUpdatedAt != null)
                    _buildDetailRow(
                      context,
                      l.lastUpdated,
                      _fmtDateTimeFull(l, profile.locationUpdatedAt!),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSection(
                context,
                title: l.contactInfo,
                icon: Icons.contact_phone_outlined,
                children: [
                  _buildPhoneRow(
                    context,
                    label: l.phone,
                    phone: contactPhone,
                    notProvidedText: l.notProvided,
                  ),
                  if (profile.email != null)
                    _buildDetailRow(context, l.email, profile.email!),
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
                      key: const Key('driver-reset-password'),
                      onPressed: _resetPassword,
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
              if (profile.isOnline != null || profile.hasLocation) ...[
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  title: l.location,
                  icon: Icons.location_on_outlined,
                  children: [
                    _buildDetailRow(
                      context,
                      l.location,
                      profile.hasLocation
                          ? '${profile.latitude}, ${profile.longitude}'
                          : l.noLocation,
                    ),
                    if (profile.hasLocation) ...[
                      const SizedBox(height: 10),
                      _buildLocationMapPreview(context, profile),
                    ],
                  ],
                ),
              ],
              if (profile.hasAddress) ...[
                const SizedBox(height: 16),
                _buildAddressSection(context, profile.address!),
              ],
              if (profile.hasServiceDetails) ...[
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  title: l.serviceTypes,
                  icon: Icons.miscellaneous_services_outlined,
                  children: [_buildServiceChips(context, profile, l)],
                ),
              ],
              if (profile.hasVehicleDetails) ...[
                const SizedBox(height: 16),
                _buildCollapsibleSection(
                  context,
                  title: l.vehicleDetails,
                  icon: Icons.directions_car_outlined,
                  expanded: _vehicleSectionExpanded,
                  onToggle: () => setState(
                    () => _vehicleSectionExpanded = !_vehicleSectionExpanded,
                  ),
                  children: _buildVehicleDetails(context, profile, l),
                ),
              ],
              if (profile.hasDocuments) ...[
                const SizedBox(height: 16),
                _buildCollapsibleSection(
                  context,
                  title: l.documents,
                  icon: Icons.folder_outlined,
                  expanded: _documentsSectionExpanded,
                  onToggle: () => setState(
                    () =>
                        _documentsSectionExpanded = !_documentsSectionExpanded,
                  ),
                  children: _buildDocumentsList(context, profile, l),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, DriverProfile profile) {
    final theme = Theme.of(context);
    final displayName = profile.name.isNotEmpty
        ? profile.name
        : widget.driverName;
    final statusColor = _statusColor(profile);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
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
                displayName
                    .split(' ')
                    .map((n) => n.isNotEmpty ? n[0] : '')
                    .take(2)
                    .join(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusText(AppLocalizations.of(context), profile),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, DriverProfile profile) {
    final l = AppLocalizations.of(context);
    final isSuspended = profile.status.toUpperCase() == 'SUSPENDED';

    return _buildSection(
      context,
      title: l.actions,
      icon: Icons.manage_accounts_outlined,
      children: [
        SizedBox(
          width: double.infinity,
          child: _statusActionBusy
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: () => _changeDriverStatus(
                    profile,
                    status: isSuspended ? 'APPROVED' : 'SUSPENDED',
                  ),
                  icon: Icon(
                    isSuspended
                        ? Icons.check_circle_outline
                        : Icons.block_rounded,
                    size: 18,
                  ),
                  label: Text(isSuspended ? l.activateDriver : l.suspendDriver),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isSuspended
                        ? AppColors.success
                        : AppColors.warning,
                    side: BorderSide(
                      color: isSuspended
                          ? AppColors.success
                          : AppColors.warning,
                    ),
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

  Widget _buildSupportCard(BuildContext context, DriverProfile profile) {
    final l = AppLocalizations.of(context);
    final canContact = profile.id > 0;
    return _buildSection(
      context,
      title: l.support,
      icon: Icons.support_agent_outlined,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('driver-create-support-ticket'),
            onPressed: canContact
                ? () => createSupportTicketFromContext(
                    context,
                    preset: SupportTicketComposerPreset.driver(
                      driverId: profile.id,
                      driverName: profile.name.isNotEmpty
                          ? profile.name
                          : widget.driverName,
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
                    letterSpacing: 0.3,
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

  Widget _buildCollapsibleSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool expanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
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
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: expanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [const SizedBox(height: 4), ...children],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
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
            width: 120,
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

  Widget _buildAddressSection(BuildContext context, DriverAddress address) {
    final l = AppLocalizations.of(context);
    final addressLine = address.displayLine.isNotEmpty
        ? address.displayLine
        : l.notProvided;

    return _buildSection(
      context,
      title: l.address,
      icon: Icons.home_outlined,
      children: [
        if (address.label.isNotEmpty)
          _buildDetailRow(context, l.label, address.label),
        _buildDetailRow(context, l.address, addressLine),
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

  Widget _buildPhoneRow(
    BuildContext context, {
    required String label,
    required String phone,
    required String notProvidedText,
  }) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final canCall = _dialablePhone(phone) != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    phone.isNotEmpty ? phone : notProvidedText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: canCall ? () => _callPhone(phone) : null,
                  icon: Icon(
                    Icons.call_outlined,
                    size: 18,
                    color: canCall
                        ? AppColors.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  visualDensity: VisualDensity.compact,
                  splashRadius: 18,
                  tooltip: l.call,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMapPreview(BuildContext context, DriverProfile profile) {
    final theme = Theme.of(context);
    final point = _locationPoint(profile);
    if (point == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 160,
          width: double.infinity,
          child: FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.coordinates(
                coordinates: [point],
                padding: const EdgeInsets.all(48),
                maxZoom: 15,
              ),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.taybgo.admin',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 34,
                    height: 34,
                    child: Center(
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  LatLng? _locationPoint(DriverProfile profile) {
    final lat = double.tryParse(profile.latitude ?? '');
    final lng = double.tryParse(profile.longitude ?? '');
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  Widget _buildServiceChips(
    BuildContext context,
    DriverProfile profile,
    AppLocalizations l,
  ) {
    final theme = Theme.of(context);
    final services = <_ServiceInfo>[
      _ServiceInfo(l.food, Icons.restaurant_outlined, profile.acceptsFood),
      _ServiceInfo(
        l.shipping,
        Icons.local_shipping_outlined,
        profile.acceptsShipping,
      ),
      _ServiceInfo(l.taxi, Icons.local_taxi_outlined, profile.acceptsTaxi),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: services.map((s) {
        final active = s.enabled == true;
        final inactive = s.enabled == false;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.08)
                : theme.colorScheme.onSurface.withValues(
                    alpha: inactive ? 0.04 : 0.02,
                  ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : theme.dividerColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                s.icon,
                size: 16,
                color: active
                    ? AppColors.primary
                    : theme.colorScheme.onSurface.withValues(
                        alpha: inactive ? 0.3 : 0.2,
                      ),
              ),
              const SizedBox(width: 6),
              Text(
                s.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: active
                      ? AppColors.primary
                      : theme.colorScheme.onSurface.withValues(
                          alpha: inactive ? 0.35 : 0.25,
                        ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                active
                    ? Icons.check_circle_rounded
                    : inactive
                    ? Icons.cancel_rounded
                    : Icons.help_outline_rounded,
                size: 14,
                color: active
                    ? AppColors.primary
                    : theme.colorScheme.onSurface.withValues(
                        alpha: inactive ? 0.2 : 0.15,
                      ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildVehicleDetails(
    BuildContext context,
    DriverProfile profile,
    AppLocalizations l,
  ) {
    final rows = <Widget>[];

    if (profile.vehicleType.isNotEmpty) {
      rows.add(
        _buildDetailRow(
          context,
          l.vehicleType,
          _vehicleLabel(l, profile.vehicleType),
        ),
      );
    }
    if (profile.carSize != null) {
      rows.add(_buildDetailRow(context, l.carSize, profile.carSize!));
    }
    if (profile.vehiclePlateNumber != null) {
      rows.add(
        _buildDetailRow(
          context,
          l.vehiclePlateNumber,
          profile.vehiclePlateNumber!,
        ),
      );
    }
    if (profile.vehicleColor != null) {
      rows.add(_buildDetailRow(context, l.vehicleColor, profile.vehicleColor!));
    }
    if (profile.vehicleMake != null) {
      rows.add(_buildDetailRow(context, l.vehicleMake, profile.vehicleMake!));
    }
    if (profile.vehicleModel != null) {
      rows.add(_buildDetailRow(context, l.vehicleModel, profile.vehicleModel!));
    }
    if (profile.vehicleYear != null) {
      rows.add(_buildDetailRow(context, l.vehicleYear, profile.vehicleYear!));
    }

    return rows;
  }

  List<Widget> _buildDocumentsList(
    BuildContext context,
    DriverProfile profile,
    AppLocalizations l,
  ) {
    final theme = Theme.of(context);
    final docs = profile.documentItems.isNotEmpty
        ? profile.documentItems
        : <DriverDocument>[
            if (profile.drivingLicense != null)
              DriverDocument(
                key: 'driving_license',
                label: l.drivingLicense,
                url: profile.drivingLicense,
              ),
            if (profile.idDocument != null)
              DriverDocument(
                key: 'id_document',
                label: l.idDocument,
                url: profile.idDocument,
              ),
            if (profile.otherDocuments != null)
              DriverDocument(
                key: 'other_documents',
                label: l.otherDocuments,
                url: profile.otherDocuments,
              ),
          ];

    if (docs.isEmpty) {
      return [
        Container(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.dividerColor,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Center(
            child: Text(
              l.noDocumentsUploaded,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      ];
    }

    return docs.map((doc) => _buildDocumentCard(context, doc, l)).toList();
  }

  Widget _buildDocumentCard(
    BuildContext context,
    DriverDocument doc,
    AppLocalizations l,
  ) {
    final theme = Theme.of(context);
    final hasUrl = doc.url != null;
    final icon = _documentIconForKey(doc.key);
    final label = _documentLabelForKey(l, doc);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (hasUrl)
                TextButton.icon(
                  onPressed: () => _openUrl(doc.url!),
                  icon: const Icon(Icons.open_in_new, size: 13),
                  label: Text(l.viewDocument),
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 11),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (!hasUrl)
            _buildMissingDocumentTile(theme, l)
          else if (_isImageUrl(doc.url!))
            GestureDetector(
              onTap: () => _showFullImage(context, doc.url!, label),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  doc.url!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.04,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stack) {
                    return _buildFileTile(
                      theme,
                      icon: Icons.broken_image_outlined,
                      title: l.couldNotLoadImage,
                      subtitle: label,
                    );
                  },
                ),
              ),
            )
          else
            _buildFileTile(
              theme,
              icon: _documentFileIconForUrl(doc.url!),
              title: l.previewUnavailable,
              subtitle: label,
              onTap: () => _openUrl(doc.url!),
            ),
        ],
      ),
    );
  }

  Widget _buildMissingDocumentTile(ThemeData theme, AppLocalizations l) {
    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Center(
        child: Text(
          l.notProvided,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }

  Widget _buildFileTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final tile = Container(
      height: 72,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.open_in_new,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
          ],
        ),
      ),
    );

    if (onTap == null) return tile;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: tile,
    );
  }

  IconData _documentIconForKey(String key) {
    switch (key) {
      case 'driving_license':
        return Icons.badge_outlined;
      case 'id_document':
        return Icons.credit_card_outlined;
      case 'health_insurance_document':
        return Icons.health_and_safety_outlined;
      case 'address_document':
        return Icons.home_work_outlined;
      case 'bank_document':
        return Icons.account_balance_outlined;
      case 'other_documents':
        return Icons.description_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String _documentLabelForKey(AppLocalizations l, DriverDocument doc) {
    switch (doc.key) {
      case 'driving_license':
        return l.drivingLicense;
      case 'id_document':
        return l.idDocument;
      case 'health_insurance_document':
        return l.healthInsuranceDocument;
      case 'address_document':
        return l.addressDocument;
      case 'bank_document':
        return l.bankDocument;
      case 'other_documents':
        return l.otherDocuments;
      default:
        return doc.label;
    }
  }

  IconData _documentFileIconForUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
      return Icons.description_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.webp') ||
        lower.contains('.gif') ||
        lower.contains('.bmp');
  }

  void _showFullImage(BuildContext context, String url, String title) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (_, error, stackTrace) =>
                          Center(child: Text(l.couldNotLoadImage)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callPhone(String phone) async {
    final dialable = _dialablePhone(phone);
    if (dialable == null) return;

    final uri = Uri(scheme: 'tel', path: dialable);
    await launchUrl(uri);
  }

  String? _dialablePhone(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return null;

    final normalized = trimmed.replaceAll(RegExp(r'[^\d+]'), '');
    if (normalized.isEmpty) return null;
    return normalized;
  }

  String _vehicleLabel(AppLocalizations l, String type) {
    switch (type.toUpperCase()) {
      case 'BIKE':
        return l.bike;
      case 'MOTOR':
      case 'MOTORCYCLE':
        return l.motorcycle;
      case 'CAR':
        return l.car;
      case 'VAN':
        return l.van;
      default:
        return type;
    }
  }

  String _fmtDateTimeFull(AppLocalizations l, DateTime d) {
    return l.formatDateTime(d);
  }

  String _statusText(AppLocalizations l, DriverProfile profile) {
    switch (profile.status.toUpperCase()) {
      case 'SUSPENDED':
      case 'REJECTED':
      case 'PENDING':
        return l.statusLabel(profile.status);
    }
    if (profile.isOnline != null) {
      return profile.isOnline == true ? l.online : l.offline;
    }
    return l.statusLabel(profile.status);
  }

  Color _statusColor(DriverProfile profile) {
    switch (profile.status.toUpperCase()) {
      case 'SUSPENDED':
        return AppColors.warning;
      case 'REJECTED':
        return AppColors.error;
      case 'PENDING':
        return AppColors.warning;
    }

    if (profile.isOnline != null) {
      return profile.isOnline == true ? AppColors.online : AppColors.offline;
    }
    return AppColors.warning;
  }

  bool _shouldShowStatusAction(DriverProfile profile) {
    final status = profile.status.toUpperCase();
    return profile.id != 0 && status != 'PENDING' && status != 'REJECTED';
  }

  void _showSnack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        width: 320,
      ),
    );
  }
}

class _ServiceInfo {
  final String label;
  final IconData icon;
  final bool? enabled;

  const _ServiceInfo(this.label, this.icon, this.enabled);
}
