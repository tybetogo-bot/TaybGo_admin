class AppRelease {
  final String label;
  final DateTime releasedAt;
  final bool isCurrent;

  const AppRelease({
    required this.label,
    required this.releasedAt,
    this.isCurrent = false,
  });
}

class AppReleaseHistory {
  AppReleaseHistory._();

  static final current = AppRelease(
    label: '1.0.11+12',
    releasedAt: DateTime(2026, 9, 12),
    isCurrent: true,
  );

  static final releases = [
    current,
    AppRelease(label: '1.0.10+11', releasedAt: DateTime(2026, 8, 24)),
    AppRelease(label: '1.0.9+10', releasedAt: DateTime(2026, 8, 22)),
    AppRelease(label: '1.0.8+9', releasedAt: DateTime(2026, 8, 20)),
    AppRelease(label: '1.0.7+8', releasedAt: DateTime(2026, 8, 11)),
    AppRelease(label: '1.0.6+7', releasedAt: DateTime(2026, 8, 10)),
    AppRelease(label: '1.0.5+6', releasedAt: DateTime(2026, 8, 9)),
    AppRelease(label: '1.0.3+4', releasedAt: DateTime(2026, 4, 17)),
    AppRelease(label: '1.0.2+3', releasedAt: DateTime(2026, 4, 17)),
    AppRelease(label: '1.0.1+2', releasedAt: DateTime(2026, 4, 16)),
    AppRelease(label: '1.0.0+1', releasedAt: DateTime(2026, 2, 25)),
  ];
}
