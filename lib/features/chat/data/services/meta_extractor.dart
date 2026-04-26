import '../models/chat_message.dart';

/// 모델이 메타 태그를 빠뜨렸을 때 텍스트만 보고 핵심 메타를 추정하는 룰베이스.
/// 100% 정확하진 않지만 모델 누락 시 안전망 역할을 한다.
class MetaExtractor {
  MetaExtractor._();

  /// AI 응답 본문에서 사용자 감정을 추정.
  /// AI가 본문에 "지쳐 보이네" 같은 미러링을 자연스레 녹였을 때 잡아낸다.
  static EmotionData? extractEmotionFromBody(String aiBody) {
    if (aiBody.isEmpty) return null;

    int tired = 0, excited = 0, stressed = 0, hesitant = 0;
    final t = aiBody;

    // 피곤/지침 신호
    const tiredKeywords = [
      '지쳐', '피곤', '힘들', '하루 끝', '에너지', '쉬',
      '축 처', '늘어', '나른', '무기력', '기운 없',
    ];
    for (final k in tiredKeywords) {
      if (t.contains(k)) tired += 25;
    }

    // 들뜸/긍정 신호
    const excitedKeywords = [
      '들떠', '신나', '도전', '특별', '재밌', '신기',
      '밝아', '활기', '들뜬', '호기심',
    ];
    for (final k in excitedKeywords) {
      if (t.contains(k)) excited += 25;
    }

    // 스트레스/짜증 신호
    const stressedKeywords = [
      '짜증', '스트레스', '바쁘', '화', '답답', '빨리',
      '시간 없', '급하', '예민',
    ];
    for (final k in stressedKeywords) {
      if (t.contains(k)) stressed += 25;
    }

    // 망설임 신호
    const hesitantKeywords = [
      '고민', '결정', '망설', '뭐 먹', '아무거나',
      '글쎄', '음...', '잘 모르', '어떨까',
    ];
    for (final k in hesitantKeywords) {
      if (t.contains(k)) hesitant += 20;
    }

    tired = tired.clamp(0, 100);
    excited = excited.clamp(0, 100);
    stressed = stressed.clamp(0, 100);
    hesitant = hesitant.clamp(0, 100);

    // 모든 값이 0이면 의미 있는 신호 없음 → null 반환 (게이지 표시 X)
    if (tired == 0 && excited == 0 && stressed == 0 && hesitant == 0) {
      return null;
    }

    return EmotionData(
      tired: tired,
      excited: excited,
      stressed: stressed,
      hesitant: hesitant,
    );
  }

  /// 사용자 발화(transcript 또는 텍스트)에서 의도를 추정.
  /// 단순한 키워드 매핑으로 데모/디버그 표시용.
  static String? extractIntent(String userText) {
    final t = userText.trim();
    if (t.isEmpty) return null;

    if (t.contains('아무거나')) return '결정 미루기';
    if (t.contains('매운') || t.contains('맵게')) return '매운 메뉴 원함';
    if (t.contains('가볍') || t.contains('샐러드')) return '가벼운 끼니 원함';
    if (t.contains('든든') || t.contains('배 채우')) return '든든한 끼니 원함';
    if (t.contains('빨리') || t.contains('급')) return '빠른 식사 필요';
    if (t.contains('혼자') || t.contains('혼밥')) return '혼밥';
    if (t.contains('회식') || t.contains('같이')) return '함께 먹기';
    if (t.contains('비싸') || t.contains('가성비') || t.contains('싸')) {
      return '가성비 우선';
    }
    if (RegExp(r'(좋아|좋다|콜|오케이|그걸로|할게|가자)').hasMatch(t)) {
      return '메뉴 확정';
    }
    return null;
  }

  /// 사용자 발화 + 최근 AI 응답에서 결정 확정 여부 + 메뉴명 추출.
  /// 사용자가 "그거 좋아" 등 확정 의사를 보이고, AI가 직전에 추천한 메뉴를 매칭.
  static String? extractDecision({
    required String userText,
    required String latestAiBody,
  }) {
    if (userText.isEmpty) return null;
    final user = userText.trim();

    // 확정 신호가 user 발화에 있는지
    final confirm = RegExp(
      r'(좋아|좋다|좋네|콜|오케이|그걸로|할게|가자|먹자|찬성|그래)',
    );
    if (!confirm.hasMatch(user)) return null;

    // 한국 음식 사전 — 자주 등장하는 것들. 확장 가능.
    const menuDict = [
      '국밥', '칼국수', '비빔밥', '제육볶음', '김치찌개', '된장찌개', '순두부찌개',
      '삼겹살', '목살', '갈비', '불고기', '닭갈비', '치킨', '피자',
      '떡볶이', '김밥', '라면', '냉면', '쫄면', '잔치국수',
      '돈까스', '카레', '오므라이스', '볶음밥',
      '파스타', '스테이크', '샐러드', '샌드위치', '햄버거',
      '초밥', '회', '우동', '돈부리', '라멘',
      '짜장면', '짬뽕', '마라탕', '탕수육', '깐풍기',
      '아이스크림', '와플', '케이크', '도넛',
    ];

    // 사용자 발화에 메뉴명이 직접 있으면 그것
    for (final m in menuDict) {
      if (user.contains(m)) return m;
    }

    // 없으면 AI 직전 응답에서 마지막으로 언급된 메뉴
    String? lastMentioned;
    for (final m in menuDict) {
      if (latestAiBody.contains(m)) lastMentioned = m;
    }
    return lastMentioned;
  }
}
