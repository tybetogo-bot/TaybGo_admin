import 'package:flutter_test/flutter_test.dart';
import 'package:taybgoadmin/core/partner_search.dart';

void main() {
  test('matches names and addresses case-insensitively', () {
    expect(matchesPartnerSearch('  ibrahim  ', ['Ibrahim Driving']), isTrue);
    expect(
      matchesPartnerSearch('vienna', ['Stephansplatz 1, 1010 Vienna, Austria']),
      isTrue,
    );
  });

  test('matches phone searches with common separators', () {
    expect(matchesPartnerSearch('43 900-0005', ['+439000005']), isTrue);
    expect(matchesPartnerSearch('9999', ['+439000005']), isFalse);
    expect(matchesPartnerSearch('AB 123', ['AB-123']), isFalse);
  });

  test('normalizes phone-like input for the backend search contract', () {
    expect(backendPartnerSearchQuery(' +43 900-0005 '), '439000005');
    expect(backendPartnerSearchQuery('Ibrahim Driving'), 'Ibrahim Driving');
    expect(backendPartnerSearchQuery('AB-123'), 'AB-123');
  });

  test('empty queries match every field', () {
    expect(matchesPartnerSearch('   ', ['Any partner']), isTrue);
  });
}
