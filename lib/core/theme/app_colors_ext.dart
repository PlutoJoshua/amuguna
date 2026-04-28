import 'package:flutter/material.dart';
import 'app_palette.dart';

/// 앱 전반에서 사용할 색상 토큰을 ThemeData.extensions로 주입하는 컨테이너.
///
/// 위젯에서는 `context.colors.primary` 형태로 접근 (theme_context_ext.dart 참고).
@immutable
class AppColorsExt extends ThemeExtension<AppColorsExt> {
  // Brand
  final Color primary;
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color textPrimary;
  final Color textSecondary;

  // Decision Types (4종)
  final Color intuit;
  final Color analyst;
  final Color vibe;
  final Color zen;

  // Emotions (4종)
  final Color emotionTired;
  final Color emotionExcited;
  final Color emotionStressed;
  final Color emotionHesitant;

  // UI 강조
  final Color recordingRed;
  final Color userBubble;
  final Color aiBubble;

  const AppColorsExt({
    required this.primary,
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.intuit,
    required this.analyst,
    required this.vibe,
    required this.zen,
    required this.emotionTired,
    required this.emotionExcited,
    required this.emotionStressed,
    required this.emotionHesitant,
    required this.recordingRed,
    required this.userBubble,
    required this.aiBubble,
  });

  /// 다크 팔레트 인스턴스
  factory AppColorsExt.dark() => AppColorsExt(
        primary: AppPalette.primary,
        background: AppPalette.darkBackground,
        surface: AppPalette.darkSurface,
        surfaceLight: AppPalette.darkSurfaceLight,
        textPrimary: AppPalette.darkTextPrimary,
        textSecondary: AppPalette.darkTextSecondary,
        intuit: AppPalette.intuit,
        analyst: AppPalette.analyst,
        vibe: AppPalette.vibe,
        zen: AppPalette.zen,
        emotionTired: AppPalette.emotionTired,
        emotionExcited: AppPalette.emotionExcited,
        emotionStressed: AppPalette.emotionStressed,
        emotionHesitant: AppPalette.emotionHesitant,
        recordingRed: AppPalette.recordingRed,
        userBubble: AppPalette.darkUserBubble,
        aiBubble: AppPalette.darkAiBubble,
      );

  /// 라이트 팔레트 인스턴스
  factory AppColorsExt.light() => AppColorsExt(
        primary: AppPalette.primary,
        background: AppPalette.lightBackground,
        surface: AppPalette.lightSurface,
        surfaceLight: AppPalette.lightSurfaceLight,
        textPrimary: AppPalette.lightTextPrimary,
        textSecondary: AppPalette.lightTextSecondary,
        intuit: AppPalette.intuit,
        analyst: AppPalette.analyst,
        vibe: AppPalette.vibe,
        zen: AppPalette.zen,
        emotionTired: AppPalette.emotionTired,
        emotionExcited: AppPalette.emotionExcited,
        emotionStressed: AppPalette.emotionStressed,
        emotionHesitant: AppPalette.emotionHesitant,
        recordingRed: AppPalette.recordingRed,
        userBubble: AppPalette.lightUserBubble,
        aiBubble: AppPalette.lightAiBubble,
      );

  /// 결정 카드 그라데이션 위 텍스트색을 luminance로 자동 분기.
  /// vibe(amber) 같은 밝은 카드에선 검정, 나머지는 흰색 반환.
  Color onDecision(Color cardColor) =>
      cardColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  @override
  AppColorsExt copyWith({
    Color? primary,
    Color? background,
    Color? surface,
    Color? surfaceLight,
    Color? textPrimary,
    Color? textSecondary,
    Color? intuit,
    Color? analyst,
    Color? vibe,
    Color? zen,
    Color? emotionTired,
    Color? emotionExcited,
    Color? emotionStressed,
    Color? emotionHesitant,
    Color? recordingRed,
    Color? userBubble,
    Color? aiBubble,
  }) {
    return AppColorsExt(
      primary: primary ?? this.primary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceLight: surfaceLight ?? this.surfaceLight,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      intuit: intuit ?? this.intuit,
      analyst: analyst ?? this.analyst,
      vibe: vibe ?? this.vibe,
      zen: zen ?? this.zen,
      emotionTired: emotionTired ?? this.emotionTired,
      emotionExcited: emotionExcited ?? this.emotionExcited,
      emotionStressed: emotionStressed ?? this.emotionStressed,
      emotionHesitant: emotionHesitant ?? this.emotionHesitant,
      recordingRed: recordingRed ?? this.recordingRed,
      userBubble: userBubble ?? this.userBubble,
      aiBubble: aiBubble ?? this.aiBubble,
    );
  }

  @override
  AppColorsExt lerp(ThemeExtension<AppColorsExt>? other, double t) {
    if (other is! AppColorsExt) return this;
    return AppColorsExt(
      primary: Color.lerp(primary, other.primary, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      intuit: Color.lerp(intuit, other.intuit, t)!,
      analyst: Color.lerp(analyst, other.analyst, t)!,
      vibe: Color.lerp(vibe, other.vibe, t)!,
      zen: Color.lerp(zen, other.zen, t)!,
      emotionTired: Color.lerp(emotionTired, other.emotionTired, t)!,
      emotionExcited: Color.lerp(emotionExcited, other.emotionExcited, t)!,
      emotionStressed: Color.lerp(emotionStressed, other.emotionStressed, t)!,
      emotionHesitant: Color.lerp(emotionHesitant, other.emotionHesitant, t)!,
      recordingRed: Color.lerp(recordingRed, other.recordingRed, t)!,
      userBubble: Color.lerp(userBubble, other.userBubble, t)!,
      aiBubble: Color.lerp(aiBubble, other.aiBubble, t)!,
    );
  }
}
