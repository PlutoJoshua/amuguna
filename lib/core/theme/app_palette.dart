import 'package:flutter/material.dart';

/// 다크/라이트 두 셋트의 색상 토큰. AppColorsExt 팩토리에서 참조.
///
/// 색상 자체에 대한 변경은 여기서만 하면 자동으로 양쪽 테마에 반영된다.
/// 직접 `palette.dark()` 또는 `palette.light()`를 부르지 말고,
/// 위젯에서는 `context.colors.X` 형태로 사용한다.
class AppPalette {
  AppPalette._();

  // ─── Dark ────────────────────────────────────────────────
  static const _darkBackground = Color(0xFF1A1A2E);
  static const _darkSurface = Color(0xFF16213E);
  static const _darkSurfaceLight = Color(0xFF0F3460);
  static const _darkTextPrimary = Color(0xFFFFFFFF);
  static const _darkTextSecondary = Color(0xFFB0B0B0);
  static const _darkUserBubble = Color(0xFF533483);
  static const _darkAiBubble = Color(0xFF1E3A5F);

  // ─── Light ───────────────────────────────────────────────
  static const _lightBackground = Color(0xFFF8F8FA);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSurfaceLight = Color(0xFFF0F0F5);
  static const _lightTextPrimary = Color(0xFF1A1A1A);
  static const _lightTextSecondary = Color(0xFF777777);
  static const _lightUserBubble = Color(0xFF7F5FA0);
  static const _lightAiBubble = Color(0xFFE8EDF5);

  // ─── 양 모드 공통 ────────────────────────────────────────
  // primary 노란색은 양쪽에서 동일. 노랑 위에 검정 텍스트가 라이트/다크 모두 자연스럽다.
  static const _primary = Color(0xFFFFD43B);

  // 시스템 표준 빨강. 양 모드에서 의미 동일.
  static const _recordingRed = Color(0xFFFF3B30);

  // Decision 카드 4종. 라이트에선 luminance 기반 onDecision 헬퍼가 텍스트 색을 자동 분기하므로
  // 색상 자체는 양쪽 동일하게 유지.
  static const _intuit = Color(0xFFD85A30); // Coral
  static const _analyst = Color(0xFF1D9E75); // Teal
  static const _vibe = Color(0xFFBA7517); // Amber
  static const _zen = Color(0xFF7F77DD); // Purple

  // Emotion 게이지. 양 모드에서 동일.
  static const _emotionTired = Color(0xFF6B7B8D);
  static const _emotionExcited = Color(0xFFFF9F43);
  static const _emotionStressed = Color(0xFFEE5A6F);
  static const _emotionHesitant = Color(0xFF7C83FD);

  // ─── 외부 노출 (AppColorsExt 팩토리 전용) ─────────────────
  // Dark
  static Color get darkBackground => _darkBackground;
  static Color get darkSurface => _darkSurface;
  static Color get darkSurfaceLight => _darkSurfaceLight;
  static Color get darkTextPrimary => _darkTextPrimary;
  static Color get darkTextSecondary => _darkTextSecondary;
  static Color get darkUserBubble => _darkUserBubble;
  static Color get darkAiBubble => _darkAiBubble;

  // Light
  static Color get lightBackground => _lightBackground;
  static Color get lightSurface => _lightSurface;
  static Color get lightSurfaceLight => _lightSurfaceLight;
  static Color get lightTextPrimary => _lightTextPrimary;
  static Color get lightTextSecondary => _lightTextSecondary;
  static Color get lightUserBubble => _lightUserBubble;
  static Color get lightAiBubble => _lightAiBubble;

  // Shared
  static Color get primary => _primary;
  static Color get recordingRed => _recordingRed;
  static Color get intuit => _intuit;
  static Color get analyst => _analyst;
  static Color get vibe => _vibe;
  static Color get zen => _zen;
  static Color get emotionTired => _emotionTired;
  static Color get emotionExcited => _emotionExcited;
  static Color get emotionStressed => _emotionStressed;
  static Color get emotionHesitant => _emotionHesitant;
}
