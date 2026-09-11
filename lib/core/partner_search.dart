String normalizePartnerSearch(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

String _compactPartnerSearch(String value) {
  return normalizePartnerSearch(value).replaceAll(RegExp(r'[\s\-()+/.]+'), '');
}

/// Returns the value that the admin partner endpoints can search reliably.
///
/// The backend searches phone values with a case-insensitive substring query.
/// Phone numbers are stored canonically, so remove presentation separators
/// from phone-like input before sending it while leaving names, emails, and
/// vehicle plates untouched.
String backendPartnerSearchQuery(String value) {
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) return '';

  return _isPhoneLikeSearch(normalized)
      ? _compactPartnerSearch(normalized)
      : normalized;
}

bool matchesPartnerSearch(String query, Iterable<String> fields) {
  final normalizedQuery = normalizePartnerSearch(query);
  if (normalizedQuery.isEmpty) return true;

  final phoneLike = _isPhoneLikeSearch(normalizedQuery);
  final compactQuery = phoneLike ? _compactPartnerSearch(normalizedQuery) : '';
  return fields.any((field) {
    final normalizedField = normalizePartnerSearch(field);
    return normalizedField.contains(normalizedQuery) ||
        (phoneLike &&
            compactQuery.isNotEmpty &&
            _compactPartnerSearch(normalizedField).contains(compactQuery));
  });
}

bool _isPhoneLikeSearch(String value) {
  return RegExp(r'^[+\d\s()\-/.]+$').hasMatch(value) &&
      RegExp(r'\d').hasMatch(value);
}
