import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/conditions.dart';

class AppTheme {
  static const Color surfaceColor = Color(0xFF141416);
  static const Color panelColor = Color(0xFF1C1C1F);
  static const Color primaryAccent = Color(0xFF4AC29A);

  static const Color happyColor = Color(0xFF4AC29A);
  static const Color sadColor = Color(0xFF5D9CEB);
  static const Color angryColor = Color(0xFFE85D75);
  static const Color tiredColor = Color(0xFFF6A623);
  static const Color neutralColor = Color(0xFFA1A9B3);

  static Color colorForEmotion(EmotionState state) {
    switch (state) {
      case EmotionState.happy:
        return happyColor;
      case EmotionState.sad:
        return sadColor;
      case EmotionState.stressed:
        return angryColor;
      case EmotionState.tired:
        return tiredColor;
      case EmotionState.neutral:
        return neutralColor;
    }
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surfaceColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        surface: panelColor,
        error: angryColor,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        ThemeData.dark().textTheme,
      ),
      cardTheme: CardThemeData(
        color: panelColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white10),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryAccent,
        inactiveTrackColor: Colors.white10,
        thumbColor: Colors.white,
        overlayColor: primaryAccent.withAlpha(50),
        trackHeight: 6,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return primaryAccent.withAlpha(40);
              }
              return panelColor;
            },
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return primaryAccent;
              }
              return Colors.white70;
            },
          ),
          side: WidgetStateProperty.all(const BorderSide(color: Colors.white10)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: panelColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
