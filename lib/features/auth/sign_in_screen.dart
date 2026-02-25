import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/country.dart';
import 'country_picker_dialog.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Country _selectedCountry = Country.defaultCountry;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _openCountryPicker() async {
    final country = await showDialog<Country>(
      context: context,
      builder: (_) => CountryPickerDialog(selected: _selectedCountry),
    );
    if (country != null) {
      setState(() => _selectedCountry = country);
    }
  }

  Future<void> _handleRequestOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final phone = '${_selectedCountry.dialCode}${_phoneController.text.trim()}';
    final success = await auth.requestOtp(phone);
    if (success && mounted) {
      context.go('/verify-otp');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          if (isWide) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF0A1A0F), const Color(0xFF0A0F0A)]
                            : [const Color(0xFFF0FAF2), const Color(0xFFFAFAFA)],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/TaybGo_green.png', width: 180),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            child: Text(
                              l.adminDashboard,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 60),
                            child: Text(
                              l.manageDescription,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: _buildForm(context, auth, theme, l),
                ),
              ],
            );
          }
          return _buildForm(context, auth, theme, l, showLogo: true);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, AuthProvider auth, ThemeData theme,
      AppLocalizations l,
      {bool showLogo = false}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Language selector
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _LanguageSelector(),
                ),
                const SizedBox(height: 8),
                if (showLogo) ...[
                  Center(
                    child: Image.asset('assets/TaybGo_green.png', width: 130),
                  ),
                  const SizedBox(height: 40),
                ],
                Text(
                  l.welcomeBack,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.enterPhoneToSignIn,
                  style: TextStyle(
                    fontSize: 15,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 32),

                // Phone number
                _FieldLabel(l.phoneNumber),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRequestOtp(),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    hintText: '5XXXXXXXX',
                    prefixIcon: InkWell(
                      onTap: _openCountryPicker,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedCountry.flag,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _selectedCountry.dialCode,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 18,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return l.enterYourPhone;
                    }
                    return null;
                  },
                ),

                if (auth.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              auth.error!,
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 28),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleRequestOtp,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l.sendOtp,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  static const _languages = [
    (locale: Locale('en'), label: 'English', flag: '🇬🇧'),
    (locale: Locale('ar'), label: 'العربية', flag: '🇸🇦'),
    (locale: Locale('nl'), label: 'Nederlands', flag: '🇳🇱'),
    (locale: Locale('fr'), label: 'Français', flag: '🇫🇷'),
    (locale: Locale('de'), label: 'Deutsch', flag: '🇩🇪'),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final current = settings.locale;

    return PopupMenuButton<Locale>(
      tooltip: 'Language',
      onSelected: (locale) => settings.setLocale(locale),
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => _languages.map((lang) {
        final selected = lang.locale.languageCode == current.languageCode;
        return PopupMenuItem<Locale>(
          value: lang.locale,
          child: Row(
            children: [
              Text(lang.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Text(
                lang.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (selected) ...[
                const Spacer(),
                Icon(Icons.check, size: 16, color: AppColors.primary),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Text(
              _languages
                  .firstWhere(
                    (l) => l.locale.languageCode == current.languageCode,
                    orElse: () => _languages.first,
                  )
                  .label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
