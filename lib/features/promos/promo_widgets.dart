import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/promo_banner.dart';
import '../../core/providers/promos_provider.dart';

Color queueColor(PromoQueue queue, BuildContext context) => switch (queue) {
  PromoQueue.pending =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFCB76)
        : const Color(0xFF9B6300),
  PromoQueue.live =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF6DD5A0)
        : const Color(0xFF087647),
  PromoQueue.inactive =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFAEBBFF)
        : const Color(0xFF5963AC),
  PromoQueue.rejected => Theme.of(context).colorScheme.error,
  PromoQueue.all => Theme.of(context).colorScheme.onSurface,
};
IconData queueIcon(PromoQueue queue) => switch (queue) {
  PromoQueue.pending => Icons.rate_review_outlined,
  PromoQueue.live => Icons.sensors_rounded,
  PromoQueue.inactive => Icons.pause_circle_outline_rounded,
  PromoQueue.rejected => Icons.edit_note_rounded,
  PromoQueue.all => Icons.grid_view_rounded,
};
String queueLabel(PromoQueue queue, AppLocalizations l) => switch (queue) {
  PromoQueue.pending => l.promoNeedsReview,
  PromoQueue.live => l.promoLive,
  PromoQueue.inactive => l.promoReady,
  PromoQueue.rejected => l.rejected,
  PromoQueue.all => l.promoAllBanners,
};
String queueHint(PromoQueue queue, AppLocalizations l) => switch (queue) {
  PromoQueue.pending => l.promoNeedsReviewHelp,
  PromoQueue.live => l.promoLiveHelp,
  PromoQueue.inactive => l.promoReadyHelp,
  PromoQueue.rejected => l.promoRejectedHelp,
  PromoQueue.all => l.promoAllBanners,
};
PromoQueue bannerQueue(PromoBanner p) => switch (p.status) {
  'PENDING' => PromoQueue.pending,
  'REJECTED' => PromoQueue.rejected,
  _ => p.isActive ? PromoQueue.live : PromoQueue.inactive,
};
String promoDate(BuildContext context, DateTime? date) {
  if (date == null) return AppLocalizations.of(context).promoUnknownDate;
  return MaterialLocalizations.of(context).formatCompactDate(date.toLocal());
}

class PromoStatusPill extends StatelessWidget {
  final PromoBanner promo;
  const PromoStatusPill({super.key, required this.promo});
  @override
  Widget build(BuildContext context) {
    final q = bannerQueue(promo),
        l = AppLocalizations.of(context),
        color = queueColor(q, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(queueIcon(q), size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              queueLabel(q, l),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PromoImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  const PromoImage({super.key, required this.url, this.fit = BoxFit.cover});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Image.network(
        url,
        fit: fit,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
        errorBuilder: (context, error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context).promoImageError,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PromoPreview extends StatelessWidget {
  final PromoBanner promo;
  final double height;
  const PromoPreview({super.key, required this.promo, this.height = 210});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PromoImage(url: promo.imageUrl),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xD9000000)],
              ),
            ),
          ),
          PositionedDirectional(
            start: 20,
            end: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.restaurantName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  promo.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if (promo.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    promo.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class PromoNotice extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final Color? color;
  const PromoNotice({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: c),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
