import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/models/support_ticket.dart';
import '../../core/l10n/app_localizations.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String _filter = 'all';
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    debugPrint('[SupportScreen] initState — loading tickets');
    final admin = context.read<AdminProvider>();
    Future.microtask(() => admin.fetchTickets());
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final tickets = _applyFilter(admin.tickets);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.support,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.supportSub(
                          admin.openTickets.length,
                          admin.inProgressTickets.length,
                          admin.resolvedTickets.length,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    debugPrint('[SupportScreen] Manual refresh triggered');
                    admin.fetchTickets();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: l.refresh,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filter tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _tab(l.all, 'all', admin.tickets.length),
                  _tab(l.open, 'open', admin.openTickets.length),
                  _tab(l.inProgress, 'inProgress',
                      admin.inProgressTickets.length),
                  _tab(l.resolved, 'resolved', admin.resolvedTickets.length),
                  _tab(l.closed, 'closed', admin.closedTickets.length),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Divider(color: theme.dividerColor, height: 1),

            // Content
            Expanded(
              child: _buildContent(admin, tickets, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      AdminProvider admin, List<SupportTicket> tickets, ThemeData theme) {
    final l = AppLocalizations.of(context);

    if (admin.ticketsLoading && admin.tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (admin.ticketsError != null && admin.tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 40,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              admin.ticketsError!,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => admin.fetchTickets(),
              child: Text(l.retry),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth > 860 && _selectedId != null) {
          return Row(
            children: [
              SizedBox(
                width: 380,
                child: _TicketList(
                  tickets: tickets,
                  selectedId: _selectedId,
                  onSelect: _onSelectTicket,
                ),
              ),
              Container(width: 1, color: theme.dividerColor),
              Expanded(child: _TicketDetailView(onBack: null)),
            ],
          );
        }
        if (_selectedId != null) {
          return _TicketDetailView(
            onBack: () {
              context.read<AdminProvider>().clearSelectedTicket();
              setState(() => _selectedId = null);
            },
          );
        }
        return _TicketList(
          tickets: tickets,
          selectedId: _selectedId,
          onSelect: _onSelectTicket,
        );
      },
    );
  }

  void _onSelectTicket(int id) {
    debugPrint('[SupportScreen] Ticket selected: id=$id');
    setState(() => _selectedId = id);
    context.read<AdminProvider>().fetchTicketDetail(id);
  }

  List<SupportTicket> _applyFilter(List<SupportTicket> tickets) {
    if (_filter == 'all') {
      debugPrint('[SupportScreen] Filter: all => ${tickets.length} tickets');
      return tickets;
    }
    final filtered = tickets.where((t) {
      switch (_filter) {
        case 'open':
          return t.isOpen;
        case 'inProgress':
          return t.isInProgress;
        case 'resolved':
          return t.isResolved;
        case 'closed':
          return t.isClosed;
        default:
          return true;
      }
    }).toList();
    debugPrint('[SupportScreen] Filter: $_filter => '
        '${filtered.length}/${tickets.length} tickets');
    return filtered;
  }

  Widget _tab(String label, String value, int count) {
    final theme = Theme.of(context);
    final selected = _filter == value;

    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.primary
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Ticket List ─────────────────────────────────────────────────

class _TicketList extends StatelessWidget {
  final List<SupportTicket> tickets;
  final int? selectedId;
  final ValueChanged<int> onSelect;

  const _TicketList({
    required this.tickets,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded,
                size: 40,
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Text(
              l.noTicketsFound,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: tickets.length,
      itemBuilder: (context, i) {
        final t = tickets[i];
        final selected = t.id == selectedId;
        return _TicketRow(
          ticket: t,
          selected: selected,
          onTap: () => onSelect(t.id),
        );
      },
    );
  }
}

class _TicketRow extends StatefulWidget {
  final SupportTicket ticket;
  final bool selected;
  final VoidCallback onTap;

  const _TicketRow({
    required this.ticket,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_TicketRow> createState() => _TicketRowState();
}

class _TicketRowState extends State<_TicketRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    final theme = Theme.of(context);

    final priorityColor = _priorityColor(t.priority);
    final statusColor = _statusColor(t.status);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.primary.withValues(alpha: 0.04)
                : _hovered
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.02)
                    : Colors.transparent,
            border: Border(
              left: BorderSide(
                color:
                    widget.selected ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.subject,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      '${t.requesterName} · ${t.category}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  Text(
                    '#${t.id}',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.3),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Ticket Detail ───────────────────────────────────────────────

class _TicketDetailView extends StatefulWidget {
  final VoidCallback? onBack;
  const _TicketDetailView({this.onBack});

  @override
  State<_TicketDetailView> createState() => _TicketDetailViewState();
}

class _TicketDetailViewState extends State<_TicketDetailView> {
  final _replyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final admin = context.watch<AdminProvider>();
    final l = AppLocalizations.of(context);

    if (admin.ticketDetailLoading && admin.selectedTicket == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final t = admin.selectedTicket;
    if (t == null) {
      return Center(
        child: Text(
          l.selectATicket,
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    final statusColor = _statusColor(t.status);
    final statusLabel = _statusLabelL10n(t.status, l);
    final priorityColor = _priorityColor(t.priority);
    final priorityLabel = _priorityLabelL10n(t.priority, l);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.onBack != null) ...[
                    IconButton(
                      onPressed: widget.onBack,
                      icon:
                          const Icon(Icons.arrow_back_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      t.subject,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Meta row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _badge(statusLabel, statusColor),
                  _badge(priorityLabel, priorityColor),
                  _outlineBadge(t.category, theme),
                  _outlineBadge('#${t.id}', theme, mono: true),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 14,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.4)),
                  const SizedBox(width: 6),
                  Text(
                    t.requesterName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(color: theme.dividerColor, height: 1),

        // Messages
        Expanded(
          child: admin.ticketDetailLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(22),
                  itemCount: t.messages.length,
                  itemBuilder: (context, i) =>
                      _Message(message: t.messages[i]),
                ),
        ),

        // Reply area
        if (!t.isClosed) ...[
          Divider(color: theme.dividerColor, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyCtrl,
                        maxLines: 3,
                        minLines: 1,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: l.writeReply,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _sending ? null : _sendReply,
                        icon: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded, size: 16),
                        label: Text(l.reply),
                        style: ElevatedButton.styleFrom(
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (t.isOpen || t.isInProgress)
                      _ActionButton(
                        label: l.markResolved,
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                        onPressed: () => _updateStatus(t.id, 'RESOLVED'),
                      ),
                    if (t.isOpen || t.isInProgress)
                      const SizedBox(width: 8),
                    _ActionButton(
                      label: l.close,
                      icon: null,
                      color: null,
                      onPressed: () => _updateStatus(t.id, 'CLOSED'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;

    final admin = context.read<AdminProvider>();
    final ticketId = admin.selectedTicket?.id;
    if (ticketId == null) return;

    debugPrint('[SupportScreen] Sending reply to ticket #$ticketId: '
        '"${text.length > 60 ? '${text.substring(0, 60)}...' : text}"');
    final l = AppLocalizations.of(context);
    setState(() => _sending = true);
    try {
      await admin.addTicketReply(ticketId, text);
      debugPrint('[SupportScreen] Reply sent successfully');
      _replyCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.failedToSend('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _updateStatus(int ticketId, String status) async {
    debugPrint('[SupportScreen] Updating ticket #$ticketId status to $status');
    final admin = context.read<AdminProvider>();
    final l = AppLocalizations.of(context);
    try {
      await admin.updateTicketStatus(ticketId, status);
      debugPrint('[SupportScreen] Ticket #$ticketId status updated to $status');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.failedToUpdate('$e'))),
        );
      }
    }
  }

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

  Widget _outlineBadge(String label, ThemeData theme, {bool mono = false}) {
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
          fontFamily: mono ? 'monospace' : null,
        ),
      ),
    );
  }
}

// ─── Action Button ──────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final Future<void> Function() onPressed;

  const _ActionButton({
    required this.label,
    this.icon,
    this.color,
    required this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    if (widget.icon != null && widget.color != null) {
      return OutlinedButton.icon(
        onPressed: _busy ? null : _run,
        icon: _busy
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(widget.icon, size: 15),
        label: Text(widget.label),
        style: OutlinedButton.styleFrom(
          foregroundColor: widget.color,
          side: BorderSide(color: widget.color!),
          textStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: Size.zero,
        ),
      );
    }

    return OutlinedButton(
      onPressed: _busy ? null : _run,
      style: OutlinedButton.styleFrom(
        textStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
      ),
      child: _busy
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2))
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

// ─── Message Bubble ──────────────────────────────────────────────

class _Message extends StatelessWidget {
  final TicketMessage message;
  const _Message({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = message.isAdmin;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isAdmin) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.person_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.4)),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isAdmin
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : theme.colorScheme.onSurface
                        .withValues(alpha: 0.04),
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMedium),
                border: isAdmin
                    ? Border.all(
                        color:
                            AppColors.primary.withValues(alpha: 0.15))
                    : Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.authorName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isAdmin
                              ? AppColors.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? AppColors.primary
                                  .withValues(alpha: 0.15)
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          message.authorRole,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isAdmin
                                ? AppColors.primary
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message.body,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.8),
                    ),
                  ),
                  // Attachments
                  if (message.attachments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: message.attachments.map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.attach_file_rounded,
                                  size: 13,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.4)),
                              const SizedBox(width: 4),
                              Text(
                                a.mimeType,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
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
            const SizedBox(width: 10),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.primary.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.support_agent_rounded,
                  size: 16, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────

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
