class ManagedEntityValidation {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9 ()-]{7,20}$');

  static Map<String, String> validateCommon({
    required String name,
    required String phone,
    required String email,
    required String label,
    required String latitude,
    required String longitude,
    required String fullAddress,
    required String city,
    required String country,
    required String requiredMessage,
    required String invalidPhoneMessage,
    required String invalidEmailMessage,
    required String invalidLatitudeMessage,
    required String invalidLongitudeMessage,
  }) {
    final errors = <String, String>{};

    void require(String key, String value) {
      if (value.trim().isEmpty) errors[key] = requiredMessage;
    }

    require('user.name', name);
    require('user.phone', phone);
    require('address.label', label);
    require('address.lat', latitude);
    require('address.lng', longitude);
    require('address.full_address', fullAddress);
    require('address.city', city);
    require('address.country', country);

    if (phone.trim().isNotEmpty && !_phonePattern.hasMatch(phone.trim())) {
      errors['user.phone'] = invalidPhoneMessage;
    }
    if (email.trim().isNotEmpty && !_emailPattern.hasMatch(email.trim())) {
      errors['user.email'] = invalidEmailMessage;
    }

    final lat = double.tryParse(latitude.trim());
    if (latitude.trim().isNotEmpty && (lat == null || lat < -90 || lat > 90)) {
      errors['address.lat'] = invalidLatitudeMessage;
    }
    final lng = double.tryParse(longitude.trim());
    if (longitude.trim().isNotEmpty &&
        (lng == null || lng < -180 || lng > 180)) {
      errors['address.lng'] = invalidLongitudeMessage;
    }

    return errors;
  }

  static bool isHttpUrl(String value) {
    final text = value.trim();
    if (text.isEmpty) return true;
    final uri = Uri.tryParse(text);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}

String buildInternationalPhone(String dialCode, String nationalNumber) {
  final input = nationalNumber.trim();
  final normalized = input.replaceAll(RegExp(r'[^0-9+]'), '');
  if (normalized.startsWith('+')) return normalized;
  final prefix = dialCode.trim().replaceAll(RegExp(r'[^0-9+]'), '');
  return '$prefix$normalized';
}

List<int> buildManagedVehicleYears(int currentYear) {
  final maximumYear = currentYear + 1;
  return List<int>.generate(
    maximumYear - 1960 + 1,
    (index) => maximumYear - index,
  );
}

Map<String, dynamic> buildManagedUserPayload({
  required String name,
  required String phone,
  String? email,
  DateTime? birthdate,
}) {
  return {
    'name': name.trim(),
    'phone': phone.trim(),
    if (email?.trim().isNotEmpty == true) 'email': email!.trim(),
    if (birthdate != null)
      'birthdate':
          '${birthdate.year.toString().padLeft(4, '0')}-'
          '${birthdate.month.toString().padLeft(2, '0')}-'
          '${birthdate.day.toString().padLeft(2, '0')}',
  };
}

Map<String, dynamic> buildManagedAddressPayload({
  required String label,
  required String latitude,
  required String longitude,
  required String fullAddress,
  required String city,
  required String country,
  String? streetName,
  String? houseNumber,
  String? postalCode,
}) {
  return {
    'label': label.trim(),
    'lat': latitude.trim(),
    'lng': longitude.trim(),
    'full_address': fullAddress.trim(),
    'city': city.trim(),
    'country': country.trim(),
    if (streetName?.trim().isNotEmpty == true)
      'street_name': streetName!.trim(),
    if (houseNumber?.trim().isNotEmpty == true)
      'house_number': houseNumber!.trim(),
    if (postalCode?.trim().isNotEmpty == true)
      'postal_code': postalCode!.trim(),
  };
}

class DailyHours {
  final bool enabled;
  final int openMinutes;
  final int closeMinutes;

  const DailyHours({
    this.enabled = false,
    this.openMinutes = 9 * 60,
    this.closeMinutes = 22 * 60,
  });

  DailyHours copyWith({bool? enabled, int? openMinutes, int? closeMinutes}) {
    return DailyHours(
      enabled: enabled ?? this.enabled,
      openMinutes: openMinutes ?? this.openMinutes,
      closeMinutes: closeMinutes ?? this.closeMinutes,
    );
  }
}

const managedWeekdayKeys = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

Map<String, List<Map<String, String>>> buildUtcWorkHours(
  Map<String, DailyHours> localHours, {
  Duration? timezoneOffset,
}) {
  final offset = (timezoneOffset ?? DateTime.now().timeZoneOffset).inMinutes;
  const dayMinutes = 24 * 60;
  const weekMinutes = 7 * dayMinutes;
  final result = {
    for (final day in managedWeekdayKeys) day: <Map<String, String>>[],
  };

  for (
    var localDayIndex = 0;
    localDayIndex < managedWeekdayKeys.length;
    localDayIndex++
  ) {
    final hours = localHours[managedWeekdayKeys[localDayIndex]];
    if (hours == null || !hours.enabled) continue;

    final close = hours.closeMinutes <= hours.openMinutes
        ? hours.closeMinutes + dayMinutes
        : hours.closeMinutes;
    var utcStart = localDayIndex * dayMinutes + hours.openMinutes - offset;
    var utcEnd = localDayIndex * dayMinutes + close - offset;
    while (utcStart < 0) {
      utcStart += weekMinutes;
      utcEnd += weekMinutes;
    }
    while (utcStart >= weekMinutes) {
      utcStart -= weekMinutes;
      utcEnd -= weekMinutes;
    }

    final utcDay = (utcStart ~/ dayMinutes) % 7;
    result[managedWeekdayKeys[utcDay]]!.add({
      'open': _formatMinutes(utcStart % dayMinutes),
      'close': _formatMinutes(utcEnd % dayMinutes),
    });
  }

  for (final ranges in result.values) {
    ranges.sort((a, b) => a['open']!.compareTo(b['open']!));
  }
  return result;
}

String _formatMinutes(int minutes) {
  final normalized = minutes % (24 * 60);
  final hour = normalized ~/ 60;
  final minute = normalized % 60;
  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}
