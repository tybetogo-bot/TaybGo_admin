import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/version/app_release_history.dart';
import '../../core/widgets/country_filter_dropdown.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _profileExpanded = false;

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
    final auth = context.watch<AuthProvider>();
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
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
            const SizedBox(height: 20),
            _buildProfileCard(auth, theme, l),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: const CountryFilterDropdown(),
            ),
            const SizedBox(height: 20),
            _buildQuickActions(theme, l),
            const SizedBox(height: 14),
            _buildSignOut(context, l),
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
      return _constrainedCard(
        child: const Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (auth.profileError != null && auth.userProfile == null) {
      return _constrainedCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 8),
              Text(
                auth.profileError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: auth.fetchProfile, child: Text(l.retry)),
            ],
          ),
        ),
      );
    }

    final profile = auth.userProfile;
    if (profile == null) return const SizedBox.shrink();

    final name = profile['name']?.toString() ?? '';
    final email = profile['email']?.toString() ?? '';
    final phone = profile['phone']?.toString() ?? '';
    final isVerified = profile['is_verified'] as bool? ?? false;
    final roles =
        (profile['roles'] as List<dynamic>?)
            ?.map((role) => role.toString())
            .where((role) => role.isNotEmpty)
            .toList() ??
        [];
    final createdAt = profile['created_at'] != null
        ? DateTime.tryParse(profile['created_at'].toString())
        : null;
    final initials = _initials(name);
    final joinedDate = createdAt == null
        ? null
        : l.formatReleaseDate(createdAt);
    final roleLabel = roles
        .map(
          (role) => role.isEmpty
              ? role
              : role[0].toUpperCase() + role.substring(1).toLowerCase(),
        )
        .join(', ');
    final statusColor = isVerified ? AppColors.success : AppColors.warning;

    return _constrainedCard(
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _profileExpanded = !_profileExpanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                child: Row(
                  children: [
                    _ProfileAvatar(initials: initials),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isNotEmpty ? name : '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 7),
                          _StatusPill(
                            label: isVerified ? l.verified : l.notVerified,
                            color: statusColor,
                            icon: isVerified
                                ? Icons.verified_rounded
                                : Icons.info_outline_rounded,
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message: _profileExpanded ? l.hideDetails : l.showDetails,
                      child: IconButton(
                        onPressed: () => setState(
                          () => _profileExpanded = !_profileExpanded,
                        ),
                        icon: AnimatedRotation(
                          turns: _profileExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _profileExpanded
                ? Column(
                    children: [
                      Divider(color: theme.dividerColor, height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final itemWidth = constraints.maxWidth >= 420
                                ? (constraints.maxWidth - 12) / 2
                                : constraints.maxWidth;
                            final details = <Widget>[
                              if (phone.isNotEmpty)
                                _ProfileDetail(
                                  width: itemWidth,
                                  icon: Icons.phone_outlined,
                                  label: l.phone,
                                  value: phone,
                                ),
                              if (roleLabel.isNotEmpty)
                                _ProfileDetail(
                                  width: itemWidth,
                                  icon: Icons.shield_outlined,
                                  label: l.roles,
                                  value: roleLabel,
                                ),
                              if (joinedDate != null)
                                _ProfileDetail(
                                  width: itemWidth,
                                  icon: Icons.calendar_today_outlined,
                                  label: l.memberSince,
                                  value: joinedDate,
                                ),
                              _ProfileDetail(
                                width: itemWidth,
                                icon: Icons.info_outline_rounded,
                                label: l.version,
                                value: AppReleaseHistory.current.label,
                              ),
                              _ProfileDetail(
                                width: itemWidth,
                                icon: Icons.event_outlined,
                                label: l.releaseDate,
                                value: l.formatReleaseDate(
                                  AppReleaseHistory.current.releasedAt,
                                ),
                              ),
                            ];
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: details,
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, AppLocalizations l) {
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
                  _ActionIcon(
                    icon: Icons.auto_awesome_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l.profileActions,
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
            _ProfileAction(
              icon: Icons.tune_outlined,
              title: l.pricingPolicies,
              subtitle: l.pricingPoliciesActionSubtitle,
              onTap: () => context.push('/profile/pricing-policies'),
            ),
            Divider(color: theme.dividerColor, height: 1),
            _ProfileAction(
              icon: Icons.settings_applications_outlined,
              title: 'Application settings',
              subtitle: 'Authentication, versions, updates, and legal links',
              onTap: () => context.push('/profile/app-settings'),
            ),
            Divider(color: theme.dividerColor, height: 1),
            _ProfileAction(
              icon: Icons.tune_rounded,
              title: l.preferences,
              subtitle: l.preferencesActionSubtitle,
              onTap: () => context.push('/profile/preferences'),
            ),
            Divider(color: theme.dividerColor, height: 1),
            _ProfileAction(
              icon: Icons.forum_outlined,
              title: l.support,
              subtitle: l.supportActionSubtitle,
              onTap: () => context.go('/support'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOut(BuildContext context, AppLocalizations l) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: () => _signOut(context),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: Text(l.signOut),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.error,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _constrainedCard({required Widget child}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Card(clipBehavior: Clip.antiAlias, child: child),
    );
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return '?';
    return name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
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

class _ProfileAvatar extends StatelessWidget {
  final String initials;

  const _ProfileAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;

  const _ProfileDetail({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.42,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _ActionIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _ActionIcon(icon: icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.48,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
