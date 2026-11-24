import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/country.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/services/google_places_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'google_places_address_field.dart';
import 'managed_cloudinary_file_field.dart';
import 'managed_entity_form_support.dart';
import 'managed_entity_form_widgets.dart';
import 'managed_file_picker.dart';
import 'managed_phone_field.dart';

class CreateRestaurantScreen extends StatefulWidget {
  const CreateRestaurantScreen({
    super.key,
    this.placesService,
    this.cloudinaryService,
    this.filePicker = pickManagedFile,
  });

  final GooglePlacesService? placesService;
  final CloudinaryService? cloudinaryService;
  final ManagedFilePicker filePicker;

  @override
  State<CreateRestaurantScreen> createState() => _CreateRestaurantScreenState();
}

class _CreateRestaurantScreenState extends State<CreateRestaurantScreen> {
  static const _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  final _ownerName = TextEditingController();
  final _ownerPhone = TextEditingController();
  final _ownerEmail = TextEditingController();
  final _addressLabel = TextEditingController(text: 'restaurant');
  final _addressSearch = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _fullAddress = TextEditingController();
  final _street = TextEditingController();
  final _houseNumber = TextEditingController();
  final _city = TextEditingController();
  final _postalCode = TextEditingController();
  final _country = TextEditingController();
  final _restaurantName = TextEditingController();
  final _restaurantPhone = TextEditingController();
  final _logoUrl = TextEditingController();
  final _licenseUrl = TextEditingController();

  DateTime? _birthdate;
  bool _deliveryEnabled = true;
  bool _submitting = false;
  String? _formError;
  Map<String, String> _errors = {};
  GooglePlacesService? _placesService;
  GooglePlaceAddress? _selectedAddress;
  bool _ownsPlacesService = false;
  late final CloudinaryService _cloudinaryService;
  bool _ownsCloudinaryService = false;
  final Set<String> _uploadingFields = {};
  final Map<String, String> _uploadFileNames = {};
  Country _ownerPhoneCountry = const Country(
    name: 'Belgium',
    code: 'BE',
    dialCode: '+32',
  );
  Country _restaurantPhoneCountry = const Country(
    name: 'Belgium',
    code: 'BE',
    dialCode: '+32',
  );
  late final Map<String, DailyHours> _hours = {
    for (final day in managedWeekdayKeys) day: const DailyHours(enabled: true),
  };

  @override
  void initState() {
    super.initState();
    if (widget.placesService != null) {
      _placesService = widget.placesService;
    } else if (_googleMapsApiKey.trim().isNotEmpty) {
      _placesService = GooglePlacesService(apiKey: _googleMapsApiKey);
      _ownsPlacesService = true;
    }
    if (widget.cloudinaryService != null) {
      _cloudinaryService = widget.cloudinaryService!;
    } else {
      _cloudinaryService = CloudinaryService();
      _ownsCloudinaryService = true;
    }
  }

  List<TextEditingController> get _controllers => [
    _ownerName,
    _ownerPhone,
    _ownerEmail,
    _addressLabel,
    _addressSearch,
    _latitude,
    _longitude,
    _fullAddress,
    _street,
    _houseNumber,
    _city,
    _postalCode,
    _country,
    _restaurantName,
    _restaurantPhone,
    _logoUrl,
    _licenseUrl,
  ];

