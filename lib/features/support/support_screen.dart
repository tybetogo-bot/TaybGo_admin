import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/models/support_ticket.dart';
import '../../core/l10n/app_localizations.dart';
import 'create_support_ticket_dialog.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String _filter = 'all';
  late final AdminProvider _admin;

  @override
  void initState() {
    super.initState();
    debugPrint('[SupportScreen] initState — loading tickets');
    _admin = context.read<AdminProvider>();
    Future.microtask(() async {
      await _admin.fetchTickets(page: 1);
      if (mounted) _admin.startSupportPolling();
    });
  }

  @override
  void dispose() {
    _admin.stopSupportPolling();
    super.dispose();
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
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => createSupportTicketFromContext(
                    context,
                    preset: SupportTicketComposerPreset.general(),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l.createSupportTicket),
                ),
                IconButton(
                  onPressed: admin.ticketsLoading
                      ? null
                      : () {
                          debugPrint(
                            '[SupportScreen] Manual refresh triggered',
                          );
                          admin.fetchTickets(page: 1);
                        },
                  icon: admin.ticketsLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
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
                  _tab(
                    l.inProgress,
                    'inProgress',
                    admin.inProgressTickets.length,
                  ),
                  _tab(l.resolved, 'resolved', admin.resolvedTickets.length),
                  _tab(l.closed, 'closed', admin.closedTickets.length),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Divider(color: theme.dividerColor, height: 1),

            // Content
            Expanded(child: _buildContent(admin, tickets, theme, l)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    AdminProvider admin,
    List<SupportTicket> tickets,
    ThemeData theme,
    AppLocalizations l,
  ) {
    if (admin.ticketsLoading && admin.tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (admin.ticketsError != null && admin.tickets.isEmpty) {
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
              admin.ticketsError!,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => admin.fetchTickets(page: 1),
              child: Text(l.retry),
            ),
          ],
        ),
      );
    }

    if (tickets.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 40,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  ),
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
            ),
          ),
          _SupportPaginationBar(admin: admin),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, i) {
              final t = tickets[i];
              return _TicketRow(
                ticket: t,
                onTap: () => context.go('/support/${t.id}'),
              );
            },
          ),
        ),
        _SupportPaginationBar(admin: admin),
      ],
    );
  }

  List<SupportTicket> _applyFilter(List<SupportTicket> tickets) {
    if (_filter == 'all') return tickets;
    return tickets.where((t) {
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.45),
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

class _SupportPaginationBar extends StatelessWidget {
  const _SupportPaginationBar({required this.admin});

  final AdminProvider admin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Text(
            l.pageNumber(admin.ticketsPage),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: admin.ticketsLoading || admin.ticketsPrevious == null
                ? null
                : () => admin.fetchTickets(page: admin.ticketsPage - 1),
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: l.previousPage,
          ),
          IconButton(
            onPressed: admin.ticketsLoading || admin.ticketsNext == null
                ? null
                : () => admin.fetchTickets(page: admin.ticketsPage + 1),
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: l.nextPage,
          ),
        ],
      ),
    );
  }
}

// ─── Ticket Row ──────────────────────────────────────────────────

class _TicketRow extends StatefulWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;

  const _TicketRow({required this.ticket, required this.onTap});

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
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hovered
                ? theme.colorScheme.onSurface.withValues(alpha: 0.02)
                : Colors.transparent,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '#${t.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
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
