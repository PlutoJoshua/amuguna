import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors_ext.dart';

/// 앱 전체 테마.
///
/// `AppTheme.light` / `AppTheme.dark` 두 ThemeData를 제공하며,
/// 각각 `extensions: [AppColorsExt.light()/dark()]` 으로 색상 토큰을 주입한다.
/// 위젯에서 색상은 `context.colors.X` (theme_context_ext.dart) 로 읽는다.
class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        colors: AppColorsExt.dark(),
      );

  static ThemeData get light => _build(
        brightness: Brightness.light,
        colors: AppColorsExt.light(),
      );

  static ThemeData _build({
    required Brightness brightness,
    required AppColorsExt colors,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: colors.primary,
            surface: colors.surface,
            onPrimary: Colors.black, // 노란색 위 검정 — 양쪽 동일
            onSurface: colors.textPrimary,
          )
        : ColorScheme.light(
            primary: colors.primary,
            surface: colors.surface,
            onPrimary: Colors.black, // 노란색 위 검정 — 양쪽 동일
            onSurface: colors.textPrimary,
          );

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: colorScheme,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
        // status bar 아이콘 색상도 brightness에 맞춰 분기
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: colors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}
