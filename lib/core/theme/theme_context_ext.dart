import 'package:flutter/material.dart';
import 'app_colors_ext.dart';

/// 위젯에서 `context.colors.primary` 형태로 색상 토큰에 접근하는 확장.
///
/// 사용 전 `MaterialApp.theme/darkTheme` 의 `extensions:`에 `AppColorsExt`가
/// 들어있어야 한다. (app_theme.dart 참고)
extension AppThemeX on BuildContext {
  AppColorsExt get colors => Theme.of(this).extension<AppColorsExt>()!;

  /// 현재 테마가 다크 모드인지 (confetti·shadow 톤 분기 등에 사용)
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
