import 'package:dfunc/dfunc.dart';
import 'package:flutter/material.dart';

import '../../l10n/decimal_separator.dart';
import '../../l10n/device_locale.dart';
import 'keypad_key.dart';

class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    super.key,
    required this.controller,
    required this.maxDecimals,
    this.isEnabled = true,
  });

  final TextEditingController controller;
  final int maxDecimals;
  final bool isEnabled;

  static const _keys = [
    KeypadKey.number(number: 1),
    KeypadKey.number(number: 2),
    KeypadKey.number(number: 3),
    KeypadKey.number(number: 4),
    KeypadKey.number(number: 5),
    KeypadKey.number(number: 6),
    KeypadKey.number(number: 7),
    KeypadKey.number(number: 8),
    KeypadKey.number(number: 9),
    KeypadKey.decimalSeparator(),
    KeypadKey.number(number: 0),
    KeypadKey.backspace(),
  ];

  void _manageKey(String key, String decimalSeparator) {
    String value = controller.text;
    if (key == '<') {
      if (value.isNotEmpty) {
        value = value.substring(0, value.length - 1);
      }
    } else if (key == '.') {
      // If we already have it, ignore it
      if (value.contains(decimalSeparator)) return;

      if (value.isEmpty) {
        value = '0$decimalSeparator';
      } else {
        value = '$value$decimalSeparator';
      }
    } else {
      if (value.isEmpty && key == '0') {
        value = '0$decimalSeparator';
      } else {
        value = '$value$key'.replaceFirst(RegExp('^[0]+'), '');
        if (value.startsWith(decimalSeparator)) {
          value = '0$value';
        }
      }
    }

    final decimals = value
        .split(decimalSeparator)
        .let((v) => v.length > 1 ? v[1] : '')
        .let((v) => v.length);

    if (decimals <= maxDecimals) {
      controller.text = value;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final decimalSeparator =
              getDecimalSeparator(DeviceLocale.localeOf(context));

          return AspectRatio(
            aspectRatio: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                childAspectRatio: 4 / 3,
                crossAxisCount: 3,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                children: _keys
                    .map(
                      (KeypadKey child) => Opacity(
                        opacity: isEnabled ? 1 : 0.5,
                        child: InkWell(
                          onTap: isEnabled
                              ? () => _manageKey(child.value, decimalSeparator)
                              : null,
                          child: Center(child: child),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      );
}