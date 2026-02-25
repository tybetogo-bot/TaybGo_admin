import 'dart:math';

/// A known city with its center coordinates.
class City {
  final String key;
  final String nameEn;
  final String nameAr;
  final double lat;
  final double lng;

  const City({
    required this.key,
    required this.nameEn,
    required this.nameAr,
    required this.lat,
    required this.lng,
  });
}

/// Locates the nearest known city for a given coordinate.
class CityLocator {
  CityLocator._();

  /// Maximum distance (km) to associate a driver with a city.
  static const double maxDistanceKm = 80;

  static const List<City> cities = [
    City(key: 'riyadh', nameEn: 'Riyadh', nameAr: 'الرياض', lat: 24.7136, lng: 46.6753),
    City(key: 'jeddah', nameEn: 'Jeddah', nameAr: 'جدة', lat: 21.4858, lng: 39.1925),
    City(key: 'mecca', nameEn: 'Mecca', nameAr: 'مكة المكرمة', lat: 21.3891, lng: 39.8579),
    City(key: 'medina', nameEn: 'Medina', nameAr: 'المدينة المنورة', lat: 24.4672, lng: 39.6024),
    City(key: 'dammam', nameEn: 'Dammam', nameAr: 'الدمام', lat: 26.4207, lng: 50.0888),
    City(key: 'khobar', nameEn: 'Khobar', nameAr: 'الخبر', lat: 26.2172, lng: 50.1971),
    City(key: 'dhahran', nameEn: 'Dhahran', nameAr: 'الظهران', lat: 26.2361, lng: 50.0393),
    City(key: 'tabuk', nameEn: 'Tabuk', nameAr: 'تبوك', lat: 28.3838, lng: 36.5550),
    City(key: 'abha', nameEn: 'Abha', nameAr: 'أبها', lat: 18.2164, lng: 42.5053),
    City(key: 'taif', nameEn: 'Taif', nameAr: 'الطائف', lat: 21.2703, lng: 40.4158),
    City(key: 'buraydah', nameEn: 'Buraydah', nameAr: 'بريدة', lat: 26.3260, lng: 43.9750),
    City(key: 'hail', nameEn: 'Hail', nameAr: 'حائل', lat: 27.5114, lng: 41.7208),
    City(key: 'najran', nameEn: 'Najran', nameAr: 'نجران', lat: 17.4933, lng: 44.1277),
    City(key: 'jizan', nameEn: 'Jizan', nameAr: 'جازان', lat: 16.8893, lng: 42.5511),
    City(key: 'yanbu', nameEn: 'Yanbu', nameAr: 'ينبع', lat: 24.0895, lng: 38.0618),
    City(key: 'alahsa', nameEn: 'Al Ahsa', nameAr: 'الأحساء', lat: 25.3948, lng: 49.5870),
    City(key: 'sakaka', nameEn: 'Sakaka', nameAr: 'سكاكا', lat: 29.9697, lng: 40.2064),
    City(key: 'arar', nameEn: 'Arar', nameAr: 'عرعر', lat: 30.9753, lng: 41.0381),
    City(key: 'jubail', nameEn: 'Jubail', nameAr: 'الجبيل', lat: 27.0046, lng: 49.6225),
    City(key: 'khamismushait', nameEn: 'Khamis Mushait', nameAr: 'خميس مشيط', lat: 18.3066, lng: 42.7329),
  ];

  /// Returns the nearest [City] for the given coordinates,
  /// or `null` if no city is within [maxDistanceKm].
  static City? nearest(double lat, double lng) {
    City? best;
    double bestDist = double.infinity;
    for (final city in cities) {
      final d = _haversineKm(lat, lng, city.lat, city.lng);
      if (d < bestDist) {
        bestDist = d;
        best = city;
      }
    }
    if (bestDist > maxDistanceKm) return null;
    return best;
  }

  /// Haversine distance in kilometres.
  static double _haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0; // Earth radius in km
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;
}
