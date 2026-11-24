class PublicAppConfig {
  const PublicAppConfig({
    required this.otpEnabledRoles,
    required this.passwordOnlyRoles,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.forceUpdate,
    required this.updateUrl,
    required this.privacyUrl,
    required this.termsUrl,
    required this.supportUrl,
  });

  final List<String> otpEnabledRoles;
  final List<String> passwordOnlyRoles;
  final String latestVersion;
  final String minSupportedVersion;
  final bool forceUpdate;
  final String? updateUrl;
  final String privacyUrl;
  final String termsUrl;
  final String supportUrl;

  bool usesOtpFor(String role) =>
      otpEnabledRoles.contains(role) && !passwordOnlyRoles.contains(role);

  factory PublicAppConfig.fromJson(Map<String, dynamic> json) {
    return PublicAppConfig(
      otpEnabledRoles: _strings(json['auth.otp_enabled_roles']),
      passwordOnlyRoles: _strings(json['auth.password_only_roles']),
      latestVersion: _required(json, 'app.latest_version'),
      minSupportedVersion: _required(json, 'app.min_supported_version'),
      forceUpdate: json['app.force_update'] == true,
      updateUrl: _nullable(json['app.update_url']),
      privacyUrl: _required(json, 'legal.privacy_url'),
      termsUrl: _required(json, 'legal.terms_url'),
      supportUrl: _required(json, 'legal.support_url'),
    );
  }

  static List<String> _strings(dynamic value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const [];

  static String _required(Map<String, dynamic> json, String key) {
    final value = _nullable(json[key]);
    if (value == null) throw FormatException('Invalid public config: $key');
    return value;
  }

  static String? _nullable(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }
}
