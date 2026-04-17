import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _appVersion = '1.0.2+3';
  static const String _releaseDate = '17 April 2026';

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.userProfile == null && !auth.profileLoading) {
      Future.microtask(() => auth.fetchProfile());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.profile,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),

            // ─── User Profile Card ────────────────────────────
            _buildProfileCard(auth, theme, l),
            const SizedBox(height: 16),

            // ─── Theme Section ────────────────────────────────
            _SectionCard(
              icon: Icons.palette_outlined,
              title: l.theme,
              child: Column(
                children: [
                  _ThemeOption(
                    label: l.systemDefault,
                    icon: Icons.settings_brightness_rounded,
                    selected: settings.themeMode == ThemeMode.system,
                    onTap: () => settings.setThemeMode(ThemeMode.system),
                  ),
                  _ThemeOption(
                    label: l.lightMode,
                    icon: Icons.light_mode_rounded,
                    selected: settings.themeMode == ThemeMode.light,
                    onTap: () => settings.setThemeMode(ThemeMode.light),
                  ),
                  _ThemeOption(
                    label: l.darkMode,
                    icon: Icons.dark_mode_rounded,
                    selected: settings.themeMode == ThemeMode.dark,
                    onTap: () => settings.setThemeMode(ThemeMode.dark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Language Section ─────────────────────────────
            _SectionCard(
              icon: Icons.translate_rounded,
              title: l.language,
              child: Column(
                children: [
                  _ThemeOption(
                    label: l.english,
                    icon: null,
                    trailing: 'EN',
                    selected: settings.locale.languageCode == 'en',
                    onTap: () => settings.setLocale(const Locale('en')),
                  ),
                  _ThemeOption(
                    label: l.arabic,
                    icon: null,
                    trailing: 'AR',
                    selected: settings.locale.languageCode == 'ar',
                    onTap: () => settings.setLocale(const Locale('ar')),
                  ),
                  _ThemeOption(
                    label: l.dutch,
                    icon: null,
                    trailing: 'NL',
                    selected: settings.locale.languageCode == 'nl',
                    onTap: () => settings.setLocale(const Locale('nl')),
                  ),
                  _ThemeOption(
                    label: l.french,
                    icon: null,
                    trailing: 'FR',
                    selected: settings.locale.languageCode == 'fr',
                    onTap: () => settings.setLocale(const Locale('fr')),
                  ),
                  _ThemeOption(
                    label: l.german,
                    icon: null,
                    trailing: 'DE',
                    selected: settings.locale.languageCode == 'de',
                    onTap: () => settings.setLocale(const Locale('de')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ─── Sign Out ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: OutlinedButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(l.signOut),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    AuthProvider auth,
    ThemeData theme,
    AppLocalizations l,
  ) {
    if (auth.profileLoading && auth.userProfile == null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: theme.dividerColor),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (auth.profileError != null && auth.userProfile == null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 8),
              Text(
                auth.profileError!,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => auth.fetchProfile(),
                child: Text(l.retry),
              ),
            ],
          ),
        ),
      );
    }

    final profile = auth.userProfile;
    if (profile == null) return const SizedBox.shrink();

    final name = profile['name'] as String? ?? '';
    final email = profile['email'] as String? ?? '';
    final phone = profile['phone'] as String? ?? '';
    final isVerified = profile['is_verified'] as bool? ?? false;
    final roles =
        (profile['roles'] as List<dynamic>?)
            ?.map((r) => r.toString())
            .toList() ??
        [];
    final createdAt = profile['created_at'] != null
        ? DateTime.tryParse(profile['created_at'])
        : null;

    final initials = name.isNotEmpty
        ? name
              .split(' ')
              .where((w) => w.isNotEmpty)
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join()
        : '?';

    final monthNames = [
      '',
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
    final joinedDate = createdAt != null
        ? '${monthNames[createdAt.month]} ${createdAt.day}, ${createdAt.year}'
        : null;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            // ── Avatar + Name + Verified badge ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name.isNotEmpty ? name : '—',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? AppColors.success.withValues(alpha: 0.08)
                          : AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVerified
                              ? Icons.verified_rounded
                              : Icons.info_outline_rounded,
                          size: 14,
                          color: isVerified
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isVerified ? l.verified : l.notVerified,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isVerified
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: theme.dividerColor, height: 1),

            // ── Detail rows ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  if (phone.isNotEmpty)
                    _profileRow(theme, Icons.phone_outlined, l.phone, phone),
                  if (roles.isNotEmpty)
                    _profileRow(
                      theme,
                      Icons.shield_outlined,
                      l.roles,
                      roles
                          .map(
                            (r) =>
                                r[0].toUpperCase() +
                                r.substring(1).toLowerCase(),
                          )
                          .join(', '),
                    ),
                  if (joinedDate != null)
                    _profileRow(
                      theme,
                      Icons.calendar_today_outlined,
                      l.memberSince,
                      joinedDate,
                    ),
                  _profileRow(
                    theme,
                    Icons.info_outline_rounded,
                    l.version,
                    _appVersion,
                  ),
                  _profileRow(
                    theme,
                    Icons.event_outlined,
                    l.releaseDate,
                    _releaseDate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _signOut(BuildContext context) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.signOut),
        content: Text(l.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SettingsProvider>().resetToDefaults();
              context.read<AuthProvider>().signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l.signOut),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: theme.dividerColor, height: 1),
            child,
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatefulWidget {
  final String label;
  final IconData? icon;
  final String? trailing;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    this.icon,
    this.trailing,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ThemeOption> createState() => _ThemeOptionState();
}

class _ThemeOptionState extends State<_ThemeOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: widget.selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : _hovered
              ? theme.colorScheme.onSurface.withValues(alpha: 0.03)
              : Colors.transparent,
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.selected
                      ? AppColors.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: widget.selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: widget.selected
                        ? AppColors.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (widget.trailing != null)
                Text(
                  widget.trailing!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.selected
                        ? AppColors.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              if (widget.trailing != null) const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.selected
                        ? AppColors.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    width: widget.selected ? 6 : 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
