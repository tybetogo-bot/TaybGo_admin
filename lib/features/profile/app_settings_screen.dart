import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/service_availability.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  ServiceAvailability? _availability;
  String? _availabilityError;
  bool _availabilityLoading = true;
  bool _savingAvailability = false;

  ApiService get _api => context.read<AdminProvider>().apiService;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _availabilityLoading = true;
      _availabilityError = null;
    });
    try {
      final availability = await _api.getServiceAvailability();
      if (mounted) {
        setState(() {
          _availability = availability;
          _availabilityLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _availabilityError = error is ApiException
              ? error.message
              : error.toString();
          _availabilityLoading = false;
        });
      }
    }
  }

  Future<void> _saveAvailability(String service, bool value) async {
    final previous = _availability;
    if (previous == null || _savingAvailability) return;

    setState(() {
      _availability = previous.withValue(service, value);
      _savingAvailability = true;
      _availabilityError = null;
    });
    try {
      final updated = await _api.updateServiceAvailability({service: value});
      if (mounted) {
        setState(() {
          _availability = updated;
          _savingAvailability = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).serviceAvailabilityUpdated,
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _availability = previous;
          _availabilityError = error is ApiException
              ? error.fieldErrors.values.isNotEmpty
                    ? error.fieldErrors.values.join('\n')
                    : error.message
              : error.toString();
          _savingAvailability = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l.serviceAvailability),
        actions: [
          IconButton(
            onPressed: _loadAvailability,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.serviceAvailabilityDescription,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_availability == null && _availabilityLoading) ...[
                    const SizedBox(height: 20),
                    const LinearProgressIndicator(),
                  ] else if (_availability == null) ...[
                    const SizedBox(height: 12),
                    _LoadError(
                      message: _availabilityError ?? l.connectionError,
                      onRetry: _loadAvailability,
                      retryLabel: l.retry,
                    ),
                  ] else ...[
                    if (_availabilityLoading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                    if (_availabilityError != null) ...[
                      const SizedBox(height: 12),
                      _LoadError(
                        message: _availabilityError!,
                        onRetry: _loadAvailability,
                        retryLabel: l.retry,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _availabilityToggle(
                      label: l.foodService,
                      service: 'food',
                      value: _availability!.food,
                    ),
                    _availabilityToggle(
                      label: l.taxiService,
                      service: 'taxi',
                      value: _availability!.taxi,
                    ),
                    _availabilityToggle(
                      label: l.shippingService,
                      service: 'shipping',
                      value: _availability!.shipping,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _availabilityToggle({
    required String label,
    required String service,
    required bool value,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: _savingAvailability || _availabilityLoading
          ? null
          : (enabled) => _saveAvailability(service, enabled),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onRetry, child: Text(retryLabel)),
      ],
    );
  }
}
