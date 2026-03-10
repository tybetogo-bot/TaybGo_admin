import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/auth_ui_strings.dart';
import '../models/country.dart';

class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
    required this.controller,
    required this.selectedCountry,
    required this.onCountryTap,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.strings = const AuthUiStrings(),
    this.autofocus = false,
  });

  final TextEditingController controller;
  final Country selectedCountry;
  final VoidCallback onCountryTap;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final AuthUiStrings strings;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: onSubmitted,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        hintText: strings.phoneHintText,
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
        prefixIcon: InkWell(
          onTap: enabled ? onCountryTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedCountry.flag,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 6),
                Text(
                  selectedCountry.dialCode,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
      validator: validator,
    );
  }
}
