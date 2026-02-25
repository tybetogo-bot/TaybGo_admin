import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/l10n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.settings,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 32),

            // ─── Theme Section ─────────────────────────────────
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

            // ─── Language Section ──────────────────────────────
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

            // ─── Sign Out ──────────────────────────────────────
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
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
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
                  Icon(icon, size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
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
                    fontWeight:
                        widget.selected ? FontWeight.w600 : FontWeight.w400,
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
