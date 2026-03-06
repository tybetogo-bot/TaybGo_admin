import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/auth_ui_strings.dart';
import '../models/country.dart';
import '../models/phone_number_value.dart';
import 'country_picker_dialog.dart';
import 'phone_number_field.dart';

class PhoneSignInForm extends StatefulWidget {
  const PhoneSignInForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.errorText,
    this.countries = Country.all,
    this.initialCountry = Country.defaultCountry,
    this.initialPhoneNumber = '',
    this.autofocus = false,
    this.strings = const AuthUiStrings(),
    this.title,
    this.subtitle,
  });

  final FutureOr<void> Function(PhoneNumberValue value) onSubmit;
  final bool isLoading;
  final String? errorText;
  final List<Country> countries;
  final Country initialCountry;
  final String initialPhoneNumber;
  final bool autofocus;
  final AuthUiStrings strings;
  final Widget? title;
  final Widget? subtitle;

  @override
  State<PhoneSignInForm> createState() => _PhoneSignInFormState();
}

class _PhoneSignInFormState extends State<PhoneSignInForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  late Country _selectedCountry;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhoneNumber);
    _selectedCountry = widget.initialCountry;
  }

  @override
  void didUpdateWidget(covariant PhoneSignInForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCountry != widget.initialCountry) {
      _selectedCountry = widget.initialCountry;
    }
    if (oldWidget.initialPhoneNumber != widget.initialPhoneNumber &&
        widget.initialPhoneNumber != _phoneController.text) {
      _phoneController.text = widget.initialPhoneNumber;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _openCountryPicker() async {
    final selected = await showDialog<Country>(
      context: context,
      builder: (context) => CountryPickerDialog(
        selected: _selectedCountry,
        countries: widget.countries,
        strings: widget.strings,
      ),
    );

    if (selected != null) {
      setState(() => _selectedCountry = selected);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final value = PhoneNumberValue(
      country: _selectedCountry,
      nationalNumber: _phoneController.text.trim(),
    );
    await widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.title ??
              Text(
                widget.strings.phoneSignInTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
          const SizedBox(height: 8),
          widget.subtitle ??
              Text(
                widget.strings.phoneSignInSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
          const SizedBox(height: 24),
          _FieldLabel(widget.strings.phoneNumberLabel),
          const SizedBox(height: 8),
          PhoneNumberField(
            controller: _phoneController,
            selectedCountry: _selectedCountry,
            onCountryTap: _openCountryPicker,
            onSubmitted: (_) => _handleSubmit(),
            enabled: !widget.isLoading,
            autofocus: widget.autofocus,
            strings: widget.strings,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return widget.strings.enterPhoneError;
              }
              return null;
            },
          ),
          if (widget.errorText != null) ...[
            const SizedBox(height: 14),
            _ErrorBanner(text: widget.errorText!),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _handleSubmit,
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.strings.sendOtpLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
