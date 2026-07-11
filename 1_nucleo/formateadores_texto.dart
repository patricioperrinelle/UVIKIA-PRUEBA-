// lib/1_nucleo/formateadores_texto.dart

import 'package:flutter/services.dart';

// =================================================================
// FORMATEADORES DE TEXTO (Moneda, Tarjetas de Crédito y Fechas)
// =================================================================

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String numericOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericOnly.length > 8) numericOnly = numericOnly.substring(0, 8);
    if (numericOnly.isEmpty) return newValue.copyWith(text: '');
    
    final buffer = StringBuffer();
    buffer.write('\$ ');
    for (int i = 0; i < numericOnly.length; i++) {
      if (i > 0 && (numericOnly.length - i) % 3 == 0) buffer.write('.');
      buffer.write(numericOnly[i]);
    }
    
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'\s+\b|\b\s'), '');
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) buffer.write(' ');
    }
    return TextEditingValue(
      text: buffer.toString(), 
      selection: TextSelection.collapsed(offset: buffer.toString().length)
    );
  }
}

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 4) text = text.substring(0, 4);
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) buffer.write('/');
    }
    return TextEditingValue(
      text: buffer.toString(), 
      selection: TextSelection.collapsed(offset: buffer.toString().length)
    );
  }
}