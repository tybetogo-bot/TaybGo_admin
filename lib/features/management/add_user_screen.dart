import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/country.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'managed_entity_form_support.dart';
import 'managed_entity_form_widgets.dart';
import 'managed_phone_field.dart';

enum _AccountType { customer, restaurant }

extension on _AccountType {
  String get apiRole => this == _AccountType.customer ? 'customer' : 'seller';
}

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  Country _phoneCountry = Country.defaultCountry;
  _AccountType? _accountType;
  Map<String, String> _errors = const {};
  String? _formError;
  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _selectAccountType(_AccountType type) {
    setState(() {
      _accountType = type;
      _errors = Map.of(_errors)..remove('role');
      if (_errors.isEmpty) _formError = null;
    });
  }

  void _clearError(String key) {
    if (!_errors.containsKey(key)) return;
    setState(() {
      _errors = Map.of(_errors)..remove(key);
      if (_errors.isEmpty) _formError = null;
    });
  }

  void _generatePassword() {
    setState(() {
      _passwordController.text = generateManagedPassword();
      _obscurePassword = false;
      _errors = Map.of(_errors)..remove('password');
      if (_errors.isEmpty) _formError = null;
    });
  }

  Future<void> _copyPassword() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: password));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).passwordCopied)),
    );
  }

  Map<String, String> _validate(AppLocalizations l) {
    final errors = <String, String>{};
    final name = _nameController.text.trim();
    final phone = buildInternationalPhone(
      _phoneCountry.dialCode,
      _phoneController.text,
    );
    final password = _passwordController.text;

    if (_accountType == null) errors['role'] = l.selectAccountTypeError;
    if (name.isEmpty) {
      errors['name'] = l.requiredField;
    } else if (name.length > 255) {
      errors['name'] = 'Maximum 255 characters.';
    }
    if (_phoneController.text.trim().isEmpty) {
      errors['phone'] = l.requiredField;
    } else if (!RegExp(r'^\+[0-9]{7,19}$').hasMatch(phone)) {
      errors['phone'] = l.invalidPhone;
    }
    if (password.isEmpty) {
      errors['password'] = l.requiredField;
    } else if (password.length < 8) {
      errors['password'] = l.passwordTooShort;
    } else if (password.length > 128) {
      errors['password'] = 'Maximum 128 characters.';
    }
    return errors;
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final errors = _validate(l);
    if (errors.isNotEmpty) {
      setState(() {
        _errors = errors;
        _formError = l.correctHighlightedFields;
      });
      return;
    }

    setState(() {
      _errors = const {};
      _formError = null;
      _submitting = true;
    });

    final payload = <String, dynamic>{
      'phone': buildInternationalPhone(
        _phoneCountry.dialCode,
        _phoneController.text,
      ),
      'password': _passwordController.text,
      'role': _accountType!.apiRole,
      'name': _nameController.text.trim(),
    };

    try {
      await context.read<AdminProvider>().createUser(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.userCreatedSuccessfully)));
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      final fieldErrors = Map<String, String>.of(error.fieldErrors);
      if (error.statusCode == 409) {
        fieldErrors['phone'] = l.duplicatePhone;
      }
      setState(() {
        _errors = fieldErrors;
        _formError = fieldErrors.isEmpty
            ? error.message
            : error.statusCode == 409
            ? l.duplicatePhone
            : l.serverRejectedFields;
      });
    } catch (_) {
      if (mounted) setState(() => _formError = l.connectionError);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ManagedFormScaffold(
      title: l.addUserTitle,
      subtitle: l.addUserSubtitle,
      icon: Icons.person_add_alt_1_rounded,
      cancelLabel: l.cancel,
      submitLabel: l.addUserAction,
      isSubmitting: _submitting,
      formError: _formError,
      onSubmit: _submit,
      showHero: false,
      child: Column(
        children: [
          _MinimalFormSection(
            title: l.chooseAccountType,
            description: l.chooseAccountTypeDescription,
            icon: Icons.badge_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 620;
                    final cards = [
                      _AccountTypeCard(
                        key: const Key('add-user-role-customer'),
                        title: l.customerAccount,
                        description: l.customerAccountDescription,
                        icon: Icons.shopping_bag_outlined,
                        selected: _accountType == _AccountType.customer,
                        onTap: () => _selectAccountType(_AccountType.customer),
                      ),
                      _AccountTypeCard(
                        key: const Key('add-user-role-restaurant'),
                        title: l.restaurantAccount,
                        description: l.restaurantAccountDescription,
                        icon: Icons.storefront_outlined,
                        selected: _accountType == _AccountType.restaurant,
                        onTap: () =>
                            _selectAccountType(_AccountType.restaurant),
                      ),
                    ];
                    if (!wide) {
                      return Column(
                        children: [
                          cards.first,
                          const SizedBox(height: 12),
                          cards.last,
                        ],
                      );
                    }
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: cards.first),
                          const SizedBox(width: 12),
                          Expanded(child: cards.last),
                        ],
                      ),
                    );
                  },
                ),
                if (_errors['role'] case final error?) ...[
                  const SizedBox(height: 8),
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _AccountOnlyNotice(
                  title: l.accountOnlyNoticeTitle,
                  message: l.accountOnlyNotice,
                ),
              ],
            ),
          ),
          _MinimalFormSection(
            title: l.userDetails,
            description: l.userDetailsDescription,
            icon: Icons.person_outline_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ManagedFieldGrid(
                  children: [
                    ManagedTextField(
                      key: const Key('add-user-name'),
                      controller: _nameController,
                      label: '${l.name} *',
                      icon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      errorText: _errors['name'],
                    ),
                    ManagedPhoneField(
                      key: const Key('add-user-phone'),
                      controller: _phoneController,
                      country: _phoneCountry,
                      onCountryChanged: (country) {
                        setState(() => _phoneCountry = country);
                        _clearError('phone');
                      },
                      label: '${l.phone} *',
                      errorText: _errors['phone'],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('add-user-password'),
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enableSuggestions: false,
                  autocorrect: false,
                  onChanged: (_) => _clearError('password'),
                  decoration: managedInputDecoration(
                    context,
                    label: '${l.password} *',
                    helperText: l.passwordHelp,
                    errorText: _errors['password'],
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? 'Show' : 'Hide',
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('generate-password'),
                      onPressed: _generatePassword,
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(l.generatePassword),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.68),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    if (_passwordController.text.isNotEmpty)
                      TextButton.icon(
                        key: const Key('copy-password'),
                        onPressed: _copyPassword,
                        icon: const Icon(Icons.copy_rounded, size: 17),
                        label: Text(l.copyPassword),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalFormSection extends StatelessWidget {
  const _MinimalFormSection({
    required this.title,
    required this.icon,
    required this.child,
    this.description,
  });

  final String title;
  final String? description;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  icon,
                  size: 20,
                  color: scheme.onSurface.withValues(alpha: 0.52),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.035)
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : scheme.outline.withValues(alpha: 0.16),
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 21,
                    color: selected
                        ? AppColors.primary
                        : scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (selected)
                            Container(
                              width: 19,
                              height: 19,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.58),
                          height: 1.35,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
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

class _AccountOnlyNotice extends StatelessWidget {
  const _AccountOnlyNotice({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: scheme.onSurface.withValues(alpha: 0.48),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.64),
                    height: 1.35,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
