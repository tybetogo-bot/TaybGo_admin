import 'package:flutter_test/flutter_test.dart';
import 'package:taybgoadmin/core/models/home_response.dart';

void main() {
  const addressJson = {
    'label': 'Home',
    'lat': '24.713600',
    'lng': '46.675300',
    'full_address': '12 King Street, Riyadh',
    'street_name': 'King Street',
    'house_number': '12',
    'city': 'Riyadh',
    'postal_code': '12345',
    'country': 'SA',
    'is_default': true,
  };

  test(
    'parses optional address on live drivers without replacing GPS data',
    () {
      final driver = DriverWithLocation.fromJson({
        'id': 7,
        'name': 'Driver User',
        'phone': '+4390004',
        'is_online': true,
        'latitude': '50.862941',
        'longitude': '4.370741',
        'address': addressJson,
      });

      expect(driver.address?.label, 'Home');
      expect(driver.address?.city, 'Riyadh');
      expect(driver.address?.displayLine, '12 King Street, Riyadh');
      expect(driver.address?.hasCoordinates, isTrue);
      expect(driver.address?.isDefault, isTrue);
      expect(driver.latitude, '50.862941');
      expect(driver.longitude, '4.370741');

      final profile = DriverProfile.fromDriverWithLocation(driver);
      expect(profile.address?.country, 'SA');
      expect(profile.latitude, '50.862941');
      expect(profile.longitude, '4.370741');
    },
  );

  test('parses an address nested inside a driver profile response', () {
    final profile = DriverProfile.fromJson({
      'driver': {
        'id': 8,
        'name': 'Nested Driver',
        'phone': '+4390005',
        'address': addressJson,
      },
    });

    expect(profile.id, 8);
    expect(profile.address?.fullAddress, '12 King Street, Riyadh');
    expect(profile.hasAddress, isTrue);
  });

  test('keeps absent or empty addresses null-safe', () {
    final driver = DriverWithLocation.fromJson({
      'id': 9,
      'name': 'No Address',
      'phone': '+4390006',
      'is_online': false,
      'address': null,
    });
    final empty = DriverProfile.fromJson({'id': 10, 'address': {}});

    expect(driver.address, isNull);
    expect(empty.address, isNull);
    expect(empty.hasAddress, isFalse);
  });
}
