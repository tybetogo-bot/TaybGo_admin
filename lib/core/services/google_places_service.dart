import 'dart:convert';

import 'package:http/http.dart' as http;

class GooglePlaceSuggestion {
  const GooglePlaceSuggestion({
    required this.placeId,
    required this.fullText,
    required this.primaryText,
    this.secondaryText,
  });

  final String placeId;
  final String fullText;
  final String primaryText;
  final String? secondaryText;
}

class GooglePlaceAddress {
  const GooglePlaceAddress({
    required this.placeId,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.streetName,
    this.houseNumber,
    this.city,
    this.postalCode,
    this.country,
  });

  final String placeId;
  final String fullAddress;
  final String latitude;
  final String longitude;
  final String? streetName;
  final String? houseNumber;
  final String? city;
  final String? postalCode;
  final String? country;
}

class GooglePlacesException implements Exception {
  const GooglePlacesException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'GooglePlacesException($message)';
}

/// Client for the Google Places API (New) autocomplete + details flow.
class GooglePlacesService {
  GooglePlacesService({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  static const _baseUrl = 'https://places.googleapis.com/v1';
  static const _autocompleteFieldMask =
      'suggestions.placePrediction.placeId,'
      'suggestions.placePrediction.text.text,'
      'suggestions.placePrediction.structuredFormat.mainText.text,'
      'suggestions.placePrediction.structuredFormat.secondaryText.text';
  static const _detailsFieldMask =
      'id,formattedAddress,shortFormattedAddress,postalAddress,'
      'addressComponents,location';

  final String apiKey;
  final http.Client _client;

  Future<List<GooglePlaceSuggestion>> autocomplete({
    required String input,
    required String sessionToken,
    String? languageCode,
  }) async {
    final normalizedInput = input.trim();
    if (normalizedInput.length < 3) return const [];

    final response = await _client.post(
      Uri.parse('$_baseUrl/places:autocomplete'),
      headers: _headers(_autocompleteFieldMask),
      body: jsonEncode({
        'input': normalizedInput,
        'sessionToken': sessionToken,
        if (_isNonEmpty(languageCode)) 'languageCode': languageCode,
      }),
    );
    final data = _decodeResponse(response);
    final suggestions = data['suggestions'];
    if (suggestions is! List) return const [];

    return suggestions
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .map((item) => item['placePrediction'])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .map(_suggestionFromJson)
        .whereType<GooglePlaceSuggestion>()
        .take(5)
        .toList(growable: false);
  }

  Future<GooglePlaceAddress> resolveAddress({
    required GooglePlaceSuggestion suggestion,
    required String sessionToken,
    String? languageCode,
  }) async {
    final uri =
        Uri.parse(
          '$_baseUrl/places/${Uri.encodeComponent(suggestion.placeId)}',
        ).replace(
          queryParameters: {
            'sessionToken': sessionToken,
            if (_isNonEmpty(languageCode)) 'languageCode': languageCode!,
          },
        );
    final response = await _client.get(
      uri,
      headers: _headers(_detailsFieldMask),
    );
    final data = _decodeResponse(response);
    final location = data['location'];
    if (location is! Map) {
      throw const GooglePlacesException(
        'The selected place did not include coordinates.',
      );
    }

    final latitude = (location['latitude'] as num?)?.toDouble();
    final longitude = (location['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) {
      throw const GooglePlacesException(
        'The selected place did not include valid coordinates.',
      );
    }

    final components = _addressComponents(data['addressComponents']);
    final postalAddress = data['postalAddress'] is Map
        ? (data['postalAddress'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final fullAddress = _firstNonEmpty([
      data['formattedAddress']?.toString(),
      data['shortFormattedAddress']?.toString(),
      suggestion.fullText,
    ]);
    if (fullAddress == null) {
      throw const GooglePlacesException(
        'The selected place did not include a formatted address.',
      );
    }

    return GooglePlaceAddress(
      placeId: suggestion.placeId,
      fullAddress: fullAddress,
      latitude: latitude.toStringAsFixed(6),
      longitude: longitude.toStringAsFixed(6),
      streetName: _component(components, 'route'),
      houseNumber: _component(components, 'street_number'),
      city: _firstNonEmpty([
        _component(components, 'locality'),
        _component(components, 'postal_town'),
        postalAddress['locality']?.toString(),
        _component(components, 'administrative_area_level_2'),
        _component(components, 'administrative_area_level_1'),
      ]),
      postalCode: _firstNonEmpty([
        _component(components, 'postal_code'),
        postalAddress['postalCode']?.toString(),
      ]),
      country: _firstNonEmpty([
        _component(components, 'country'),
        postalAddress['regionCode']?.toString(),
      ]),
    );
  }

  void close() => _client.close();

  Map<String, String> _headers(String fieldMask) => {
    'Content-Type': 'application/json',
    'X-Goog-Api-Key': apiKey,
    'X-Goog-FieldMask': fieldMask,
  };

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(response.body);
      data = decoded is Map
          ? decoded.cast<String, dynamic>()
          : <String, dynamic>{};
    } on FormatException {
      throw GooglePlacesException(
        'Google Places returned an invalid response.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = data['error'];
      final errorMap = error is Map
          ? error.cast<String, dynamic>()
          : const <String, dynamic>{};
      throw GooglePlacesException(
        errorMap['message']?.toString() ?? 'Google Places request failed.',
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  GooglePlaceSuggestion? _suggestionFromJson(Map<String, dynamic> json) {
    final placeId = _normalize(json['placeId']?.toString());
    final text = json['text'];
    final textMap = text is Map
        ? text.cast<String, dynamic>()
        : const <String, dynamic>{};
    final structured = json['structuredFormat'];
    final structuredMap = structured is Map
        ? structured.cast<String, dynamic>()
        : const <String, dynamic>{};
    final mainText = structuredMap['mainText'];
    final secondaryText = structuredMap['secondaryText'];
    final primary = mainText is Map
        ? _normalize(mainText['text']?.toString())
        : null;
    final secondary = secondaryText is Map
        ? _normalize(secondaryText['text']?.toString())
        : null;
    final fullText = _normalize(textMap['text']?.toString());
    if (placeId == null || fullText == null) return null;

    return GooglePlaceSuggestion(
      placeId: placeId,
      fullText: fullText,
      primaryText: primary ?? fullText,
      secondaryText: secondary,
    );
  }

  List<Map<String, dynamic>> _addressComponents(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }

  String? _component(List<Map<String, dynamic>> components, String type) {
    for (final component in components) {
      final types = component['types'];
      if (types is List && types.contains(type)) {
        return _normalize(component['longText']?.toString());
      }
    }
    return null;
  }

  String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final normalized = _normalize(value);
      if (normalized != null) return normalized;
    }
    return null;
  }

  bool _isNonEmpty(String? value) => _normalize(value) != null;

  String? _normalize(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
