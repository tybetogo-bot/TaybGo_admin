import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/models/home_response.dart';
import '../../core/l10n/app_localizations.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  String _filter = 'all';
  String _search = '';
  bool _showMap = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    debugPrint('[DriversScreen] initState');
    final admin = context.read<AdminProvider>();
    if (admin.homeData == null) {
      debugPrint('[DriversScreen] No home data cached — fetching');
      Future.microtask(() => admin.fetchHome());
    } else {
      debugPrint('[DriversScreen] Using cached data — '
          '${admin.drivers.length} drivers');
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final all = admin.drivers;
    final driversCounts = admin.driversCount;
    final filtered = _apply(all);

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
                        l.drivers,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.driversScreenSub(driversCounts.total,
                            driversCounts.online, driversCounts.offline),
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
                    debugPrint('[DriversScreen] Manual refresh triggered');
                    admin.refreshHome();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: l.refresh,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status overview cards
            SizedBox(
              height: 80,
              child: Row(
                children: [
                  _MiniStat(
                    label: l.total,
                    value: '${driversCounts.total}',
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    label: l.online,
                    value: '${driversCounts.online}',
                    color: AppColors.online,
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    label: l.offline,
                    value: '${driversCounts.offline}',
                    color: AppColors.offline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Search + filter + view toggle row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  height: 40,
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: l.searchByNameOrPhone,
                      prefixIcon: Icon(Icons.search, size: 18,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.35)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                _filterChipBtn(l.all, 'all'),
                _filterChipBtn(l.online, 'online'),
                _filterChipBtn(l.offline, 'offline'),
                const SizedBox(width: 8),
                // Map / List toggle
                Container(
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _viewToggleBtn(
                        icon: Icons.list_rounded,
                        label: l.listView,
                        selected: !_showMap,
                        onTap: () => setState(() => _showMap = false),
                        isLeft: true,
                        theme: theme,
                      ),
                      _viewToggleBtn(
                        icon: Icons.map_rounded,
                        label: l.mapView,
                        selected: _showMap,
                        onTap: () => setState(() => _showMap = true),
                        isLeft: false,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _showMap
                  ? _buildMap(filtered, theme, l)
                  : LayoutBuilder(builder: (context, constraints) {
                      if (constraints.maxWidth < 620) {
                        return _buildCardList(filtered, theme, l);
                      }
                      return _buildTable(filtered, theme, l);
                    }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewToggleBtn({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isLeft,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(7) : Radius.zero,
            right: isLeft ? Radius.zero : const Radius.circular(7),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? AppColors.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? AppColors.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Map View ─────────────────────────────────────────────────

  Widget _buildMap(
      List<DriverWithLocation> filtered, ThemeData theme, AppLocalizations l) {
    // Collect drivers with valid coordinates
    final driversWithCoords = <_DriverLatLng>[];
    for (final d in filtered) {
      final lat = double.tryParse(d.latitude ?? '');
      final lng = double.tryParse(d.longitude ?? '');
      if (lat != null && lng != null) {
        driversWithCoords.add(_DriverLatLng(d, LatLng(lat, lng)));
      }
    }

    if (driversWithCoords.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 40,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Text(l.noLocationsAvailable,
                style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      );
    }

    // Compute bounds
    final bounds = LatLngBounds.fromPoints(
        driversWithCoords.map((d) => d.latLng).toList());

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50),
            maxZoom: 15,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.taybgo.admin',
          ),
          MarkerLayer(
            markers: driversWithCoords
                .map((d) => _buildMarker(d, theme))
                .toList(),
          ),
        ],
      ),
    );
  }

  Marker _buildMarker(_DriverLatLng driverLatLng, ThemeData theme) {
    final d = driverLatLng.driver;
    final color = d.isOnline ? AppColors.online : AppColors.offline;
    final initials = d.name
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join();

    return Marker(
      point: driverLatLng.latLng,
      width: 120,
      height: 50,
      child: GestureDetector(
        onTap: () => _showDriverPopup(d, driverLatLng.latLng, theme),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            // Arrow
            CustomPaint(
              size: const Size(10, 6),
              painter: _ArrowPainter(color: color),
            ),
            // Dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDriverPopup(
      DriverWithLocation d, LatLng point, ThemeData theme) {
    debugPrint('[DriversScreen] Selected driver: '
        'id=${d.id}, name="${d.name}", phone="${d.phone}", '
        'online=${d.isOnline}, lat=${d.latitude}, lng=${d.longitude}');
    final l = AppLocalizations.of(context);
    final statusColor = d.isOnline ? AppColors.online : AppColors.offline;
    final statusLabel = d.isOnline ? l.online : l.offline;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.primary.withValues(alpha: 0.04),
                    ]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      d.name
                          .split(' ')
                          .map((n) => n.isNotEmpty ? n[0] : '')
                          .take(2)
                          .join(),
                      style: TextStyle(
                        fontSize: 13,
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
                      Text(d.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          )),
                      const SizedBox(height: 2),
                      Text(d.phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(statusLabel,
                    style: TextStyle(fontSize: 13, color: statusColor)),
                const Spacer(),
                Icon(Icons.location_on_rounded,
                    size: 14,
                    color: AppColors.primary.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(
                  '${d.latitude}, ${d.longitude}',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── List Views ───────────────────────────────────────────────

  Widget _buildTable(
      List<DriverWithLocation> filtered, ThemeData theme, AppLocalizations l) {
    final admin = context.read<AdminProvider>();

    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              _Col(l.driver, flex: 3),
              _Col(l.status, flex: 2),
              _Col(l.phone, flex: 2),
              _Col(l.location, flex: 3),
            ],
          ),
        ),
        Divider(color: theme.dividerColor, height: 1),

        // Rows
        Expanded(
          child: filtered.isEmpty
              ? _emptyState(theme, l, admin.driversCount.total)
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) =>
                      _DriverTableRow(driver: filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildCardList(
      List<DriverWithLocation> filtered, ThemeData theme, AppLocalizations l) {
    final admin = context.read<AdminProvider>();
    if (filtered.isEmpty) {
      return _emptyState(theme, l, admin.driversCount.total);
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _DriverCard(driver: filtered[i]),
    );
  }

  Widget _emptyState(ThemeData theme, AppLocalizations l, int totalDrivers) {
    final hasDrivers = totalDrivers > 0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasDrivers
                ? Icons.location_off_rounded
                : Icons.search_off_rounded,
            size: 40,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          Text(
            hasDrivers
                ? l.allDriversOffline
                : l.noDriversMatchFilters,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          if (hasDrivers) ...[
            const SizedBox(height: 4),
            Text(
              l.driversOfflineHint(totalDrivers),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<DriverWithLocation> _apply(List<DriverWithLocation> drivers) {
    var r = drivers;
    if (_filter == 'online') {
      r = r.where((d) => d.isOnline).toList();
    } else if (_filter == 'offline') {
      r = r.where((d) => !d.isOnline).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      r = r
          .where((d) =>
              d.name.toLowerCase().contains(q) ||
              d.phone.contains(q))
          .toList();
    }
    debugPrint('[DriversScreen] Filter: $_filter, search: "$_search" '
        '=> ${r.length}/${drivers.length} drivers shown');
    return r;
  }

  Widget _filterChipBtn(String label, String value) {
    final selected = _filter == value;
    return FilterChip(
      selected: selected,
      showCheckmark: false,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      side: BorderSide(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.3)
            : Theme.of(context).dividerColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}

// ─── Helper: Driver + parsed LatLng ─────────────────────────────

class _DriverLatLng {
  final DriverWithLocation driver;
  final LatLng latLng;
  const _DriverLatLng(this.driver, this.latLng);
}

// ─── Arrow painter for marker ───────────────────────────────────

class _ArrowPainter extends CustomPainter {
  final Color color;
  _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) => old.color != color;
}

// ─── Mini Stat Card ──────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Column Header ───────────────────────────────────────────────

class _Col extends StatelessWidget {
  final String label;
  final int flex;
  const _Col(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Driver Table Row (wide screens) ─────────────────────────────

class _DriverTableRow extends StatefulWidget {
  final DriverWithLocation driver;
  const _DriverTableRow({required this.driver});

  @override
  State<_DriverTableRow> createState() => _DriverTableRowState();
}

class _DriverTableRowState extends State<_DriverTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.driver;
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final statusColor = d.isOnline ? AppColors.online : AppColors.offline;
    final statusLabel = d.isOnline ? l.online : l.offline;

    final hasLocation = d.latitude != null &&
        d.latitude!.isNotEmpty &&
        d.longitude != null &&
        d.longitude!.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            color: _hovered
                ? theme.colorScheme.onSurface.withValues(alpha: 0.02)
                : Colors.transparent,
            child: Row(
              children: [
                // Driver info
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
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
                            d.name
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
                        child: Text(
                          d.name,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),

                // Phone
                Expanded(
                  flex: 2,
                  child: Text(
                    d.phone,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.65),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Location
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Icon(
                        hasLocation
                            ? Icons.location_on_rounded
                            : Icons.location_off_rounded,
                        size: 14,
                        color: hasLocation
                            ? AppColors.primary.withValues(alpha: 0.6)
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          hasLocation
                              ? '${d.latitude}, ${d.longitude}'
                              : l.noLocation,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: theme.dividerColor, height: 1),
        ],
      ),
    );
  }
}

// ─── Driver Card (narrow screens) ────────────────────────────────

class _DriverCard extends StatelessWidget {
  final DriverWithLocation driver;
  const _DriverCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final d = driver;
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final statusColor = d.isOnline ? AppColors.online : AppColors.offline;
    final statusLabel = d.isOnline ? l.online : l.offline;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + status
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
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
                    d.name
                        .split(' ')
                        .map((n) => n.isNotEmpty ? n[0] : '')
                        .take(2)
                        .join(),
                    style: TextStyle(
                      fontSize: 13,
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
                      d.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      d.phone,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
