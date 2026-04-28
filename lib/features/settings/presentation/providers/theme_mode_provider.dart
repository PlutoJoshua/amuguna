import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/presentation/providers/chat_provider.dart'
    show userPreferencesServiceProvider;

/// 현재 활성 ThemeMode. 앱 부팅 시 main()에서 saved 값으로 override되고,
/// 설정 화면에서 변경 시 setThemeMode()로 갱신된다.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Provider state 갱신 + 단말 영속화를 한 번에.
/// 설정 화면 토글 변경 시 호출.
Future<void> setThemeMode(WidgetRef ref, ThemeMode mode) async {
  ref.read(themeModeProvider.notifier).state = mode;
  await ref.read(userPreferencesServiceProvider).setThemeMode(mode);
}
