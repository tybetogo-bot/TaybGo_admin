import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/models/home_response.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/partner_search.dart';

class DriversScreen extends StatefulWidget {
  final String initialFilter;
  final bool showHeader;
  final bool showSearchToolbar;
  final String? searchQuery;

  const DriversScreen({
    super.key,
    this.initialFilter = 'all',
    this.showHeader = true,
    this.showSearchToolbar = true,
    this.searchQuery,
  });

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  late String _filter;
  String _search = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showMap = false;
  final MapController _mapController = MapController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _filter = _normalizeFilter(widget.initialFilter);
    debugPrint('[DriversScreen] initState');
    debugPrint('[DriversScreen] Loading direct admin driver collection');
    Future.microtask(_loadDrivers);
  }

  @override
  void didUpdateWidget(covariant DriversScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() => _filter = _normalizeFilter(widget.initialFilter));
      _loadDrivers();
    }
    if (oldWidget.searchQuery != widget.searchQuery) {
      _scheduleLoadDrivers();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDrivers() {
    final search = widget.searchQuery ?? _search;
    return context.read<AdminProvider>().fetchManagementDrivers(
      search: search,
      status: _filter == 'suspended' ? 'SUSPENDED' : null,
      isOnline: switch (_filter) {
        'online' => true,
        'offline' => false,
        _ => null,
      },
    );
  }

  void _scheduleLoadDrivers() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_loadDrivers()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final all = admin.managementDrivers;
    final suspendedCount = admin.managementDriversSummarySuspended;
    final onlineCount = admin.managementDriversSummaryOnline;
    final offlineCount = admin.managementDriversSummaryOffline;
    final totalCount = admin.managementDriversSummaryTotal;
    final filtered = _apply(all);
    final activeSearch = widget.searchQuery ?? _search;
    final hasActiveFilters = _filter != 'all' || activeSearch.trim().isNotEmpty;
    final locatedCount = filtered.where(_hasLocation).length;
    final locatedTotal = hasActiveFilters ? filtered.length : totalCount;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.fromLTRB(28, widget.showHeader ? 24 : 0, 28, 0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showHeader) ...[
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
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        debugPrint('[DriversScreen] Manual refresh triggered');
                        _loadDrivers();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      tooltip: l.refresh,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Status overview cards
              LayoutBuilder(
                builder: (context, c) {
                  const gap = 6.0;
                  final compact = c.maxWidth < 620;
                  final cardWidth = (c.maxWidth - gap * 3) / 4;
                  return Row(
                    children: [
                      _MiniStat(
                        width: cardWidth,
                        icon: Icons.groups_outlined,
                        label: l.total,
                        value: '$totalCount',
                        color: theme.colorScheme.onSurface,
                        selected: _filter == 'all',
                        compact: compact,
                        onTap: () => _setFilter('all'),
                      ),
                      const SizedBox(width: gap),
                      _MiniStat(
                        width: cardWidth,
                        icon: Icons.wifi_tethering_rounded,
                        label: l.online,
                        value: '$onlineCount',
                        color: AppColors.online,
                        selected: _filter == 'online',
                        compact: compact,
                        onTap: () => _setFilter('online'),
                      ),
                      const SizedBox(width: gap),
                      _MiniStat(
                        width: cardWidth,
                        icon: Icons.power_settings_new_rounded,
                        label: l.offline,
                        value: '$offlineCount',
                        color: AppColors.offline,
                        selected: _filter == 'offline',
                        compact: compact,
                        onTap: () => _setFilter('offline'),
                      ),
                      const SizedBox(width: gap),
                      _MiniStat(
                        width: cardWidth,
                        icon: Icons.block_outlined,
                        label: l.suspended,
                        value: '$suspendedCount',
                        color: AppColors.warning,
                        selected: _filter == 'suspended',
                        compact: compact,
                        onTap: () => _setFilter('suspended'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),

              // Search + view controls
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 620;
                    final controls = Row(
                      children: [
                        if (widget.showSearchToolbar) ...[
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) {
                                  setState(() => _search = v);
                                  _scheduleLoadDrivers();
                                },
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: l.searchByNameOrPhone,
                                  filled: true,
                                  fillColor: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.035),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(11),
                                    borderSide: BorderSide(
                                      color: theme.dividerColor.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(11),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 1.4,
                                    ),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    size: 18,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.35),
                                  ),
                                  suffixIcon: _search.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: l.clear,
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _search = '');
                                            _loadDrivers();
                                          },
                                          icon: const Icon(
                                            Icons.close,
                                            size: 17,
                                          ),
                                        ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        _viewToggle(theme, l, compact: compact),
                        if (widget.showSearchToolbar && hasActiveFilters)
                          IconButton(
                            onPressed: _clearFilters,
                            tooltip: l.clear,
                            icon: const Icon(Icons.filter_alt_off_outlined),
                          ),
                      ],
                    );
                    return widget.showSearchToolbar
                        ? controls
                        : Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: controls,
                          );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${filtered.length} ${l.drivers}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                  _MetaPill(
                    icon: Icons.location_on_outlined,
                    label:
                        '$locatedCount/$locatedTotal ${l.location.toLowerCase()}',
                    color: locatedCount == locatedTotal
                        ? AppColors.primary
                        : AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Content
              if (admin.managementDriversLoading && all.isEmpty)
                _LoadingPanel(theme: theme)
              else if (admin.managementDriversError != null && all.isEmpty)
                _ErrorPanel(
                  message: admin.managementDriversError!,
                  retryLabel: l.retry,
                  onRetry: _loadDrivers,
                  theme: theme,
                )
              else if (_showMap)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final mapHeight = constraints.maxWidth < 620
                        ? 300.0
                        : 420.0;
                    return SizedBox(
                      height: mapHeight,
                      child: _buildMap(filtered, theme, l),
                    );
                  },
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 620) {
                      return _buildCardList(filtered, theme, l);
                    }
                    return _buildTable(filtered, theme, l);
                  },
                ),
            ],
          ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  Widget _viewToggle(
    ThemeData theme,
    AppLocalizations l, {
    bool compact = false,
  }) {
    return Container(
      height: compact ? 38 : 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _viewToggleBtn(
            icon: Icons.list_rounded,
            label: compact ? '' : l.listView,
            selected: !_showMap,
            onTap: () => setState(() => _showMap = false),
            isLeft: true,
            theme: theme,
          ),
          _viewToggleBtn(
            icon: Icons.map_rounded,
            label: compact ? '' : l.mapView,
            selected: _showMap,
            onTap: () => setState(() => _showMap = true),
            isLeft: false,
            theme: theme,
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _search = '';
      _filter = 'all';
    });
    _loadDrivers();
  }

  // ─── Map View ─────────────────────────────────────────────────

  Widget _buildMap(
    List<DriverWithLocation> filtered,
    ThemeData theme,
    AppLocalizations l,
  ) {
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
            Icon(
              Icons.map_outlined,
              size: 40,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              l.noLocationsAvailable,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    // Compute bounds
    final bounds = LatLngBounds.fromPoints(
      driversWithCoords.map((d) => d.latLng).toList(),
    );

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
          // Keep vertical swipes available to the surrounding page scroll.
          // Pinch and double-tap zoom still work on the compact map.
          interactionOptions: const InteractionOptions(
            flags:
                InteractiveFlag.pinchZoom |
                InteractiveFlag.pinchMove |
                InteractiveFlag.doubleTapZoom,
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
    final color = d.status.toUpperCase() == 'SUSPENDED'
        ? AppColors.warning
        : (d.isOnline ? AppColors.online : AppColors.offline);
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
        onTap: () => _openDriverDetails(d),
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
                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDriverDetails(DriverWithLocation d) {
    debugPrint(
      '[DriversScreen] Selected driver: '
      'id=${d.id}, name="${d.name}", phone="${d.phone}", '
      'online=${d.isOnline}, lat=${d.latitude}, lng=${d.longitude}',
    );
    final queryParameters = <String, String>{
      'tab': 'drivers',
      'driver_filter': _filter,
      'name': d.name,
      'phone': d.phone,
    };
    final search = (widget.searchQuery ?? _search).trim();
    if (search.isNotEmpty) queryParameters['search'] = search;

    context.push(
      Uri(
        path: '/management/drivers/${d.id}',
        queryParameters: queryParameters,
      ).toString(),
    );
  }

  // ─── List Views ───────────────────────────────────────────────

  Widget _buildTable(
    List<DriverWithLocation> filtered,
    ThemeData theme,
    AppLocalizations l,
  ) {
    final admin = context.read<AdminProvider>();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
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

          if (filtered.isEmpty)
            SizedBox(
              height: 360,
              child: _emptyState(theme, l, admin.managementDriversTotal),
            )
          else
            ...filtered.map(
              (driver) => _DriverTableRow(
                driver: driver,
                onTap: () => _openDriverDetails(driver),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardList(
    List<DriverWithLocation> filtered,
    ThemeData theme,
    AppLocalizations l,
  ) {
    final admin = context.read<AdminProvider>();
    if (filtered.isEmpty) {
      return _emptyState(theme, l, admin.managementDriversTotal);
    }

    return Column(
      children: [
        ...filtered.map(
          (driver) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DriverCard(
              driver: driver,
              onTap: () => _openDriverDetails(driver),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState(ThemeData theme, AppLocalizations l, int totalDrivers) {
    final search = widget.searchQuery ?? _search;
    final showAllOfflineState =
        _filter == 'all' && totalDrivers > 0 && search.trim().isEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            showAllOfflineState
                ? Icons.location_off_rounded
                : Icons.search_off_rounded,
            size: 40,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          Text(
            showAllOfflineState ? l.allDriversOffline : l.noDriversMatchFilters,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          if (showAllOfflineState) ...[
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
      r = r.where((d) => !_isSuspended(d) && d.isOnline).toList();
    } else if (_filter == 'offline') {
      r = r.where((d) => !_isSuspended(d) && !d.isOnline).toList();
    } else if (_filter == 'suspended') {
      r = r.where(_isSuspended).toList();
    }
    final search = widget.searchQuery ?? _search;
    if (search.trim().isNotEmpty) {
      r = r
          .where(
            (d) => matchesPartnerSearch(search, [
              d.name,
              d.phone,
              d.email ?? '',
              d.vehiclePlateNumber ?? '',
            ]),
          )
          .toList();
    }
    debugPrint(
      '[DriversScreen] Filter: $_filter, search: "$search", '
      '${r.length}/${drivers.length} drivers shown',
    );
    return r;
  }

  bool _hasLocation(DriverWithLocation driver) {
    return double.tryParse(driver.latitude ?? '') != null &&
        double.tryParse(driver.longitude ?? '') != null;
  }

  bool _isSuspended(DriverWithLocation driver) {
    return driver.status.toUpperCase() == 'SUSPENDED';
  }

  void _setFilter(String filter) {
    setState(() => _filter = _normalizeFilter(filter));
    _loadDrivers();
  }

  String _normalizeFilter(String value) {
    const allowed = {'all', 'online', 'offline', 'suspended'};
    return allowed.contains(value) ? value : 'all';
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
  final double width;
  final IconData icon;
  final bool compact;
  final String label;
  final String value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _MiniStat({
    required this.width,
    required this.icon,
    this.compact = false,
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      height: compact ? 50 : 58,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.08)
                  : theme.cardTheme.color,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.45)
                    : theme.dividerColor,
              ),
            ),
            child: compact
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: color,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? color
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.45,
                                ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 27,
                        height: 27,
                        decoration: BoxDecoration(
                          color: color.withValues(
                            alpha: selected ? 0.14 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 14, color: color),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: color,
                                height: 1,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: selected
                                    ? color
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.45,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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

class _DriverLocationCell extends StatelessWidget {
  final DriverWithLocation driver;
  final bool compact;

  const _DriverLocationCell({required this.driver, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final hasLocation =
        double.tryParse(driver.latitude ?? '') != null &&
        double.tryParse(driver.longitude ?? '') != null;
    final updatedAt = driver.locationUpdatedAt?.toLocal();
    final stale =
        updatedAt != null &&
        DateTime.now().difference(updatedAt).inMinutes > 15;
    final locationColor = !hasLocation
        ? theme.colorScheme.onSurface.withValues(alpha: 0.25)
        : stale
        ? AppColors.warning
        : AppColors.primary;
    final addressLine = driver.address?.displayLine.isNotEmpty == true
        ? driver.address!.displayLine
        : driver.address?.label;
    final hasAddress = addressLine != null && addressLine.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            hasLocation
                ? (stale
                      ? Icons.location_searching_rounded
                      : Icons.location_on_rounded)
                : Icons.location_off_rounded,
            size: 14,
            color: locationColor.withValues(alpha: hasLocation ? 0.8 : 0.5),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasLocation
                    ? '${driver.latitude}, ${driver.longitude}'
                    : l.noLocation,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 11.5 : 12,
                  color: hasLocation
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.62)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              if (updatedAt != null) ...[
                const SizedBox(height: 3),
                Text(
                  '${l.updatedAt} ${_formatLocationTime(updatedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: stale ? FontWeight.w600 : FontWeight.w400,
                    color: stale
                        ? AppColors.warning
                        : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
              ],
              if (hasAddress) ...[
                SizedBox(height: compact ? 3 : 4),
                Row(
                  children: [
                    Icon(
                      Icons.home_outlined,
                      size: compact ? 12 : 13,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.35,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        addressLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 10.5 : 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

String _formatLocationTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}

// ─── Driver Table Row (wide screens) ─────────────────────────────

class _DriverTableRow extends StatefulWidget {
  final DriverWithLocation driver;
  final VoidCallback onTap;
  const _DriverTableRow({required this.driver, required this.onTap});

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

    final isSuspended = d.status.toUpperCase() == 'SUSPENDED';
    final statusColor = isSuspended
        ? AppColors.warning
        : (d.isOnline ? AppColors.online : AppColors.offline);
    final statusLabel = isSuspended
        ? l.suspended
        : (d.isOnline ? l.online : l.offline);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              color: _hovered
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.02)
                  : Colors.transparent,
              child: Row(
                children: [
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.name,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isSuspended) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    l.suspended,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      d.phone,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.65,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(flex: 3, child: _DriverLocationCell(driver: d)),
                ],
              ),
            ),
            Divider(color: theme.dividerColor, height: 1),
          ],
        ),
      ),
    );
  }
}

// ─── Driver Card (narrow screens) ────────────────────────────────

class _DriverCard extends StatelessWidget {
  final DriverWithLocation driver;
  final VoidCallback onTap;
  const _DriverCard({required this.driver, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = driver;
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final isSuspended = d.status.toUpperCase() == 'SUSPENDED';
    final statusColor = isSuspended
        ? AppColors.warning
        : (d.isOnline ? AppColors.online : AppColors.offline);
    final statusLabel = isSuspended
        ? l.suspended
        : (d.isOnline ? l.online : l.offline);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        d.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 14),
            _DriverLocationCell(driver: d, compact: true),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  final ThemeData theme;

  const _LoadingPanel({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: theme.dividerColor),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2.2)),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final ThemeData theme;

  const _ErrorPanel({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 34,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
