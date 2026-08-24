import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/country.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/services/google_places_service.dart';
import 'google_places_address_field.dart';
import 'managed_cloudinary_file_field.dart';
import 'managed_entity_form_support.dart';
import 'managed_entity_form_widgets.dart';
import 'managed_file_picker.dart';
import 'managed_phone_field.dart';

class CreateDriverScreen extends StatefulWidget {
  const CreateDriverScreen({
    super.key,
    this.placesService,
    this.cloudinaryService,
    this.filePicker = pickManagedFile,
  });

  final GooglePlacesService? placesService;
  final CloudinaryService? cloudinaryService;
  final ManagedFilePicker filePicker;

  @override
  State<CreateDriverScreen> createState() => _CreateDriverScreenState();
}

class _CreateDriverScreenState extends State<CreateDriverScreen> {
  static const _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _addressLabel = TextEditingController(text: 'home');
  final _addressSearch = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _fullAddress = TextEditingController();
  final _street = TextEditingController();
  final _houseNumber = TextEditingController();
  final _city = TextEditingController();
  final _postalCode = TextEditingController();
  final _country = TextEditingController();
  final _plate = TextEditingController();
  final _color = TextEditingController();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _drivingLicense = TextEditingController();
  final _idDocument = TextEditingController();
  final _healthInsurance = TextEditingController();
  final _addressDocument = TextEditingController();
  final _bankDocument = TextEditingController();
  final _otherDocuments = TextEditingController();
  final _notes = TextEditingController();

  DateTime? _birthdate;
  String _vehicleType = 'BIKE';
  String? _carSize;
  int? _vehicleYear;
  Country _phoneCountry = const Country(
    name: 'Belgium',
    code: 'BE',
    dialCode: '+32',
  );
  bool _acceptsFood = true;
  bool _acceptsShipping = false;
  bool _acceptsTaxi = false;
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