  @override
  void dispose() {
    if (_ownsPlacesService) _placesService?.close();
    if (_ownsCloudinaryService) _cloudinaryService.close();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ManagedFormScaffold(
      title: l.createRestaurantTitle,
      subtitle: l.createRestaurantSubtitle,
      icon: Icons.storefront_rounded,
      cancelLabel: l.cancel,
      submitLabel: l.createRestaurantAction,
      isSubmitting: _submitting || _uploadingFields.isNotEmpty,
      formError: _formError,
      onSubmit: _submit,
      child: Column(
        children: [
          ManagedFormSection(
            title: l.ownerAccount,
            description: l.ownerAccountDescription,
            icon: Icons.person_outline_rounded,
            child: ManagedFieldGrid(
              children: [
                ManagedTextField(
                  key: const Key('restaurant-owner-name'),
                  controller: _ownerName,
                  label: l.name,
                  icon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.words,
                  errorText: _error('user.name'),
                ),
                ManagedPhoneField(
                  key: const Key('restaurant-owner-phone'),
                  controller: _ownerPhone,
                  country: _ownerPhoneCountry,
                  onCountryChanged: (country) =>
                      setState(() => _ownerPhoneCountry = country),
                  label: l.phone,
                  errorText: _error('user.phone'),
                ),
                ManagedTextField(
                  controller: _ownerEmail,
                  label: '${l.email} (${l.optional})',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _error('user.email'),
                ),
                _birthdateField(l),
              ],
            ),
          ),
          ManagedFormSection(
            title: l.restaurantInfo,
            description: l.restaurantProfileDescription,
            icon: Icons.restaurant_menu_rounded,
            child: Column(
              children: [
                ManagedFieldGrid(
                  children: [
                    ManagedTextField(
                      key: const Key('restaurant-name'),
                      controller: _restaurantName,
                      label: l.restaurantName,
                      icon: Icons.storefront_outlined,
                      textCapitalization: TextCapitalization.words,
                      errorText: _error('restaurant.name'),
                    ),
                    ManagedPhoneField(
                      key: const Key('restaurant-phone'),
                      controller: _restaurantPhone,
                      country: _restaurantPhoneCountry,
                      onCountryChanged: (country) =>
                          setState(() => _restaurantPhoneCountry = country),
                      label: l.restaurantPhone,
                      suffixIcon: IconButton(
                        tooltip: l.useOwnerPhone,
                        onPressed: () => setState(() {
                          _restaurantPhone.text = _ownerPhone.text;
                          _restaurantPhoneCountry = _ownerPhoneCountry;
                        }),
                        icon: const Icon(Icons.content_copy_rounded, size: 18),
                      ),
                      errorText: _error('restaurant.phone'),
                    ),
                    ManagedCloudinaryFileField(
                      key: const Key('restaurant-upload-logo'),
                      label: l.logoUrl,
                      icon: Icons.image_outlined,
                      isRequired: false,
                      isUploading: _uploadingFields.contains('restaurant.logo'),
                      fileName: _uploadFileNames['restaurant.logo'],
                      url: _logoUrl.text,
                      errorText: _error('restaurant.logo'),
                      uploadLabel: l.uploadFile,
                      replaceLabel: l.replaceFile,
                      uploadingLabel: l.uploadingFile,
                      fileTypesLabel: l.imageFileTypesHelp,
                      onPick: () => _pickAndUpload(
                        key: 'restaurant.logo',
                        folder: 'restaurant_logos',
                        controller: _logoUrl,
                        imagesOnly: true,
                      ),
                    ),
                    ManagedCloudinaryFileField(
                      key: const Key('restaurant-upload-license'),
                      label: l.registrationLicenseUrl,
                      icon: Icons.verified_user_outlined,
                      isRequired: true,
                      isUploading: _uploadingFields.contains(
                        'seller_profile.restaurant_registration_license_document',
                      ),
                      fileName:
                          _uploadFileNames['seller_profile.restaurant_registration_license_document'],
                      url: _licenseUrl.text,
                      errorText: _error(
                        'seller_profile.restaurant_registration_license_document',
                      ),
                      uploadLabel: l.uploadFile,
                      replaceLabel: l.replaceFile,
                      uploadingLabel: l.uploadingFile,
                      fileTypesLabel: l.documentFileTypesHelp,
                      onPick: () => _pickAndUpload(
                        key:
                            'seller_profile.restaurant_registration_license_document',
                        folder: 'restaurant_registration_licenses',
                        controller: _licenseUrl,
                        imagesOnly: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ManagedToggleTile(
                  title: l.deliveryEnabled,
                  subtitle: l.deliveryEnabledDescription,
                  icon: Icons.delivery_dining_rounded,
                  value: _deliveryEnabled,
                  onChanged: (value) =>
                      setState(() => _deliveryEnabled = value),
                ),
              ],
            ),
          ),
          ManagedFormSection(
            title: l.address,
            description: l.addressDetailsDescription,
            icon: Icons.location_on_outlined,
            child: Column(
              children: [
                GooglePlacesAddressField(
                  service: _placesService,
                  searchController: _addressSearch,
                  selectedAddress: _selectedAddress,
                  errorText: _addressError,
                  onSelection: _selectAddress,
                  onSelectionInvalidated: _invalidateAddress,
                  onError: (_) =>
                      setState(() => _formError = l.googlePlacesSearchError),
                ),
                const SizedBox(height: 16),
                ManagedFieldGrid(
                  children: [
                    ManagedTextField(
                      controller: _addressLabel,
                      label: l.label,
                      hint: l.restaurantAddressLabelHint,
                      icon: Icons.bookmark_outline_rounded,
                      errorText: _error('address.label'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ManagedFormSection(
            title: l.openingHours,
            description: l.openingHoursDescription,
            icon: Icons.schedule_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errors['restaurant.work_hours'] != null) ...[
                  ManagedFormError(message: _errors['restaurant.work_hours']!),
                  const SizedBox(height: 12),
                ],
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 760;
                    const gap = 10.0;
                    final width = twoColumns
                        ? (constraints.maxWidth - gap) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: gap,
                      runSpacing: 10,
                      children: managedWeekdayKeys
                          .map(
                            (day) => SizedBox(
                              width: width,
                              child: _DayHoursRow(
                                dayLabel: l.weekdayName(day),
                                closedLabel: l.closed,
                                hours: _hours[day]!,
                                onEnabledChanged: (enabled) => setState(() {
                                  _hours[day] = _hours[day]!.copyWith(
                                    enabled: enabled,
                                  );
                                }),
                                onOpenTap: () => _pickTime(day, true),
                                onCloseTap: () => _pickTime(day, false),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _birthdateField(AppLocalizations l) {
    final text = _birthdate == null
        ? l.selectBirthdate
        : '${_birthdate!.year.toString().padLeft(4, '0')}-'
              '${_birthdate!.month.toString().padLeft(2, '0')}-'
              '${_birthdate!.day.toString().padLeft(2, '0')}';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _pickBirthdate,
      child: InputDecorator(
        decoration: managedInputDecoration(
          context,
          label: '${l.birthdate} (${l.optional})',
          prefixIcon: Icons.cake_outlined,
          errorText: _error('user.birthdate'),
          suffixIcon: _birthdate == null
              ? const Icon(Icons.calendar_month_outlined)
              : IconButton(
                  tooltip: l.clear,
                  onPressed: () => setState(() => _birthdate = null),
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: _birthdate == null
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                : null,
          ),
        ),
      ),
    );
  }

  String? _error(String key) {
    return _errors[key] ??
        _errors[key.split('.').last] ??
        switch (key) {
          'user.phone' => _errors['phone'],
          'user.email' => _errors['email'],
          _ => null,
        };
  }

  String? get _addressError =>
      _errors['address.place'] ??
      _error('address.full_address') ??
      _error('address.city') ??
      _error('address.country') ??
      _error('address.lat') ??
      _error('address.lng');

  void _selectAddress(GooglePlaceAddress address) {
    setState(() {
      _selectedAddress = address;
      _latitude.text = address.latitude;
      _longitude.text = address.longitude;
      _fullAddress.text = address.fullAddress;
      _street.text = address.streetName ?? '';
      _houseNumber.text = address.houseNumber ?? '';
      _city.text = address.city ?? '';
      _postalCode.text = address.postalCode ?? '';
      _country.text = address.country ?? '';
      _errors.removeWhere((key, _) => key.startsWith('address.'));
      _formError = null;
    });
  }

  void _invalidateAddress() {
    setState(() {
      _selectedAddress = null;
      for (final controller in [
        _latitude,
        _longitude,
        _fullAddress,
        _street,
        _houseNumber,
        _city,
        _postalCode,
        _country,
      ]) {
        controller.clear();
      }
    });
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (mounted && selected != null) setState(() => _birthdate = selected);
  }

  Future<void> _pickAndUpload({
    required String key,
    required String folder,
    required TextEditingController controller,
    required bool imagesOnly,
  }) async {
    final l = AppLocalizations.of(context);
    final file = await widget.filePicker(imagesOnly: imagesOnly);
    if (file == null || !mounted) return;
    if (file.bytes.length > 10 * 1024 * 1024) {
      setState(() => _errors[key] = l.fileTooLarge);
      return;
    }
    setState(() {
      _uploadingFields.add(key);
      _errors.remove(key);
      _formError = null;
    });
    try {
      final url = await _cloudinaryService.uploadFile(
        file.bytes,
        fileName: file.fileName,
        folder: folder,
        resourceType: imagesOnly ? 'image' : 'auto',
      );
      if (!mounted) return;
      setState(() {
        controller.text = url;
        _uploadFileNames[key] = file.fileName;
      });
    } catch (_) {
      if (mounted) setState(() => _errors[key] = l.uploadFailed);
    } finally {
      if (mounted) setState(() => _uploadingFields.remove(key));
    }
  }

  Future<void> _pickTime(String day, bool opening) async {
    final current = _hours[day]!;
    final minutes = opening ? current.openMinutes : current.closeMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (!mounted || picked == null) return;
    final updatedMinutes = picked.hour * 60 + picked.minute;
    setState(() {
      _hours[day] = opening
          ? current.copyWith(openMinutes: updatedMinutes)
          : current.copyWith(closeMinutes: updatedMinutes);
    });
  }

  Map<String, String> _validate(AppLocalizations l) {
    final ownerPhone = buildInternationalPhone(
      _ownerPhoneCountry.dialCode,
      _ownerPhone.text,
    );
    final errors = ManagedEntityValidation.validateCommon(
      name: _ownerName.text,
      phone: ownerPhone,
      email: _ownerEmail.text,
      label: _addressLabel.text,
      latitude: _latitude.text,
      longitude: _longitude.text,
      fullAddress: _fullAddress.text,
      city: _city.text,
      country: _country.text,
      requiredMessage: l.requiredField,
      invalidPhoneMessage: l.invalidPhone,
      invalidEmailMessage: l.invalidEmail,
      invalidLatitudeMessage: l.invalidLatitude,
      invalidLongitudeMessage: l.invalidLongitude,
    );
    if (_selectedAddress == null) {
      errors['address.place'] = l.selectAddressSuggestion;
    } else if (_city.text.trim().isEmpty || _country.text.trim().isEmpty) {
      errors['address.place'] = l.completeAddressRequired;
    }
    if (_restaurantName.text.trim().isEmpty) {
      errors['restaurant.name'] = l.requiredField;
    }
    final restaurantPhone = buildInternationalPhone(
      _restaurantPhoneCountry.dialCode,
      _restaurantPhone.text,
    );
    if (restaurantPhone.isEmpty) {
      errors['restaurant.phone'] = l.requiredField;
    } else {
      final phoneErrors = ManagedEntityValidation.validateCommon(
        name: 'ok',
        phone: restaurantPhone,
        email: '',
        label: 'ok',
        latitude: '0',
        longitude: '0',
        fullAddress: 'ok',
        city: 'ok',
        country: 'ok',
        requiredMessage: l.requiredField,
        invalidPhoneMessage: l.invalidPhone,
        invalidEmailMessage: l.invalidEmail,
        invalidLatitudeMessage: l.invalidLatitude,
        invalidLongitudeMessage: l.invalidLongitude,
      );
      if (phoneErrors['user.phone'] case final message?) {
        errors['restaurant.phone'] = message;
      }
    }
    if (_licenseUrl.text.trim().isEmpty) {
      errors['seller_profile.restaurant_registration_license_document'] =
          l.requiredField;
    }
    if (_hours.values.any(
      (hours) => hours.enabled && hours.openMinutes == hours.closeMinutes,
    )) {
      errors['restaurant.work_hours'] = l.openCloseTimesMustDiffer;
    }
    return errors;
  }

  Map<String, dynamic> _payload() {
    final logo = _logoUrl.text.trim();
    final license = _licenseUrl.text.trim();
    return {
      'user': buildManagedUserPayload(
        name: _ownerName.text,
        phone: buildInternationalPhone(
          _ownerPhoneCountry.dialCode,
          _ownerPhone.text,
        ),
        email: _ownerEmail.text,
        birthdate: _birthdate,
      ),
      'seller_profile': {
        if (license.isNotEmpty)
          'restaurant_registration_license_document': license,
      },
      'address': buildManagedAddressPayload(
        label: _addressLabel.text,
        latitude: _latitude.text,
        longitude: _longitude.text,
        fullAddress: _fullAddress.text,
        streetName: _street.text,
        houseNumber: _houseNumber.text,
        city: _city.text,
        postalCode: _postalCode.text,
        country: _country.text,
      ),
      'restaurant': {
        'name': _restaurantName.text.trim(),
        'phone': buildInternationalPhone(
          _restaurantPhoneCountry.dialCode,
          _restaurantPhone.text,
        ),
        if (logo.isNotEmpty) 'logo': logo,
        'work_hours': buildUtcWorkHours(_hours),
        'delivery_enabled': _deliveryEnabled,
        'status': 'ACTIVE',
      },
    };
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final errors = _validate(l);
    if (errors.isNotEmpty) {
      setState(() {
        _errors = errors;
        _formError = l.correctHighlightedFields;
      });
      return;
    }

    setState(() {
      _errors = {};
      _formError = null;
      _submitting = true;
    });
    try {
      await context.read<AdminProvider>().createRestaurant(_payload());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.restaurantCreatedSuccessfully)));
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errors = error.fieldErrors;
        _formError = error.fieldErrors.isEmpty
            ? error.message
            : l.serverRejectedFields;
      });
    } catch (_) {
      if (mounted) setState(() => _formError = l.connectionError);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _DayHoursRow extends StatelessWidget {
  final String dayLabel;
  final String closedLabel;
  final DailyHours hours;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onOpenTap;
  final VoidCallback onCloseTap;

  const _DayHoursRow({
    required this.dayLabel,
    required this.closedLabel,
    required this.hours,
    required this.onEnabledChanged,
    required this.onOpenTap,
    required this.onCloseTap,
  });

  String _format(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: hours.enabled
            ? AppColors.primary.withValues(alpha: 0.045)
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: hours.enabled
              ? AppColors.primary.withValues(alpha: 0.22)
              : scheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              dayLabel,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Switch.adaptive(value: hours.enabled, onChanged: onEnabledChanged),
          const SizedBox(width: 4),
          if (!hours.enabled)
            Expanded(
              child: Text(
                closedLabel,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.48),
                ),
              ),
            )
          else ...[
            Expanded(
              child: OutlinedButton(
                onPressed: onOpenTap,
                child: Text(_format(hours.openMinutes)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '–',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.48),
                ),
              ),
            ),
            Expanded(
              child: OutlinedButton(
                onPressed: onCloseTap,
                child: Text(_format(hours.closeMinutes)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
