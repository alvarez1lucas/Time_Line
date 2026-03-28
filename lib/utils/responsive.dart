// Utility helpers for responsive layout and font sizing.

import 'package:flutter/material.dart';

/// Returns width percentage of screen.
double wp(BuildContext context, double percent) {
  return MediaQuery.of(context).size.width * percent / 100.0;
}

/// Returns height percentage of screen.
double hp(BuildContext context, double percent) {
  return MediaQuery.of(context).size.height * percent / 100.0;
}

/// Recommended font size as percentage of width.
double rf(BuildContext context, double percent) {
  return wp(context, percent);
}
