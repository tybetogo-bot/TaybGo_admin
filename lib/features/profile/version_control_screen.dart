import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/version/app_release_history.dart';

class VersionControlScreen extends StatelessWidget {
  const VersionControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l.versionControl),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CurrentReleaseCard(
                  release: AppReleaseHistory.current,
                  theme: theme,
                  l: l,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSmall,
                        ),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l.releaseHistory,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...AppReleaseHistory.releases.map(
                  (release) => _ReleaseAccordion(
                    release: release,
                    notes: _notesFor(release, l),
                    theme: theme,
                    l: l,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _notesFor(AppRelease release, AppLocalizations l) {
    return switch (release.label) {
      '1.0.7+8' => [
        l.release107Change1,
        l.release107Change2,
        l.release107Change3,
        l.release107Change4,
        l.release107Change5,
      ],
      '1.0.6+7' => [
        l.release106Change1,
        l.release106Change2,
        l.release106Change3,
      ],
      '1.0.5+6' => [
        l.release105Change1,
        l.release105Change2,
        l.release105Change3,
      ],
      '1.0.3+4' => [l.release103Change1, l.release103Change2],
      '1.0.2+3' => [l.release102Change1, l.release102Change2],
      '1.0.1+2' => [l.release101Change1],
      _ => [l.release100Change1],
    };
  }
}

class _CurrentReleaseCard extends StatelessWidget {
  final AppRelease release;
  final ThemeData theme;
  final AppLocalizations l;

  const _CurrentReleaseCard({
    required this.release,
    required this.theme,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.16),
            scheme.primary.withValues(alpha: 0.045),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Icon(
                  Icons.verified_rounded,
                  color: scheme.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.currentVersion,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.58),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      release.label,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  l.latestRelease,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: scheme.primary.withValues(alpha: 0.16), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.event_outlined,
                size: 16,
                color: scheme.onSurface.withValues(alpha: 0.52),
              ),
              const SizedBox(width: 7),
              Text(
                l.releasedOn(l.formatReleaseDate(release.releasedAt)),
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l.versionControlSubtitle,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReleaseAccordion extends StatefulWidget {
  final AppRelease release;
  final List<String> notes;
  final ThemeData theme;
  final AppLocalizations l;

  const _ReleaseAccordion({
    required this.release,
    required this.notes,
    required this.theme,
    required this.l,
  });

  @override
  State<_ReleaseAccordion> createState() => _ReleaseAccordionState();
}

class _ReleaseAccordionState extends State<_ReleaseAccordion> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = widget.theme.colorScheme;
    final release = widget.release;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: widget.theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(
            color: release.isCurrent
                ? scheme.primary.withValues(alpha: 0.3)
                : widget.theme.dividerColor,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: release.isCurrent
                              ? scheme.primary.withValues(alpha: 0.12)
                              : scheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSmall,
                          ),
                        ),
                        child: Icon(
                          release.isCurrent
                              ? Icons.new_releases_outlined
                              : Icons.history_toggle_off_rounded,
                          size: 18,
                          color: release.isCurrent
                              ? scheme.primary
                              : scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                release.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.l.releasedOn(
                                widget.l.formatReleaseDate(release.releasedAt),
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurface.withValues(alpha: 0.48),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (release.isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull,
                            ),
                          ),
                          child: Text(
                            widget.l.latestRelease,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 21,
                          color: scheme.onSurface.withValues(alpha: 0.42),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: _isExpanded
                      ? Column(
                          children: [
                            Divider(
                              color: widget.theme.dividerColor,
                              height: 1,
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                13,
                                16,
                                12,
                              ),
                              child: Column(
                                children: [
                                  for (var i = 0; i < widget.notes.length; i++)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom: i == widget.notes.length - 1
                                            ? 0
                                            : 9,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 16,
                                            color: release.isCurrent
                                                ? scheme.primary
                                                : scheme.onSurface.withValues(
                                                    alpha: 0.38,
                                                  ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              widget.notes[i],
                                              style: TextStyle(
                                                fontSize: 12,
                                                height: 1.35,
                                                color: scheme.onSurface
                                                    .withValues(alpha: 0.68),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
