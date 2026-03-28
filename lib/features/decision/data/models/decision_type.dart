import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

enum DecisionType { intuit, analyst, vibe, zen }

extension DecisionTypeExtension on DecisionType {
  String get name {
    switch (this) {
      case DecisionType.intuit:
        return '직감형 결정러';
      case DecisionType.analyst:
        return '분석형 결정러';
      case DecisionType.vibe:
        return '분위기형 결정러';
      case DecisionType.zen:
        return '초월형 결정러';
    }
  }

  String get code {
    switch (this) {
      case DecisionType.intuit:
        return 'INTUIT';
      case DecisionType.analyst:
        return 'ANALYST';
      case DecisionType.vibe:
        return 'VIBE';
      case DecisionType.zen:
        return 'ZEN';
    }
  }

  String get description {
    switch (this) {
      case DecisionType.intuit:
        return '이미 정해놓고 물어보는 타입';
      case DecisionType.analyst:
        return '별점 4.3 이상만 갑니다';
      case DecisionType.vibe:
        return '다들 뭐 먹고 싶어?';
      case DecisionType.zen:
        return '진짜 아무거나';
    }
  }

  Color get color {
    switch (this) {
      case DecisionType.intuit:
        return AppColors.intuit;
      case DecisionType.analyst:
        return AppColors.analyst;
      case DecisionType.vibe:
        return AppColors.vibe;
      case DecisionType.zen:
        return AppColors.zen;
    }
  }

  List<({String label, int value})> get stats {
    switch (this) {
      case DecisionType.intuit:
        return [
          (label: '직감', value: 92),
          (label: '속도', value: 88),
          (label: '후회', value: 15),
        ];
      case DecisionType.analyst:
        return [
          (label: '분석', value: 95),
          (label: '속도', value: 22),
          (label: '만족도', value: 90),
        ];
      case DecisionType.vibe:
        return [
          (label: '눈치', value: 97),
          (label: '소신', value: 30),
          (label: '조율력', value: 85),
        ];
      case DecisionType.zen:
        return [
          (label: '무관심', value: 90),
          (label: '적응력', value: 99),
          (label: '불만', value: 5),
        ];
    }
  }

  String get compatibility {
    switch (this) {
      case DecisionType.intuit:
        return '회피형과 찰떡 / 분석형과 충돌';
      case DecisionType.analyst:
        return '직감형이 대신 정해줌 / 분석형끼리는 무한루프';
      case DecisionType.vibe:
        return '직감형이 결정해주면 감사 / 분석형과는 서로 양보';
      case DecisionType.zen:
        return '누구와도 평화 / 분위기형이 유일하게 답답해함';
    }
  }
}
