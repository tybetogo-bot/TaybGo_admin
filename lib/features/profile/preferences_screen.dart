import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/version/app_release_history.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l.preferences),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                l.preferencesSubtitle,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.52),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _VersionControlLink(
              onTap: () => context.push('/profile/preferences/version-control'),
            ),
            const SizedBox(height: 16),
            _PreferenceCard(
              icon: Icons.palette_outlined,
              title: l.theme,
              options: [
                _PreferenceOption(
                  label: l.systemDefault,
                  icon: Icons.settings_brightness_rounded,
                  selected: settings.themeMode == ThemeMode.system,
                  onTap: () => settings.setThemeMode(ThemeMode.system),
                ),
                _PreferenceOption(
                  label: l.lightMode,
                  icon: Icons.light_mode_rounded,
                  selected: settings.themeMode == ThemeMode.light,
                  onTap: () => settings.setThemeMode(ThemeMode.light),
                ),
                _PreferenceOption(
                  label: l.darkMode,
                  icon: Icons.dark_mode_rounded,
                  selected: settings.themeMode == ThemeMode.dark,
                  onTap: () => settings.setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _PreferenceCard(
              icon: Icons.translate_rounded,
              title: l.language,
              options: [
                _PreferenceOption(
                  label: l.english,
                  code: 'EN',
                  selected: settings.locale.languageCode == 'en',
                  onTap: () => settings.setLocale(const Locale('en')),
                ),
                _PreferenceOption(
                  label: l.arabic,
                  code: 'AR',
                  selected: settings.locale.languageCode == 'ar',
                  onTap: () => settings.setLocale(const Locale('ar')),
                ),
                _PreferenceOption(
                  label: l.dutch,
                  code: 'NL',
                  selected: settings.locale.languageCode == 'nl',
                  onTap: () => settings.setLocale(const Locale('nl')),
                ),
                _PreferenceOption(
                  label: l.french,
                  code: 'FR',
                  selected: settings.locale.languageCode == 'fr',
                  onTap: () => settings.setLocale(const Locale('fr')),
                ),
                _PreferenceOption(
                  label: l.german,
                  code: 'DE',
                  selected: settings.locale.languageCode == 'de',
                  onTap: () => settings.setLocale(const Locale('de')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionControlLink extends StatelessWidget {
  final VoidCallback onTap;

  const _VersionControlLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = AppLocalizations.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.12),
                  scheme.primary.withValues(alpha: 0.035),
                ],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    size: 21,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.versionControl,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l.versionControlSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l.currentVersion,
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppReleaseHistory.current.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurface.withValues(alpha: 0.38),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_PreferenceOption> options;

  const _PreferenceCard({
    required this.icon,
    required this.title,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[];
    for (var i = 0; i < options.length; i++) {
      children.add(options[i]);
      if (i < options.length - 1) {
        children.add(Divider(color: theme.dividerColor, height: 1));
      }
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: theme.dividerColor, height: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _PreferenceOption extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? code;
  final bool selected;
  final VoidCallback onTap;

  const _PreferenceOption({
    required this.label,
    this.icon,
    this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? AppColors.primary
        : theme.colorScheme.onSurface;

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.065)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground.withValues(alpha: 0.75)),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: foreground,
                  ),
                ),
              ),
              if (code != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    code!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: selected
                          ? AppColors.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.22),
                    width: selected ? 6 : 1.5,
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
