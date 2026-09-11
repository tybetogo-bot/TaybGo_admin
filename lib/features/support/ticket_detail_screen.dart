import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/models/support_ticket.dart';
import '../../core/l10n/app_localizations.dart';

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _replyCtrl = TextEditingController();
  bool _sending = false;
  bool _detailsExpanded = false;
  String? _restaurantName;
  late final AdminProvider _admin;

  @override
  void initState() {
    super.initState();
    _admin = context.read<AdminProvider>();
    _admin.stopSupportPolling();
    if (_admin.selectedTicket?.id != widget.ticketId) {
      _admin.clearSelectedTicket();
    }
    Future.microtask(_refreshTicket);
  }

  Future<void> _refreshTicket() async {
    _admin.stopSupportPolling();
    await _admin.fetchTicketDetail(widget.ticketId);
    if (!mounted) return;

    if (_admin.selectedTicket?.id == widget.ticketId) {
      _admin.startSupportPolling(ticketId: widget.ticketId);
      _loadRestaurantName();
    }
  }

  Future<void> _loadRestaurantName() async {
    final admin = context.read<AdminProvider>();
    final restaurantId = admin.selectedTicket?.restaurant;
    if (restaurantId == null) return;

    // Already have name from ticket API
    if (admin.selectedTicket?.restaurantName != null) {
      setState(() => _restaurantName = admin.selectedTicket!.restaurantName);
      return;
    }

    try {
      final apiService = context.read<AdminProvider>().apiService;
      final data = await apiService.getRestaurant(restaurantId);
      if (mounted) {
        setState(() => _restaurantName = data['name'] as String?);
      }
    } catch (_) {
      // Fallback: just show ID
    }
  }

  @override
  void dispose() {
    // The parent SupportScreen stays mounted for nested ticket routes. Resume
    // its list polling when this detail route is popped.
    _admin.startSupportPolling();
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final admin = context.watch<AdminProvider>();
    final l = AppLocalizations.of(context);
    final t = admin.selectedTicket;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            admin.clearSelectedTicket();
            context.pop();
          },
        ),
        title: t != null
            ? Text(
                '#${t.id}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontFamily: 'monospace',
                ),
              )
            : Text(
                l.ticketDetails,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
        titleSpacing: 0,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            onPressed: admin.ticketDetailLoading
                ? null
                : () {
                    debugPrint(
                      '[TicketDetailScreen] Manual refresh triggered '
                      'for ticket #${widget.ticketId}',
                    );
                    _refreshTicket();
                  },
            icon: admin.ticketDetailLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 20),
            tooltip: l.refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context, admin, t, theme, l),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AdminProvider admin,
    SupportTicket? t,
    ThemeData theme,
    AppLocalizations l,
  ) {
    if (admin.ticketDetailLoading && t == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (t == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              admin.ticketsError ?? l.connectionError,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _refreshTicket, child: Text(l.retry)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeader(t, theme, l),
              _buildDetails(t, theme, l),
              const SizedBox(height: 8),
              _buildConversation(t, theme, l),
              const SizedBox(height: 20),
            ],
          ),
        ),
        if (!t.isClosed) _buildReplyArea(t, theme, l),
      ],
    );
  }

  // ─── Header: subject + status badges ───────────────────────────

  Widget _buildHeader(SupportTicket t, ThemeData theme, AppLocalizations l) {
    final statusColor = _statusColor(t.status);
    final statusLabel = _statusLabelL10n(t.status, l);
    final priorityColor = _priorityColor(t.priority);
    final priorityLabel = _priorityLabelL10n(t.priority, l);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.subject,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _badge(statusLabel, statusColor),
              _badge(priorityLabel, priorityColor),
              _outlineBadge(t.category, theme),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Details: collapsible key-value section ────────────────────

  Widget _buildDetails(SupportTicket t, ThemeData theme, AppLocalizations l) {
    final restaurantDisplay =
        _restaurantName ??
        t.restaurantName ??
        (t.restaurant != null ? '#${t.restaurant}' : null);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _detailsExpanded = !_detailsExpanded),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l.requester,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 2,
                    child: Text(
                      t.requesterName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _detailsExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _divider(theme),
                  if (restaurantDisplay != null) ...[
                    _detailRow(
                      Icons.restaurant_outlined,
                      l.relatedRestaurant,
                      restaurantDisplay,
                      theme: theme,
                    ),
                    _divider(theme),
                  ],
                  if (t.driver != null) ...[
                    _detailRow(
                      Icons.local_shipping_outlined,
                      l.relatedDriver,
                      t.driverName ?? '#${t.driver}',
                      theme: theme,
                    ),
                    _divider(theme),
                  ],
                  if (t.order != null) ...[
                    _detailRow(
                      Icons.receipt_long_outlined,
                      l.relatedOrder,
                      '#${t.order}',
                      theme: theme,
                    ),
                    _divider(theme),
                  ],
                  if (t.assignedTo != null) ...[
                    _detailRow(
                      Icons.support_agent_rounded,
                      l.assignedTo,
                      t.assignedToName ?? '#${t.assignedTo}',
                      theme: theme,
                      valueColor: AppColors.primary,
                    ),
                    _divider(theme),
                  ],
                  _detailRow(
                    Icons.access_time_outlined,
                    l.created,
                    _formatDate(t.createdAt),
                    theme: theme,
                  ),
                  if (t.closedAt != null) ...[
                    _divider(theme),
                    _detailRow(
                      Icons.check_circle_outline,
                      l.closedAt,
                      _formatDate(t.closedAt!),
                      theme: theme,
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: _detailsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    required ThemeData theme,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color:
                    valueColor ??
                    theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ThemeData theme) =>
      Divider(color: theme.dividerColor.withValues(alpha: 0.5), height: 1);

  // ─── Conversation ──────────────────────────────────────────────

  Widget _buildConversation(
    SupportTicket t,
    ThemeData theme,
    AppLocalizations l,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Text(
            '${l.conversation} (${t.messages.length})',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        if (t.messages.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Center(
              child: Text(
                l.noMessages(t.id),
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
          )
        else
          ...t.messages.map((m) => _MessageBubble(message: m)),
      ],
    );
  }

  // ─── Reply area ────────────────────────────────────────────────

  Widget _buildReplyArea(SupportTicket t, ThemeData theme, AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _replyCtrl,
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: l.writeReply,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _sendReply,
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(l.reply),
                    style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                if (t.isOpen || t.isInProgress)
                  _ActionBtn(
                    label: l.markResolved,
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                    onPressed: () => _updateStatus(t.id, 'RESOLVED'),
                  ),
                _ActionBtn(
                  label: l.close,
                  icon: Icons.close_rounded,
                  color: AppColors.error,
                  onPressed: () => _updateStatus(t.id, 'CLOSED'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _outlineBadge(String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$day/$month/${d.year} $hour:$min';
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;

    final admin = context.read<AdminProvider>();
    final ticketId = admin.selectedTicket?.id;
    if (ticketId == null) return;

    final l = AppLocalizations.of(context);
    setState(() => _sending = true);
    try {
      await admin.addTicketReply(ticketId, text);
      _replyCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.failedToSend('$e'))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _updateStatus(int ticketId, String status) async {
    final admin = context.read<AdminProvider>();
    final l = AppLocalizations.of(context);
    try {
      await admin.updateTicketStatus(ticketId, status);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.failedToUpdate('$e'))));
      }
    }
  }
}

// ─── Role colors ─────────────────────────────────────────────────

const _adminColor = AppColors.primary;
const _sellerColor = Color(0xFFFF8F00); // amber
const _customerColor = AppColors.info;

Color _roleColor(TicketMessage m) {
  if (m.isAdmin) return _adminColor;
  if (m.isSeller) return _sellerColor;
  return _customerColor;
}

IconData _roleIcon(TicketMessage m) {
  if (m.isAdmin) return Icons.support_agent_rounded;
  if (m.isSeller) return Icons.storefront_rounded;
  return Icons.person_rounded;
}

// ─── Message Bubble ───────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final TicketMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = message.isAdmin;
    final color = _roleColor(message);

    return Padding(
      padding: EdgeInsets.fromLTRB(isAdmin ? 48 : 20, 6, isAdmin ? 20 : 48, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isAdmin
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isAdmin) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_roleIcon(message), size: 15, color: color),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: color.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          message.authorName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            message.authorRole,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _fmtTime(message.createdAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message.body,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  if (message.attachments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: message.attachments.map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.05,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attach_file_rounded,
                                size: 12,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 160,
                                ),
                                child: Text(
                                  a.mimeType,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _adminColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                size: 15,
                color: _adminColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtTime(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$min';
  }
}

// ─── Action Button ────────────────────────────────────────────────

class _ActionBtn extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final Future<void> Function() onPressed;

  const _ActionBtn({
    required this.label,
    this.icon,
    this.color,
    required this.onPressed,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    if (widget.icon != null && widget.color != null) {
      return OutlinedButton.icon(
        onPressed: _busy ? null : _run,
        icon: _busy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(widget.icon, size: 14),
        label: Text(widget.label),
        style: OutlinedButton.styleFrom(
          foregroundColor: widget.color,
          side: BorderSide(color: widget.color!),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
      );
    }

    return OutlinedButton(
      onPressed: _busy ? null : _run,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      child: _busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(widget.label),
    );
  }

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

// ─── Helpers ──────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status) {
    case 'OPEN':
      return AppColors.info;
    case 'IN_PROGRESS':
      return AppColors.warning;
    case 'RESOLVED':
      return AppColors.success;
    case 'CLOSED':
      return AppColors.offline;
    default:
      return AppColors.info;
  }
}

String _statusLabelL10n(String status, AppLocalizations l) {
  switch (status) {
    case 'OPEN':
      return l.open;
    case 'IN_PROGRESS':
      return l.inProgress;
    case 'RESOLVED':
      return l.resolved;
    case 'CLOSED':
      return l.closed;
    default:
      return status;
  }
}

Color _priorityColor(String priority) {
  switch (priority) {
    case 'LOW':
      return AppColors.offline;
    case 'MEDIUM':
      return AppColors.info;
    case 'HIGH':
      return AppColors.warning;
    case 'URGENT':
      return AppColors.error;
    default:
      return AppColors.offline;
  }
}

String _priorityLabelL10n(String priority, AppLocalizations l) {
  switch (priority) {
    case 'LOW':
      return l.low;
    case 'MEDIUM':
      return l.medium;
    case 'HIGH':
      return l.high;
    case 'URGENT':
      return l.urgent;
    default:
      return priority;
  }
}
