import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/promo_banner.dart';
import '../../core/providers/promos_provider.dart';
import '../../core/providers/country_filter_provider.dart';
import 'promo_widgets.dart';
import 'promo_filters.dart';
import 'promo_review.dart';

class PromosScreen extends StatefulWidget {
  final bool showBackButton;
  const PromosScreen({super.key, this.showBackButton = false});
  @override
  State<PromosScreen> createState() => _PromosScreenState();
}

class _PromosScreenState extends State<PromosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PromosProvider>().refresh();
    });
  }

  Future<void> _review(PromoBanner promo, {String? action}) async {
    final p = context.read<PromosProvider>();
    final wide = MediaQuery.sizeOf(context).width >= 900;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: AppLocalizations.of(context).promoReview,
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (context, animation, secondary, child) =>
          SlideTransition(
            position:
                Tween<Offset>(
                  begin: Offset(
                    wide
                        ? (Directionality.of(context) == TextDirection.rtl
                              ? -0.12
                              : 0.12)
                        : 0,
                    wide ? 0 : 0.08,
                  ),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          ),
      pageBuilder: (_, animation, secondary) => ChangeNotifierProvider.value(
        value: p,
        child: PromoReview(id: promo.id, initialAction: action),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        p = context.watch<PromosProvider>(),
        country = context.watch<CountryFilterProvider>();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          final mobile = box.maxWidth < 600, padding = mobile ? 16.0 : 32.0;
          return RefreshIndicator(
            onRefresh: p.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(padding, 28, padding, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (widget.showBackButton) ...[
                              IconButton(
                                tooltip: MaterialLocalizations.of(
                                  context,
                                ).backButtonTooltip,
                                onPressed: () => context.go('/profile'),
                                icon: const BackButtonIcon(),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.09),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.campaign_outlined,
                                color: scheme.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Text(
                              l.promoDiscovery,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.6,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            IconButton.outlined(
                              tooltip: l.promoRefreshHint,
                              onPressed: p.loading || p.mutating
                                  ? null
                                  : p.refresh,
                              icon: const Icon(Icons.refresh_rounded, size: 19),
                            ),
                          ],
                        ),
                        const SizedBox(height: 17),
                        Text(
                          l.promoWorkspace,
                          style: TextStyle(
                            fontSize: mobile ? 27 : 33,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.promoWorkspaceHelp,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, grid) {
                            final columns = grid.maxWidth >= 800 ? 4 : 2;
                            final width =
                                (grid.maxWidth - (columns - 1) * 10) / columns;
                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final q in PromoQueue.values.where(
                                  (q) => q != PromoQueue.all,
                                ))
                                  SizedBox(
                                    width: width,
                                    child: _QueueTile(
                                      compact: grid.maxWidth < 600,
                                      queue: q,
                                      count: p.counts[q],
                                      selected: p.queue == q,
                                      loading: p.countsLoading,
                                      disabled: p.mutating,
                                      onTap: () => p.selectQueue(q),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        if (p.countsFailed)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Text(
                                  l.promoCountError,
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                                TextButton(
                                  onPressed: p.loadCounts,
                                  child: Text(l.retry),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l.promoQueue,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: p.mutating
                                  ? null
                                  : () => p.selectQueue(PromoQueue.all),
                              child: Text(l.promoAllBanners),
                            ),
                            const SizedBox(width: 4),
                            Badge(
                              isLabelVisible:
                                  p.city.isNotEmpty ||
                                  p.restaurantId != null ||
                                  country.selectedCountryId != null,
                              child: OutlinedButton.icon(
                                onPressed: p.mutating
                                    ? null
                                    : () => showPromoFilters(context, p),
                                icon: const Icon(Icons.tune_rounded, size: 17),
                                label: Text(l.promoFilters),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _ScopeLabel(
                              icon: Icons.public_outlined,
                              text:
                                  country.selectedCountry?.name ??
                                  l.allCountries,
                              onTap: () => showPromoFilters(context, p),
                            ),
                            if (p.city.isNotEmpty)
                              InputChip(
                                label: Text(p.city),
                                onDeleted: () => p.applyScope(
                                  city: '',
                                  restaurantId: p.restaurantId,
                                  restaurantName: p.restaurantName,
                                ),
                              ),
                            if (p.restaurantId != null)
                              InputChip(
                                label: Text(
                                  p.restaurantName ?? '#${p.restaurantId}',
                                ),
                                onDeleted: () => p.applyScope(city: p.city),
                              ),
                            _ScopeLabel(
                              icon: queueIcon(p.queue),
                              text: queueLabel(p.queue, l),
                            ),
                            if (!p.loading && p.error == null)
                              Text(
                                '· ${p.total}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
                if (p.loading)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    sliver: const SliverToBoxAdapter(
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  ),
                if (p.error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: l.promosLoadError,
                      body: p.error == 'promosLoadError' ? '' : p.error!,
                      action: l.retry,
                      onAction: p.refresh,
                    ),
                  )
                else if (!p.loading && p.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      icon: Icons.inbox_outlined,
                      title: l.promoNoResults,
                      body: l.promoNoQueueHelp,
                      action: l.promoAllBanners,
                      onAction: () => p.selectQueue(PromoQueue.all),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.crossAxisExtent >= 1050
                            ? 3
                            : constraints.crossAxisExtent >= 620
                            ? 2
                            : 1;
                        return SliverGrid(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final promo = p.items[index];
                            return _BannerCard(
                              promo: promo,
                              onOpen: () => _review(promo),
                              onReview: () => _review(
                                promo,
                                action: promo.status == 'PENDING'
                                    ? 'approve'
                                    : null,
                              ),
                            );
                          }, childCount: p.items.length),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisExtent: 380,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                        );
                      },
                    ),
                  ),
                if (!p.loading && p.error == null && p.items.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(padding, 18, padding, 28),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Text(
                            '${p.items.length} / ${p.total}',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          IconButton.outlined(
                            tooltip: l.previousPage,
                            onPressed: p.page > 1 && !p.mutating
                                ? () => p.load(pageNumber: p.page - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '${p.page}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton.outlined(
                            tooltip: l.nextPage,
                            onPressed: p.hasNext && !p.mutating
                                ? () => p.load(pageNumber: p.page + 1)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (p.loading && p.items.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.all(padding),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        height: 230,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  final PromoQueue queue;
  final int? count;
  final bool selected, loading, disabled;
  final bool compact;
  final VoidCallback onTap;
  const _QueueTile({
    required this.queue,
    this.compact = false,
    required this.count,
    required this.selected,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        color = queueColor(queue, context),
        scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? color.withValues(alpha: 0.08) : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected
                ? color.withValues(alpha: 0.6)
                : scheme.outline.withValues(alpha: 0.35),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(queueIcon(queue), color: color, size: 20),
                    const Spacer(),
                    if (selected)
                      Icon(Icons.check_circle_rounded, size: 16, color: color),
                  ],
                ),
                SizedBox(height: compact ? 6 : 14),
                Text(
                  loading ? '—' : count?.toString() ?? '—',
                  style: TextStyle(
                    fontSize: compact ? 22 : 28,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  queueLabel(queue, l),
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 5),
                  Text(
                    queueHint(queue, l),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: scheme.onSurfaceVariant,
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

class _ScopeLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  const _ScopeLabel({required this.icon, required this.text, this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _BannerCard extends StatelessWidget {
  final PromoBanner promo;
  final VoidCallback onOpen, onReview;
  const _BannerCard({
    required this.promo,
    required this.onOpen,
    required this.onReview,
  });
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PromoImage(url: promo.imageUrl),
                  PositionedDirectional(
                    top: 12,
                    end: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.layers_outlined,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${promo.priority}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        promo.restaurantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  promo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                PromoStatusPill(promo: promo),
                const SizedBox(height: 12),
                Text(
                  promoDate(context, promo.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onOpen,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 38),
                        ),
                        child: Text(
                          l.promoViewDetails,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    if (promo.status == 'PENDING') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: onReview,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 38),
                          ),
                          child: Text(
                            l.promoReview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, body, action;
  final VoidCallback onAction;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.07),
          ),
          child: Icon(
            icon,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onAction, child: Text(action)),
      ],
    ),
  );
}
