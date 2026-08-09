import 'package:flutter_test/flutter_test.dart';
import 'package:taybgoadmin/core/utils/country_flags.dart';

void main() {
  test('uses the API ISO code when available', () {
    expect(resolveCountryIsoCode(isoCode: 'be'), 'BE');
    expect(countryFlagEmoji(isoCode: 'be'), '🇧🇪');
  });

  test('fills missing country codes from country names', () {
    expect(resolveCountryIsoCode(countryName: 'Belgium'), 'BE');
    expect(resolveCountryIsoCode(countryName: 'Saudi Arabia'), 'SA');
    expect(countryFlagEmoji(countryName: 'Lebanon'), '🇱🇧');
  });

  test('supports common ISO-3 country codes', () {
    expect(resolveCountryIsoCode(isoCode: 'JOR'), 'JO');
    expect(countryFlagEmoji(isoCode: 'AUT'), '🇦🇹');
  });
}
