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
    label: '1.0.5+6',
    releasedAt: DateTime(2026, 8, 9),
    isCurrent: true,
  );

  static final releases = [
    current,
    AppRelease(label: '1.0.3+4', releasedAt: DateTime(2026, 4, 17)),
    AppRelease(label: '1.0.2+3', releasedAt: DateTime(2026, 4, 17)),
    AppRelease(label: '1.0.1+2', releasedAt: DateTime(2026, 4, 16)),
    AppRelease(label: '1.0.0+1', releasedAt: DateTime(2026, 2, 25)),
  ];
}
