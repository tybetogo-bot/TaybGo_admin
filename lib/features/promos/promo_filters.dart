import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/home_response.dart';
import '../../core/providers/promos_provider.dart';
import '../../core/services/api_service.dart';

Future<void> showPromoFilters(BuildContext context, PromosProvider provider) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => _Filters(provider: provider),
    );

class _Filters extends StatefulWidget {
  final PromosProvider provider;
  const _Filters({required this.provider});
  @override
  State<_Filters> createState() => _FiltersState();
}

class _FiltersState extends State<_Filters> {
  late final TextEditingController city;
  int? restaurantId;
  String? restaurantName;
  int? _countryId;
  @override
  void initState() {
    super.initState();
    city = TextEditingController(text: widget.provider.city);
    restaurantId = widget.provider.restaurantId;
    restaurantName = widget.provider.restaurantName;
    _countryId = widget.provider.country.selectedCountryId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.provider.country.loadCountries();
    });
  }

  @override
  void dispose() {
    city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = widget.provider;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.promoFilters,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.close,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              l.promoFilterHelp,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 22),
            ListenableBuilder(
              listenable: p.country,
              builder: (context, _) => Column(
                children: [
                  DropdownButtonFormField<int?>(
                    key: ValueKey(_countryId),
                    initialValue: _countryId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l.countryFilter,
                      prefixIcon: const Icon(Icons.public_outlined),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(l.allCountries),
                      ),
                      ...p.country.countries.map(
                        (c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: p.country.isLoading
                        ? null
                        : (id) => setState(() {
                            _countryId = id;
                            city.clear();
                            restaurantId = null;
                            restaurantName = null;
                          }),
                  ),
                  if (p.country.isLoading)
                    const LinearProgressIndicator(minHeight: 2),
                  if (p.country.error != null)
                    TextButton(
                      onPressed: p.country.loadCountries,
                      child: Text(l.retry),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: city,
              decoration: InputDecoration(
                labelText: l.city,
                prefixIcon: const Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.storefront_outlined),
              title: Text(restaurantName ?? l.promoAllRestaurants),
              subtitle: Text(l.promoFindRestaurant),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await showDialog<HomeRestaurant>(
                  context: context,
                  builder: (_) =>
                      _RestaurantSearch(provider: p, countryId: _countryId),
                );
                if (result != null && mounted) {
                  setState(() {
                    restaurantId = result.id;
                    restaurantName = result.name;
                  });
                }
              },
            ),
            if (restaurantId != null)
              TextButton(
                onPressed: () => setState(() {
                  restaurantId = null;
                  restaurantName = null;
                }),
                child: Text(l.promoAllRestaurants),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _countryId = null;
                      city.clear();
                      restaurantId = null;
                      restaurantName = null;
                    });
                  },
                  child: Text(l.promoClearScope),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () {
                    p.applyScope(
                      city: city.text,
                      countryId: _countryId,
                      changeCountry: true,
                      restaurantId: restaurantId,
                      restaurantName: restaurantName,
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(l.promoApplyFilters),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantSearch extends StatefulWidget {
  final PromosProvider provider;
  final int? countryId;
  const _RestaurantSearch({required this.provider, required this.countryId});
  @override
  State<_RestaurantSearch> createState() => _RestaurantSearchState();
}

class _RestaurantSearchState extends State<_RestaurantSearch> {
  final search = TextEditingController();
  List<HomeRestaurant> results = [];
  bool loading = false;
  String? error;
  int version = 0;
  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final request = ++version;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await widget.provider.api.getAdminRestaurants(
        search: search.text,
        countryId: widget.countryId,
      );
      if (mounted && request == version) {
        setState(() => results = response.results);
      }
    } catch (e) {
      if (mounted && request == version) {
        setState(
          () => error = e is ApiException
              ? e.message
              : AppLocalizations.of(context).promosLoadError,
        );
      }
    } finally {
      if (mounted && request == version) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.promoFindRestaurant),
      content: SizedBox(
        width: 420,
        height: 360,
        child: Column(
          children: [
            TextField(
              controller: search,
              autofocus: true,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: l.promoSearchRestaurant,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: l.promoSearchAction,
                  onPressed: loading ? null : _search,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (loading) const LinearProgressIndicator(),
            if (error != null) Text(error!),
            Expanded(
              child: !loading && results.isEmpty
                  ? Center(child: Text(l.promoNoRestaurants))
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final r = results[index];
                        return ListTile(
                          leading: const Icon(Icons.storefront_outlined),
                          title: Text(r.name),
                          subtitle: Text('#${r.id}'),
                          onTap: () => Navigator.pop(context, r),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
      ],
    );
  }
}
