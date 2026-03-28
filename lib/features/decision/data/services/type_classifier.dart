import 'dart:math';

import '../../../chat/data/models/chat_message.dart';
import '../models/decision_type.dart';

class TypeClassifier {
  /// ChatState 데이터를 기반으로 결정 유형 판별
  static DecisionType classify({
    required int turnCount,
    required int elapsedSeconds,
    required List<EmotionData> emotionHistory,
  }) {
    final scores = {
      DecisionType.intuit: 0,
      DecisionType.analyst: 0,
      DecisionType.vibe: 0,
      DecisionType.zen: 0,
    };

    // 1. 결정 속도
    if (elapsedSeconds < 60) {
      scores[DecisionType.intuit] = scores[DecisionType.intuit]! + 3;
      scores[DecisionType.zen] = scores[DecisionType.zen]! + 1;
    } else if (elapsedSeconds > 120) {
      scores[DecisionType.analyst] = scores[DecisionType.analyst]! + 2;
    }

    // 2. 턴 수
    if (turnCount <= 3) {
      scores[DecisionType.intuit] = scores[DecisionType.intuit]! + 2;
      scores[DecisionType.zen] = scores[DecisionType.zen]! + 2;
    } else {
      scores[DecisionType.analyst] = scores[DecisionType.analyst]! + 3;
      scores[DecisionType.vibe] = scores[DecisionType.vibe]! + 1;
    }

    // 3. 감정 변동폭
    if (emotionHistory.length >= 2) {
      final variance = _emotionVariance(emotionHistory);
      if (variance > 20) {
        scores[DecisionType.vibe] = scores[DecisionType.vibe]! + 3;
      } else {
        scores[DecisionType.zen] = scores[DecisionType.zen]! + 3;
      }
    }

    // 4. 평균 hesitant
    if (emotionHistory.isNotEmpty) {
      final avgHesitant =
          emotionHistory.map((e) => e.hesitant).reduce((a, b) => a + b) /
              emotionHistory.length;
      if (avgHesitant > 50) {
        scores[DecisionType.analyst] = scores[DecisionType.analyst]! + 2;
      }
    }

    // 5. 평균 excited
    if (emotionHistory.isNotEmpty) {
      final avgExcited =
          emotionHistory.map((e) => e.excited).reduce((a, b) => a + b) /
              emotionHistory.length;
      if (avgExcited > 50) {
        scores[DecisionType.intuit] = scores[DecisionType.intuit]! + 1;
        scores[DecisionType.vibe] = scores[DecisionType.vibe]! + 1;
      }
    }

    // 6. 평균 관심도 낮음 (tired + stressed 둘 다 낮으면 zen)
    if (emotionHistory.isNotEmpty) {
      final avgTired =
          emotionHistory.map((e) => e.tired).reduce((a, b) => a + b) /
              emotionHistory.length;
      final avgStressed =
          emotionHistory.map((e) => e.stressed).reduce((a, b) => a + b) /
              emotionHistory.length;
      if (avgTired < 30 && avgStressed < 30) {
        scores[DecisionType.zen] = scores[DecisionType.zen]! + 2;
      }
    }

    // 최고 점수 유형 반환 (동점 시 enum 순서대로 = intuit 우선)
    var maxScore = -1;
    var result = DecisionType.intuit;
    for (final entry in scores.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        result = entry.key;
      }
    }

    return result;
  }

  /// 감정 히스토리의 전체 변동폭 (표준편차 기반)
  static double _emotionVariance(List<EmotionData> history) {
    final allValues = <int>[];
    for (final e in history) {
      allValues.addAll([e.tired, e.excited, e.stressed, e.hesitant]);
    }
    if (allValues.isEmpty) return 0;

    final mean = allValues.reduce((a, b) => a + b) / allValues.length;
    final variance =
        allValues.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
            allValues.length;
    return sqrt(variance);
  }
}
