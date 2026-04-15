import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/l10n/app_localizations.dart';

class AdminShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AdminShell({super.key, required this.navigationShell});

  static const _icons = [
    _IconDef(Icons.space_dashboard_outlined, Icons.space_dashboard_rounded),
    _IconDef(Icons.how_to_reg_outlined, Icons.how_to_reg_rounded),
    _IconDef(Icons.local_shipping_outlined, Icons.local_shipping_rounded),
    _IconDef(Icons.forum_outlined, Icons.forum_rounded),
    _IconDef(Icons.person_outline, Icons.person_rounded),
  ];

  static List<String> _labels(AppLocalizations l) => [
    l.overview,
    l.approvals,
    l.drivers,
    l.support,
    l.profile,
  ];

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  @override
  void initState() {
    super.initState();
    debugPrint('[AdminShell] initState — starting polling service');
    final admin = context.read<AdminProvider>();
    Future.microtask(() => admin.startPolling());
  }

  @override
  void dispose() {
    debugPrint('[AdminShell] dispose — stopping polling service');
    // Stop polling when shell is disposed (e.g., on logout)
    // Use try-catch since context may not be available in dispose
    try {
      context.read<AdminProvider>().stopPolling();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = MediaQuery.of(context).size.width;
    final l = AppLocalizations.of(context);
    final labels = AdminShell._labels(l);

    if (w < 640) {
      return Scaffold(
        body: SafeArea(child: widget.navigationShell),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 64,
              child: Row(
                children: List.generate(AdminShell._icons.length, (i) {
                  final item = AdminShell._icons[i];
                  final selected = widget.navigationShell.currentIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selected ? item.activeIcon : item.icon,
                            size: 22,
                            color: selected
                                ? AppColors.primary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: selected
                                  ? AppColors.primary
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.4,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      );
    }

    final expanded = w >= 960;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _Sidebar(
              currentIndex: widget.navigationShell.currentIndex,
              expanded: expanded,
              onTap: _onTap,
            ),
            Expanded(child: widget.navigationShell),
          ],
        ),
      ),
    );
  }

  void _onTap(int i) {
    widget.navigationShell.goBranch(
      i,
      initialLocation: i == widget.navigationShell.currentIndex,
    );
  }
}

class _IconDef {
  final IconData icon;
  final IconData activeIcon;
  const _IconDef(this.icon, this.activeIcon);
}

class _Sidebar extends StatelessWidget {
  final int currentIndex;
  final bool expanded;
  final ValueChanged<int> onTap;

  const _Sidebar({
    required this.currentIndex,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final admin = context.watch<AdminProvider>();
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    final labels = AdminShell._labels(l);

    return Container(
      width: expanded ? 230 : 68,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFBFBFB),
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          // Logo area
          SizedBox(
            height: 68,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: expanded ? 20 : 0),
              child: Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/TaybGo_green.png',
                    height: expanded ? 36 : 30,
                  ),
                ],
              ),
            ),
          ),
          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: 12),

          // Nav items
          ...List.generate(AdminShell._icons.length, (i) {
            final item = AdminShell._icons[i];
            final selected = currentIndex == i;
            // Badge count for approvals
            int? badge;
            if (i == 1) {
              final count =
                  admin.pendingDriversTotal + admin.pendingRestaurantsTotal;
              if (count > 0) badge = count;
            }
            if (i == 3) {
              final count = admin.openTickets.length;
              if (count > 0) badge = count;
            }

            return _SidebarItem(
              icon: selected ? item.activeIcon : item.icon,
              label: labels[i],
              selected: selected,
              expanded: expanded,
              badge: badge,
              onTap: () => onTap(i),
            );
          }),

          const Spacer(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool expanded;
  final int? badge;
  final VoidCallback onTap;
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.expanded,
    this.badge,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = widget.selected
        ? AppColors.primary
        : _hovered
        ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
        : theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.expanded ? 12 : 10,
        vertical: 2,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 42,
            padding: EdgeInsets.symmetric(horizontal: widget.expanded ? 14 : 0),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : _hovered
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Row(
              mainAxisAlignment: widget.expanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 20, color: color),
                if (widget.expanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: widget.selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: color,
                      ),
                    ),
                  ),
                  if (widget.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.badge}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
