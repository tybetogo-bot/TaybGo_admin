import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/services/google_places_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'managed_entity_form_widgets.dart';

class GooglePlacesAddressField extends StatefulWidget {
  const GooglePlacesAddressField({
    super.key,
    required this.service,
    required this.searchController,
    required this.selectedAddress,
    required this.errorText,
    required this.onSelection,
    required this.onSelectionInvalidated,
    required this.onError,
  });

  final GooglePlacesService? service;
  final TextEditingController searchController;
  final GooglePlaceAddress? selectedAddress;
  final String? errorText;
  final ValueChanged<GooglePlaceAddress> onSelection;
  final VoidCallback onSelectionInvalidated;
  final ValueChanged<Object> onError;

  @override
  State<GooglePlacesAddressField> createState() =>
      _GooglePlacesAddressFieldState();
}

class _GooglePlacesAddressFieldState extends State<GooglePlacesAddressField> {
  Timer? _debounce;
  List<GooglePlaceSuggestion> _suggestions = const [];
  bool _searching = false;
  bool _resolving = false;
  bool _showNoResults = false;
  int _requestGeneration = 0;
  late String _sessionToken;

  @override
  void initState() {
    super.initState();
    _sessionToken = _newSessionToken();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    if (widget.selectedAddress != null) widget.onSelectionInvalidated();
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _suggestions = const [];
        _searching = false;
        _showNoResults = false;
      });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_search(query)),
    );
  }

  Future<void> _search(String query) async {
    final service = widget.service;
    if (service == null || !mounted) return;
    final generation = ++_requestGeneration;
    setState(() {
      _searching = true;
      _showNoResults = false;
    });
    try {
      final results = await service.autocomplete(
        input: query,
        sessionToken: _sessionToken,
        languageCode: Localizations.localeOf(context).languageCode,
      );
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _suggestions = results;
        _searching = false;
        _showNoResults = results.isEmpty;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _suggestions = const [];
        _searching = false;
        _showNoResults = false;
      });
      widget.onError(error);
    }
  }

  Future<void> _select(GooglePlaceSuggestion suggestion) async {
    final service = widget.service;
    if (service == null || _resolving) return;
    setState(() => _resolving = true);
    try {
      final address = await service.resolveAddress(
        suggestion: suggestion,
        sessionToken: _sessionToken,
        languageCode: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      widget.searchController.value = TextEditingValue(
        text: address.fullAddress,
        selection: TextSelection.collapsed(offset: address.fullAddress.length),
      );
      setState(() {
        _resolving = false;
        _suggestions = const [];
        _showNoResults = false;
        _sessionToken = _newSessionToken();
      });
      widget.onSelection(address);
    } catch (error) {
      if (!mounted) return;
      setState(() => _resolving = false);
      widget.onError(error);
    }
  }

  void _clear() {
    _debounce?.cancel();
    _requestGeneration++;
    widget.searchController.clear();
    setState(() {
      _suggestions = const [];
      _searching = false;
      _resolving = false;
      _showNoResults = false;
      _sessionToken = _newSessionToken();
    });
    widget.onSelectionInvalidated();
  }

  String _newSessionToken() {
    final random = Random.secure();
    return List<int>.generate(
      4,
      (_) => random.nextInt(0x100000000),
    ).map((value) => value.toRadixString(16).padLeft(8, '0')).join();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.service == null)
          _PlacesStatusCard(
            icon: Icons.key_off_outlined,
            message: l.googlePlacesUnavailable,
            color: AppColors.warning,
          )
        else ...[
          TextField(
            key: const Key('google-places-search'),
            controller: widget.searchController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.search,
            onChanged: _onQueryChanged,
            decoration: managedInputDecoration(
              context,
              label: l.searchAddress,
              hint: l.searchAddressHint,
              helperText: l.googlePlacesSearchHelp,
              errorText: widget.errorText,
              prefixIcon: Icons.location_searching_rounded,
              suffixIcon: _searching || _resolving
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : widget.searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l.clear,
                      onPressed: _clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < _suggestions.length; i++) ...[
                    ListTile(
                      onTap: () => _select(_suggestions[i]),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        _suggestions[i].primaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: _suggestions[i].secondaryText == null
                          ? null
                          : Text(
                              _suggestions[i].secondaryText!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                    if (i < _suggestions.length - 1)
                      Divider(
                        height: 1,
                        color: scheme.outline.withValues(alpha: 0.18),
                      ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        'Powered by Google',
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_showNoResults) ...[
            const SizedBox(height: 8),
            _PlacesStatusCard(
              icon: Icons.search_off_rounded,
              message: l.noAddressResults,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ],
        ],
        if (widget.selectedAddress != null) ...[
          const SizedBox(height: 14),
          _SelectedPlaceCard(address: widget.selectedAddress!, onClear: _clear),
        ],
      ],
    );
  }
}

class _SelectedPlaceCard extends StatelessWidget {
  const _SelectedPlaceCard({required this.address, required this.onClear});

  final GooglePlaceAddress address;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final area = [
      address.postalCode,
      address.city,
      address.country,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.addressSelected,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  address.fullAddress,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                if (area.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    area,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12.5,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  '${address.latitude}, ${address.longitude}',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.48),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l.clear,
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _PlacesStatusCard extends StatelessWidget {
  const _PlacesStatusCard({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
