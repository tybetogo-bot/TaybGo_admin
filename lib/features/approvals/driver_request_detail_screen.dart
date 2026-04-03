import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/home_response.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class DriverRequestDetailScreen extends StatefulWidget {
  final int driverId;
  final String driverName;
  final String driverPhone;
  final bool showActions;
  final String? pageTitle;

  const DriverRequestDetailScreen({
    super.key,
    required this.driverId,
    required this.driverName,
    this.driverPhone = '',
    this.showActions = true,
    this.pageTitle,
  });

  @override
  State<DriverRequestDetailScreen> createState() =>
      _DriverRequestDetailScreenState();
}

class _DriverRequestDetailScreenState extends State<DriverRequestDetailScreen> {
  bool _actionBusy = false;
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

  Future<void> _verify(String status) async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    final admin = context.read<AdminProvider>();
    final l = AppLocalizations.of(context);
    final nav = Navigator.of(context);
    try {
      await admin.verifyDriver(widget.driverId, status: status);
      if (!mounted) return;
      final msg = status == 'APPROVED'
          ? l.driverApproved(widget.driverName)
          : l.driverRejected(widget.driverName);
      final color = status == 'APPROVED' ? AppColors.success : AppColors.error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontSize: 13)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          width: 300,
        ),
      );
      nav.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.failed('$e'), style: const TextStyle(fontSize: 13)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          width: 300,
        ),
      );
      setState(() => _actionBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final admin = context.watch<AdminProvider>();
    final profile = admin.driverProfile;
    final loading = admin.driverProfileLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pageTitle ?? (widget.showActions ? l.driverRequest : l.driver),
        ),
        centerTitle: false,
      ),
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
                Expanded(child: _buildContent(context, profile)),
              ],
            ),
    );
  }

  Widget _buildContent(BuildContext context, DriverProfile profile) {
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
              const SizedBox(height: 20),
              _buildSection(
                context,
                title: l.contactInfo,
                icon: Icons.contact_phone_outlined,
                children: [
                  _buildDetailRow(
                    context,
                    l.phone,
                    contactPhone.isNotEmpty ? contactPhone : l.notProvided,
                  ),
                  _buildDetailRow(
                    context,
                    l.email,
                    profile.email ?? l.notProvided,
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
                    if (profile.isOnline != null)
                      _buildDetailRow(
                        context,
                        l.status,
                        profile.isOnline == true ? l.online : l.offline,
                      ),
                    _buildDetailRow(
                      context,
                      l.location,
                      profile.hasLocation
                          ? '${profile.latitude}, ${profile.longitude}'
                          : l.noLocation,
                    ),
                  ],
                ),
              ],
              if (profile.hasExtendedDetails) ...[
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  title: l.vehicleType,
                  icon: Icons.directions_car_outlined,
                  children: [
                    _buildDetailRow(
                      context,
                      l.vehicleType,
                      profile.vehicleType.isNotEmpty
                          ? _vehicleLabel(l, profile.vehicleType)
                          : l.notProvided,
                    ),
                  ],
                ),
                if (profile.hasServiceDetails) ...[
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    title: l.serviceTypes,
                    icon: Icons.miscellaneous_services_outlined,
                    children: [_buildServiceChips(context, profile, l)],
                  ),
                ],
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  title: l.documents,
                  icon: Icons.folder_outlined,
                  children: _buildDocumentsList(context, profile, l),
                ),
              ],
              const SizedBox(height: 16),
              _buildSection(
                context,
                title: profile.submittedAt != null
                    ? l.submittedDate
                    : l.registeredDate,
                icon: Icons.calendar_today_outlined,
                children: [
                  if (profile.createdAt != null)
                    _buildDetailRow(
                      context,
                      l.registeredDate,
                      _fmtDateTime(profile.createdAt!),
                    ),
                  if (profile.submittedAt != null)
                    _buildDetailRow(
                      context,
                      l.submittedDate,
                      _fmtDateTime(profile.submittedAt!),
                    ),
                  if (profile.createdAt == null && profile.submittedAt == null)
                    _buildDetailRow(context, l.registeredDate, l.notProvided),
                ],
              ),
              if (widget.showActions) ...[
                const SizedBox(height: 32),
                if (_actionBusy)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => _verify('REJECTED'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: Text(l.decline),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => _verify('APPROVED'),
                            style: ElevatedButton.styleFrom(
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: Text(l.approve),
                          ),
                        ),
                      ),
                    ],
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 0.3,
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
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
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

  List<Widget> _buildDocumentsList(
    BuildContext context,
    DriverProfile profile,
    AppLocalizations l,
  ) {
    final docs = <_DocInfo>[
      _DocInfo(l.drivingLicense, Icons.badge_outlined, profile.drivingLicense),
      _DocInfo(l.idDocument, Icons.credit_card_outlined, profile.idDocument),
      _DocInfo(
        l.otherDocuments,
        Icons.description_outlined,
        profile.otherDocuments,
      ),
    ];

    return docs.map((doc) => _buildDocumentCard(context, doc, l)).toList();
  }

  Widget _buildDocumentCard(
    BuildContext context,
    _DocInfo doc,
    AppLocalizations l,
  ) {
    final theme = Theme.of(context);
    final hasUrl = doc.url != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                doc.icon,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
              Text(
                doc.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
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
          if (hasUrl)
            GestureDetector(
              onTap: () => _showFullImage(context, doc.url!, doc.label),
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
                    return Container(
                      height: 60,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.04,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Could not load image',
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
                    );
                  },
                ),
              ),
            )
          else
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
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String url, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Flexible(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Failed to load image')),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openUrl(url);
                  },
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Open in browser'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  String _vehicleLabel(AppLocalizations l, String type) {
    switch (type) {
      case 'BIKE':
        return l.bike;
      case 'MOTOR':
        return l.motorcycle;
      case 'CAR':
        return l.car;
      case 'VAN':
        return l.van;
      default:
        return type;
    }
  }

  String _fmtDateTime(DateTime d) {
    const m = [
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
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _statusText(AppLocalizations l, DriverProfile profile) {
    if (profile.isOnline != null) {
      return profile.isOnline == true ? l.online : l.offline;
    }
    return l.statusLabel(profile.status);
  }

  Color _statusColor(DriverProfile profile) {
    if (profile.isOnline != null) {
      return profile.isOnline == true ? AppColors.online : AppColors.offline;
    }

    switch (profile.status.toUpperCase()) {
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }
}

class _ServiceInfo {
  final String label;
  final IconData icon;
  final bool? enabled;
  const _ServiceInfo(this.label, this.icon, this.enabled);
}

class _DocInfo {
  final String label;
  final IconData icon;
  final String? url;
  const _DocInfo(this.label, this.icon, this.url);
}
