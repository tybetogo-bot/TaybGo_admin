import 'package:flutter/material.dart';

import '../../core/models/country.dart';
import '../auth/country_picker_dialog.dart';
import 'managed_entity_form_widgets.dart';

class ManagedPhoneField extends StatelessWidget {
  const ManagedPhoneField({
    super.key,
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    required this.label,
    this.errorText,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final Country country;
  final ValueChanged<Country> onCountryChanged;
  final String label;
  final String? errorText;
  final Widget? suffixIcon;

  Future<void> _chooseCountry(BuildContext context) async {
    final selected = await showDialog<Country>(
      context: context,
      builder: (_) => CountryPickerDialog(selected: country),
    );
    if (selected != null) onCountryChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      decoration: managedInputDecoration(
        context,
        label: label,
        hint: '470 00 00 00',
        errorText: errorText,
        suffixIcon: suffixIcon,
        prefix: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _chooseCountry(context),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 13, end: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(country.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  country.dialCode,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_drop_down_rounded, size: 20),
                const SizedBox(width: 8),
                SizedBox(
                  height: 25,
                  child: VerticalDivider(
                    width: 1,
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.28),
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
