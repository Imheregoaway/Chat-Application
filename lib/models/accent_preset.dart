import 'package:flutter/material.dart';

enum AccentPreset {
  violet('Violet', Color(0xFF6C63FF), Color(0xFF8B84FF), Color(0xFF00D9A5)),
  teal('Teal', Color(0xFF00B894), Color(0xFF55EFC4), Color(0xFF0984E3)),
  rose('Rose', Color(0xFFE84393), Color(0xFFFD79A8), Color(0xFF6C5CE7)),
  amber('Amber', Color(0xFFF39C12), Color(0xFFFDCB6E), Color(0xFFE17055)),
  sky('Sky', Color(0xFF3498DB), Color(0xFF74B9FF), Color(0xFF00CEC9));

  const AccentPreset(this.label, this.primary, this.primaryLight, this.secondary);

  final String label;
  final Color primary;
  final Color primaryLight;
  final Color secondary;
}
