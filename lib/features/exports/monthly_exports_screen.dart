import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/monthly_store_export.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class MonthlyExportsScreen extends StatefulWidget {
  final int? initialRestaurantId;
  final bool showBackButton;

  const MonthlyExportsScreen({
    super.key,
    this.initialRestaurantId,
    this.showBackButton = true,
  });

  @override
  State<MonthlyExportsScreen> createState() => _MonthlyExportsScreenState();
}

class _MonthlyExportsScreenState extends State<MonthlyExportsScreen> {
  final TextEditingController _restaurantIdController = TextEditingController();

  List<MonthlyStoreExport> _exports = const [];
  bool _loading = false;
  bool _generating = false;
  String? _error;
  int? _selectedYear;
  int? _selectedMonth;
  String? _selectedStoreType;

  @override
  void initState() {
    super.initState();
    if (widget.initialRestaurantId != null) {
      _restaurantIdController.text = '${widget.initialRestaurantId}';
    }
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _restaurantIdController.dispose();
    super.dispose();
  }

  int? get _parsedRestaurantId {
    final text = _restaurantIdController.text.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AdminProvider>().apiService;
      final list = await api.getMonthlyStoreExports(
        restaurantId: _parsedRestaurantId,
        year: _selectedYear,
        month: _selectedMonth,
        storeType: _selectedStoreType,
      );
      if (!mounted) return;
      setState(() => _exports = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openPdf(MonthlyStoreExport export) async {
    final l = AppLocalizations.of(context);
    final url = export.downloadUrl;
    if (url == null || url.trim().isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.failedToOpenPdf),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showGenerateDialog() async {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1, 1);

    final options = await showDialog<_GenerateExportsOptions>(
      context: context,
      builder: (_) => _GenerateExportsDialog(
        initialYear: _selectedYear ?? prevMonth.year,
        initialMonth: _selectedMonth ?? prevMonth.month,
        initialRestaurantIdText: _restaurantIdController.text.trim(),
        maxYear: now.year,
      ),
    );

    if (options == null || !mounted) return;
    final restId = options.restaurantIdText.isEmpty
        ? null
        : int.tryParse(options.restaurantIdText);

    setState(() => _generating = true);
    try {
      final api = context.read<AdminProvider>().apiService;
      final res = await api.generateMonthlyStoreExports(
        year: options.year,
        month: options.month,
        restaurantId: restId,
        force: options.force,
      );
      if (!mounted) return;
      final summaryText = res.singleExport != null
          ? '${res.singleExport!.restaurantName} (${res.singleExport!.periodLabel})'
          : l.monthlyExportsGeneratedSummary;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(summaryText),
          backgroundColor: AppColors.success,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.failed('$e')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(l.monthlyPdfExports),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: l.refresh,
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              key: const Key('generate-monthly-export-button'),
              onPressed: _generating ? null : _showGenerateDialog,
              icon: _generating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: Text(l.generate),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _restaurantIdController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l.storeId,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _load(),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: DropdownButtonFormField<int?>(
                        isExpanded: true,
                        initialValue: _selectedYear,
                        decoration: InputDecoration(
                          labelText: l.year,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(l.all),
                          ),
                          ...List.generate(5, (i) => now.year - i).map(
                            (y) => DropdownMenuItem<int?>(
                              value: y,
                              child: Text('$y'),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedYear = v);
                          _load();
                        },
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: DropdownButtonFormField<int?>(
                        isExpanded: true,
                        initialValue: _selectedMonth,
                        decoration: InputDecoration(
                          labelText: l.month,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(l.all),
                          ),
                          ...List.generate(12, (i) => i + 1).map(
                            (m) => DropdownMenuItem<int?>(
                              value: m,
                              child: Text(m.toString().padLeft(2, '0')),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedMonth = v);
                          _load();
                        },
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        initialValue: _selectedStoreType,
                        decoration: InputDecoration(
                          labelText: l.storeType,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l.allStoreTypes),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'RESTAURANT',
                            child: Text(l.storeTypeRestaurant),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'GENERAL_MARKET',
                            child: Text(l.storeTypeGeneralMarket),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedStoreType = v);
                          _load();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _loading && _exports.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null && _exports.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _load,
                                child: Text(l.retry),
                              ),
                            ],
                          ),
                        )
                      : _exports.isEmpty
                      ? Center(
                          child: Text(
                            l.noMonthlyExportsFound,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _exports.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final export = _exports[index];
                            final isMarket =
                                export.restaurantStoreType == 'GENERAL_MARKET';
                            final statusColor = export.isCompleted
                                ? AppColors.success
                                : AppColors.warning;
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.cardTheme.color,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMedium,
                                ),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                '${export.restaurantName} (#${export.restaurantId})',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _Tag(
                                              label: isMarket
                                                  ? l.storeTypeGeneralMarket
                                                  : l.storeTypeRestaurant,
                                              color: isMarket
                                                  ? AppColors.info
                                                  : AppColors.primary,
                                            ),
                                            const SizedBox(width: 6),
                                            _Tag(
                                              label: export.status,
                                              color: statusColor,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${export.periodLabel} · ${export.fileFormat} · ${l.exportRowCount(export.rowCount)}'
                                          '${export.grossSalesDisplay != null ? ' · €${export.grossSalesDisplay}' : ''}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.65),
                                          ),
                                        ),
                                        if (export.errorMessage != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            export.errorMessage!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (export.hasDownload)
                                    OutlinedButton.icon(
                                      onPressed: () => _openPdf(export),
                                      icon: const Icon(
                                        Icons.open_in_new_rounded,
                                        size: 16,
                                      ),
                                      label: Text(l.openPdf),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenerateExportsOptions {
  final int year;
  final int month;
  final String restaurantIdText;
  final bool force;

  const _GenerateExportsOptions({
    required this.year,
    required this.month,
    required this.restaurantIdText,
    required this.force,
  });
}

class _GenerateExportsDialog extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final String initialRestaurantIdText;
  final int maxYear;

  const _GenerateExportsDialog({
    required this.initialYear,
    required this.initialMonth,
    required this.initialRestaurantIdText,
    required this.maxYear,
  });

  @override
  State<_GenerateExportsDialog> createState() => _GenerateExportsDialogState();
}

class _GenerateExportsDialogState extends State<_GenerateExportsDialog> {
  late int _year;
  late int _month;
  bool _force = false;
  late final TextEditingController _restController;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
    _month = widget.initialMonth;
    _restController = TextEditingController(text: widget.initialRestaurantIdText);
  }

  @override
  void dispose() {
    _restController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.generateMonthlyExports),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _year,
                    decoration: InputDecoration(labelText: l.year),
                    items: List.generate(5, (index) => widget.maxYear - index)
                        .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _year = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _month,
                    decoration: InputDecoration(labelText: l.month),
                    items: List.generate(12, (index) => index + 1)
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.toString().padLeft(2, '0')),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _month = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _restController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '${l.storeId} (${l.optional})',
                hintText: l.allStoresIfBlank,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.forceRegenerate),
              value: _force,
              onChanged: (v) => setState(() => _force = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('generate-monthly-export-confirm'),
          onPressed: () => Navigator.pop(
            context,
            _GenerateExportsOptions(
              year: _year,
              month: _month,
              restaurantIdText: _restController.text.trim(),
              force: _force,
            ),
          ),
          child: Text(l.generate),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