  int get _maximumVehicleYear => DateTime.now().year + 1;
  List<int> get _vehicleYears =>
      buildManagedVehicleYears(_maximumVehicleYear - 1);

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
    _name,
    _phone,
    _email,
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
    _plate,
    _color,
    _make,
    _model,
    _drivingLicense,
    _idDocument,
    _healthInsurance,
    _addressDocument,
    _bankDocument,
    _otherDocuments,
    _notes,
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
      title: l.createDriverTitle,
      subtitle: l.createDriverSubtitle,
      icon: Icons.local_shipping_rounded,
      cancelLabel: l.cancel,
      submitLabel: l.createDriverAction,
      isSubmitting: _submitting || _uploadingFields.isNotEmpty,
      formError: _formError,
      onSubmit: _submit,
      child: Column(
        children: [
          ManagedFormSection(
            title: l.accountDetails,
            description: l.accountDetailsDescription,
            icon: Icons.person_outline_rounded,
            child: ManagedFieldGrid(
              children: [
                ManagedTextField(
                  key: const Key('driver-name'),
                  controller: _name,
                  label: l.name,
                  icon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.words,
                  errorText: _error('user.name'),
                ),
                ManagedPhoneField(
                  key: const Key('driver-phone'),
                  controller: _phone,
                  country: _phoneCountry,
                  onCountryChanged: (country) =>
                      setState(() => _phoneCountry = country),
                  label: l.phone,
                  errorText: _error('user.phone'),
                ),
                ManagedTextField(
                  controller: _email,
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
                      hint: l.addressLabelHint,
                      icon: Icons.bookmark_outline_rounded,
                      errorText: _error('address.label'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ManagedFormSection(
            title: l.vehicleDetails,
            description: l.vehicleDetailsDescription,
            icon: Icons.directions_car_outlined,
            child: Column(
              children: [
                ManagedFieldGrid(
                  children: [
                    ManagedDropdown<String>(
                      key: const Key('driver-vehicle-type'),
                      value: _vehicleType,
                      label: l.vehicleType,
                      icon: Icons.commute_rounded,
                      items: [
                        DropdownMenuItem(value: 'BIKE', child: Text(l.bike)),
                        DropdownMenuItem(value: 'CAR', child: Text(l.car)),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _vehicleType = value;
                          if (value != 'CAR') {
                            _carSize = null;
                            _vehicleYear = null;
                            _acceptsTaxi = false;
                          }
                        });
                      },
                    ),
                    if (_vehicleType == 'CAR')
                      ManagedDropdown<String>(
                        value: _carSize,
                        label: l.carSize,
                        icon: Icons.airline_seat_recline_extra_rounded,
                        errorText: _error('profile.car_size'),
                        items: const [
                          DropdownMenuItem(value: 'X', child: Text('X')),
                          DropdownMenuItem(
                            value: 'COMFORT',
                            child: Text('Comfort'),
                          ),
                          DropdownMenuItem(value: 'XL', child: Text('XL')),
                          DropdownMenuItem(
                            value: 'BLACK',
                            child: Text('Black'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _carSize = value),
                      ),
                    if (_vehicleType == 'CAR') ...[
                      ManagedTextField(
                        key: const Key('driver-vehicle-plate'),
                        controller: _plate,
                        label: l.vehiclePlateNumber,
                        icon: Icons.pin_outlined,
                        textCapitalization: TextCapitalization.characters,
                        errorText: _error('profile.vehicle_plate_number'),
                      ),
                      ManagedTextField(
                        key: const Key('driver-vehicle-color'),
                        controller: _color,
                        label: l.vehicleColor,
                        icon: Icons.palette_outlined,
                        textCapitalization: TextCapitalization.words,
                        errorText: _error('profile.vehicle_color'),
                      ),
                      ManagedTextField(
                        key: const Key('driver-vehicle-make'),
                        controller: _make,
                        label: l.vehicleMake,
                        icon: Icons.factory_outlined,
                        textCapitalization: TextCapitalization.words,
                        errorText: _error('profile.vehicle_make'),
                      ),
                      ManagedTextField(
                        key: const Key('driver-vehicle-model'),
                        controller: _model,
                        label: l.vehicleModel,
                        icon: Icons.directions_car_filled_outlined,
                        textCapitalization: TextCapitalization.words,
                        errorText: _error('profile.vehicle_model'),
                      ),
                      ManagedDropdown<int>(
                        key: const Key('driver-vehicle-year'),
                        value: _vehicleYear,
                        label: l.vehicleYear,
                        icon: Icons.calendar_today_outlined,
                        errorText: _error('profile.vehicle_year'),
                        items: _vehicleYears
                            .map(
                              (year) => DropdownMenuItem(
                                value: year,
                                child: Text('$year'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _vehicleYear = value),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          ManagedFormSection(
            title: l.serviceTypes,
            description: l.serviceTypesDescription,
            icon: Icons.route_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errors['profile.services'] != null) ...[
                  ManagedFormError(message: _errors['profile.services']!),
                  const SizedBox(height: 12),
                ],
                ManagedFieldGrid(
                  children: [
                    ManagedToggleTile(
                      title: l.food,
                      icon: Icons.restaurant_outlined,
                      value: _acceptsFood,
                      onChanged: (value) =>
                          setState(() => _acceptsFood = value),
                    ),
                    ManagedToggleTile(
                      title: l.shipping,
                      icon: Icons.inventory_2_outlined,
                      value: _acceptsShipping,
                      onChanged: (value) =>
                          setState(() => _acceptsShipping = value),
                    ),
                    if (_vehicleType == 'CAR')
                      ManagedToggleTile(
                        title: l.taxi,
                        icon: Icons.local_taxi_outlined,
                        value: _acceptsTaxi,
                        onChanged: (value) =>
                            setState(() => _acceptsTaxi = value),
                      ),
                  ],
                ),
              ],
            ),
          ),
          ManagedFormSection(
            title: l.optionalDocuments,
            description: l.optionalDocumentsDescription,
            icon: Icons.folder_copy_outlined,
            child: ManagedFieldGrid(
              children: [
                _uploadField(
                  l.drivingLicense,
                  _drivingLicense,
                  'profile.driving_license',
                  'driver_licenses',
                  isRequired: true,
                ),
                _uploadField(
                  l.idDocument,
                  _idDocument,
                  'profile.id_document',
                  'id_documents',
                  isRequired: true,
                ),
                _uploadField(
                  l.healthInsuranceDocument,
                  _healthInsurance,
                  'profile.health_insurance_document',
                  'health_insurance_documents',
                  isRequired: true,
                ),
                _uploadField(
                  l.addressDocument,
                  _addressDocument,
                  'profile.address_document',
                  'address_documents',
                  isRequired: true,
                ),
                _uploadField(
                  l.bankDocument,
                  _bankDocument,
                  'profile.bank_document',
                  'bank_documents',
                  isRequired: true,
                ),
                _uploadField(
                  l.otherDocuments,
                  _otherDocuments,
                  'profile.other_documents',
                  'other_documents',
                  isRequired: false,
                ),
              ],
            ),
          ),
          ManagedFormSection(
            title: l.adminNotes,
            description: l.adminNotesDescription,
            icon: Icons.sticky_note_2_outlined,
            child: ManagedTextField(
              controller: _notes,
              label: '${l.adminNotes} (${l.optional})',
              icon: Icons.edit_note_rounded,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              errorText: _error('notes'),
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

  Widget _uploadField(
    String label,
    TextEditingController controller,
    String key,
    String folder, {
    required bool isRequired,
  }) {
    final l = AppLocalizations.of(context);
    return ManagedCloudinaryFileField(
      key: Key('driver-upload-$key'),
      label: label,
      icon: Icons.description_outlined,
      isRequired: isRequired,
      isUploading: _uploadingFields.contains(key),
      fileName: _uploadFileNames[key],
      url: controller.text,
      errorText: _error(key),
      uploadLabel: l.uploadFile,
      replaceLabel: l.replaceFile,
      uploadingLabel: l.uploadingFile,
      fileTypesLabel: l.documentFileTypesHelp,
      onPick: () => _pickAndUpload(
        key: key,
        folder: folder,
        controller: controller,
        imagesOnly: false,
      ),
    );
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
      initialDate: _birthdate ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (mounted && selected != null) {
      setState(() => _birthdate = selected);
    }
  }

  Map<String, String> _validate(AppLocalizations l) {
    final phone = buildInternationalPhone(_phoneCountry.dialCode, _phone.text);
    final errors = ManagedEntityValidation.validateCommon(
      name: _name.text,
      phone: phone,
      email: _email.text,
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

    if (!_acceptsFood && !_acceptsShipping && !_acceptsTaxi) {
      errors['profile.services'] = l.atLeastOneService;
    }
    if (_vehicleType == 'CAR') {
      final requiredCarFields = {
        'profile.car_size': _carSize ?? '',
        'profile.vehicle_plate_number': _plate.text,
        'profile.vehicle_color': _color.text,
        'profile.vehicle_make': _make.text,
        'profile.vehicle_model': _model.text,
        'profile.vehicle_year': _vehicleYear?.toString() ?? '',
      };
      for (final entry in requiredCarFields.entries) {
        if (entry.value.trim().isEmpty) errors[entry.key] = l.requiredField;
      }
    }
    final requiredDocuments = {
      'profile.driving_license': _drivingLicense.text,
      'profile.id_document': _idDocument.text,
      'profile.health_insurance_document': _healthInsurance.text,
      'profile.address_document': _addressDocument.text,
      'profile.bank_document': _bankDocument.text,
    };
    for (final entry in requiredDocuments.entries) {
      if (entry.value.trim().isEmpty) errors[entry.key] = l.requiredField;
    }
    return errors;
  }

  Map<String, dynamic> _payload() {
    String? optional(TextEditingController controller) {
      final value = controller.text.trim();
      return value.isEmpty ? null : value;
    }

    final profile = <String, dynamic>{
      'status': 'APPROVED',
      'vehicle_type': _vehicleType,
      'accepts_food': _acceptsFood,
      'accepts_shipping': _acceptsShipping,
      'accepts_taxi': _acceptsTaxi,
    };
    void addOptional(String key, Object? value) {
      if (value != null) profile[key] = value;
    }

    if (_vehicleType == 'CAR') {
      addOptional('car_size', _carSize);
      addOptional('vehicle_plate_number', optional(_plate));
      addOptional('vehicle_color', optional(_color));
      addOptional('vehicle_make', optional(_make));
      addOptional('vehicle_model', optional(_model));
      addOptional('vehicle_year', _vehicleYear);
    }
    profile['driving_license'] = _drivingLicense.text.trim();
    profile['id_document'] = _idDocument.text.trim();
    profile['health_insurance_document'] = _healthInsurance.text.trim();
    profile['address_document'] = _addressDocument.text.trim();
    profile['bank_document'] = _bankDocument.text.trim();
    addOptional('other_documents', optional(_otherDocuments));

    final payload = <String, dynamic>{
      'user': buildManagedUserPayload(
        name: _name.text,
        phone: buildInternationalPhone(_phoneCountry.dialCode, _phone.text),
        email: _email.text,
        birthdate: _birthdate,
      ),
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
      'profile': profile,
    };
    final notes = optional(_notes);
    if (notes != null) payload['notes'] = notes;
    return payload;
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
      await context.read<AdminProvider>().createDriver(_payload());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.driverCreatedSuccessfully)));
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
