import 'package:flutter_test/flutter_test.dart';
import 'package:taybgoadmin/features/management/managed_entity_form_support.dart';

void main() {
  test('common validation accepts valid account and coordinates', () {
    final errors = ManagedEntityValidation.validateCommon(
      name: 'Alex Driver',
      phone: '+32 470 00 00 00',
      email: 'alex@example.com',
      label: 'home',
      latitude: '50.850346',
      longitude: '4.351721',
      fullAddress: 'Central Brussels',
      city: 'Brussels',
      country: 'Belgium',
      requiredMessage: 'required',
      invalidPhoneMessage: 'phone',
      invalidEmailMessage: 'email',
      invalidLatitudeMessage: 'latitude',
      invalidLongitudeMessage: 'longitude',
    );

    expect(errors, isEmpty);
  });

  test('common validation reports required and range errors by API key', () {
    final errors = ManagedEntityValidation.validateCommon(
      name: '',
      phone: 'abc',
      email: 'invalid',
      label: '',
      latitude: '91',
      longitude: '-181',
      fullAddress: '',
      city: '',
      country: '',
      requiredMessage: 'required',
      invalidPhoneMessage: 'phone',
      invalidEmailMessage: 'email',
      invalidLatitudeMessage: 'latitude',
      invalidLongitudeMessage: 'longitude',
    );

    expect(errors['user.name'], 'required');
    expect(errors['user.phone'], 'phone');
    expect(errors['user.email'], 'email');
    expect(errors['address.lat'], 'latitude');
    expect(errors['address.lng'], 'longitude');
    expect(errors['address.full_address'], 'required');
  });

  test('payload helpers omit empty optional values', () {
    final user = buildManagedUserPayload(
      name: '  Sam Owner ',
      phone: ' +32471111111 ',
      email: ' ',
    );
    final address = buildManagedAddressPayload(
      label: ' restaurant ',
      latitude: ' 50.85 ',
      longitude: ' 4.35 ',
      fullAddress: ' Grand Place ',
      city: ' Brussels ',
      country: ' Belgium ',
      streetName: ' ',
    );

    expect(user, {'name': 'Sam Owner', 'phone': '+32471111111'});
    expect(address.containsKey('street_name'), isFalse);
    expect(address['city'], 'Brussels');
  });

  test('international phone helper combines country code and local number', () {
    expect(buildInternationalPhone('+32', '470 00-00-00'), '+32470000000');
    expect(buildInternationalPhone('+43', '+32 470 00 00 00'), '+32470000000');
  });

  test('vehicle year selector spans 1960 through next year', () {
    final years = buildManagedVehicleYears(2026);
    expect(years.first, 2027);
    expect(years.last, 1960);
    expect(years, hasLength(68));
  });

  test('work hours are converted from local time to UTC and wrap the week', () {
    final hours = {
      for (final day in managedWeekdayKeys) day: const DailyHours(),
      'monday': const DailyHours(
        enabled: true,
        openMinutes: 9 * 60,
        closeMinutes: 22 * 60,
      ),
      'sunday': const DailyHours(
        enabled: true,
        openMinutes: 1 * 60,
        closeMinutes: 3 * 60,
      ),
    };

    final utc = buildUtcWorkHours(
      hours,
      timezoneOffset: const Duration(hours: 2),
    );

    expect(utc['monday'], [
      {'open': '07:00', 'close': '20:00'},
    ]);
    expect(utc['saturday'], [
      {'open': '23:00', 'close': '01:00'},
    ]);
  });

  test('URL validation permits empty and HTTP links only', () {
    expect(ManagedEntityValidation.isHttpUrl(''), isTrue);
    expect(
      ManagedEntityValidation.isHttpUrl('https://cdn.example.com/id.pdf'),
      isTrue,
    );
    expect(ManagedEntityValidation.isHttpUrl('file:///tmp/id.pdf'), isFalse);
    expect(ManagedEntityValidation.isHttpUrl('not-a-url'), isFalse);
  });
}
