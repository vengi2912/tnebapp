import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A labeled numeric input field that:
///  - accepts decimals (e.g. "123.5" units)
///  - rejects negative numbers and invalid characters
///  - shows an inline validation error message
class NumberInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? suffixText;
  final IconData? prefixIcon;

  const NumberInputField({
    super.key,
    required this.label,
    required this.controller,
    this.suffixText = 'units',
    this.prefixIcon,
  });

  String? _validate(String? value) {
    if (value == null || value.trim().isEmpty) return null; // allow empty -> 0
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0) return 'Cannot be negative';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        validator: _validate,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffixText,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        ),
      ),
    );
  }
}
