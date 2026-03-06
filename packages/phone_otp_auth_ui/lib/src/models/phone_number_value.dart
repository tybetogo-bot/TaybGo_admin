import 'country.dart';

class PhoneNumberValue {
  const PhoneNumberValue({
    required this.country,
    required this.nationalNumber,
  });

  final Country country;
  final String nationalNumber;

  String get digitsOnly => nationalNumber.replaceAll(RegExp(r'\D'), '');

  String get fullNumber => '${country.dialCode}$digitsOnly';
}
