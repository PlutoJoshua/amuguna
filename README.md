# 🍜 아무거나 (amuguna)

> **"아무거나라고 했지만, 진짜 원하는 건 따로 있잖아"**
>
> Kanana-o 멀티모달 AI로 목소리에서 숨은 선호를 읽어주는 의사결정 도우미

[![Built with Kanana-o](https://img.shields.io/badge/Built%20with-Kanana--o-FFD43B?style=flat-square)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Kakao AI Ambassador](https://img.shields.io/badge/Kakao-AI%20Ambassador-FFD43B?style=flat-square)]()

> ℹ️ **비공식 프로젝트.** 카카오 AI 앰배서더 Kanana-o 베타 테스트 프로그램의 일환으로 개인이 제작한 프로젝트이며, 카카오 또는 Kanana 팀의 공식 프로덕트가 아닙니다.

---

## 📋 목차

- [프로젝트 개요](#프로젝트-개요)
- [스크린샷](#-스크린샷) ← 앱 미리보기
- [빠른 시작](#-빠른-시작)
- [현재 구현 상태](#현재-구현-상태) ← 최신 진행
- [왜 "아무거나"인가?](#왜-아무거나인가)
- [핵심 컨셉: 3대 한국 문화 훅포인트](#핵심-컨셉-3대-한국-문화-훅포인트)
- [Kanana-o 기술 매핑](#kanana-o-기술-매핑)
- [데모 시나리오: "아무거나 번역" 풀 플로우](#데모-시나리오-아무거나-번역-풀-플로우)
  - [시나리오 A: "뭐 먹지?" 모드 (메인)](#시나리오-a-뭐-먹지-모드-메인-데모)
  - [시나리오 B: "뭐 시키지?" 모드 (Vision)](#시나리오-b-뭐-시키지-모드-vision-쇼케이스)
- [결정 유형 카드 시스템](#결정-유형-카드-시스템)
- [사용자 성장 루프](#사용자-성장-루프)
- [기술 아키텍처](#기술-아키텍처)
- [Kanana-o API 연동 가이드](#kanana-o-api-연동-가이드)
- [MVP 범위 및 로드맵](#mvp-범위-및-로드맵)
- [참고 자료](#참고-자료)

---

## 프로젝트 개요

### 한줄 피치

**"네 목소리에서 네가 진짜 원하는 걸 읽어주는 AI"**

### 프로젝트 정보

| 항목 | 내용 |
|------|------|
| **프로덕트명** | 아무거나 (amuguna) |
| **컨셉** | 음성 감정 분석 기반 의사결정 도우미 |
| **핵심 기술** | Kakao Kanana-o 멀티모달 AI (음성 + 이미지) |
| **프로덕트 형태** | Flutter 앱 (iOS · Android · macOS) |
| **타겟 사용자** | MZ세대(일상 결정 피로), 직장인(업무+회식+소비), 커플/친구 그룹 |
| **배경** | 카카오 AI 앰배서더 Kanana-o 베타 테스터 선정 |

### 핵심 차별점

기존 "결정 앱"들(룰렛, 동전던지기)과의 결정적 차이:

- **룰렛/동전던지기**: 무작위 결과. 사용자 의지 무시
- **일반 AI 추천**: 텍스트 기반 추천. 맥락 부족
- **아무거나**: 음성 톤에서 감정을 읽어 **"네가 진짜 원하는 것"**을 찾아줌. Kanana-o만 가능한 한국어 감정 인식 활용

---

## 📸 스크린샷

**홈 / 설정**

<table>
  <tr>
    <td align="center"><b>홈 (다크)</b></td>
    <td align="center"><b>홈 (라이트)</b></td>
    <td align="center"><b>설정 (BYO-key)</b></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/home-dark.png" width="220"/></td>
    <td><img src="docs/screenshots/home-light.png" width="220"/></td>
    <td><img src="docs/screenshots/settings-light.png" width="220"/></td>
  </tr>
</table>

**뭐 먹지? — 음성 대화 (Mode A)**

<table>
  <tr>
    <td align="center"><b>음성 녹음 중</b></td>
    <td align="center"><b>AI 감정 미러링 대화</b></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/chat-recording-light.png" width="220"/></td>
    <td><img src="docs/screenshots/chat-voice-light.png" width="220"/></td>
  </tr>
</table>

**뭐 시키지? — 메뉴판 분석 (Mode B)**

<table>
  <tr>
    <td align="center"><b>메뉴판 업로드</b></td>
    <td align="center"><b>Vision 분석 결과</b></td>
    <td align="center"><b>메뉴 기반 추천 대화</b></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/menu-result-light.png" width="220"/></td>
    <td><img src="docs/screenshots/menu-result-light2.png" width="220"/></td>
    <td><img src="docs/screenshots/chat-mirror-light.png" width="220"/></td>
  </tr>
</table>

**결정 완료 / 결정 유형 카드**

<table>
  <tr>
    <td align="center"><b>결정 완료 🎉</b></td>
    <td align="center"><b>직감형 (INTUIT)</b></td>
    <td align="center"><b>초월형 (ZEN)</b></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/decision-card-light.png" width="220"/></td>
    <td><img src="docs/screenshots/decision-card-light2.png" width="220"/></td>
    <td><img src="docs/screenshots/decision-card-light3.png" width="220"/></td>
  </tr>
</table>

---

## 🚀 빠른 시작

> **BYO-key 프로젝트입니다.** 본 레포는 공용 데모를 운영하지 않으며, 사용자가 자신의 Kanana-o API 키를 발급받아 직접 입력해야 동작합니다. 호출 비용은 본인 계정으로 청구됩니다.

### 요구사항

- Flutter 3.29+ / Dart 3.8+
- 지원 플랫폼: **iOS / Android / macOS** (웹은 미지원 — 아래 [웹 빌드 안내](#웹-빌드-안내) 참고)
- 본인의 Kanana-o API 키 — 카카오 Kanana 앰배서더/베타 프로그램에서 발급. [공식 문서](https://huggingface.co/kakaocorp/Kanana-1.5-o-9.8B-instruct-2602-API_Doc)

### 권장 — 앱 내에서 키 입력 (가장 안전)

빌드에 키를 박지 않고 앱 첫 실행 시 설정 화면에서 직접 입력하는 방식. 키는 `shared_preferences`로 **단말에만 저장**되며 외부로 전송되지 않습니다.

```bash
flutter pub get

# 키 없이 그냥 실행
flutter run -d macos          # macOS 데스크탑 (개발 추천)
flutter run                   # iOS / Android 실기기 또는 시뮬레이터
```

앱이 열리면 자동으로 설정 화면이 뜨며, 키를 입력 후 메인 화면으로 이동합니다.

### 옵션 — dart-define으로 빌드에 주입 (개발용)

매번 입력이 번거로우면 빌드 시 환경변수로 주입할 수 있습니다. **공유 빌드(앱스토어 / TestFlight 등)에는 절대 사용하지 마세요** — 빌드 산출물에 키가 박힙니다.

```bash
flutter run --dart-define=KANANA_API_KEY=your_api_key_here

# 릴리즈 빌드
flutter build ios     --dart-define=KANANA_API_KEY=your_api_key_here
flutter build apk     --dart-define=KANANA_API_KEY=your_api_key_here
flutter build macos   --dart-define=KANANA_API_KEY=your_api_key_here
```

### 웹 빌드 안내

Kanana-o API 엔드포인트는 CORS preflight(OPTIONS)에 응답하지 않아 브라우저에서 직접 호출이 차단됩니다. 웹 환경을 지원하려면 **본인이 별도의 CORS 프록시를 호스팅**해야 하며, 본 레포는 프록시 코드를 포함하지 않습니다 (구버전 git 히스토리에 Firebase Functions 기반 예시가 있음).

---

## 현재 구현 상태

> 카카오 Kanana-o 베타테스트 기간 동안 실험·개선이 진행 중인 부분과, 이미 동작하는 부분을 분리해 정리.

### ✅ 동작하는 것

| 영역 | 상태 |
|------|------|
| Mode A "뭐 먹지?" — 음성 입력 + 자연어 응답 + 음성 응답 | ✅ |
| Mode B "뭐 시키지?" — 메뉴판 사진(여러 장) + Vision 분석 + 음성 추천 | ✅ |
| 멀티턴 대화 (이전 발화 기억 + 거부 메뉴 회피) | ✅ |
| 결정 유형 카드 4종 (INTUIT / ANALYST / VIBE / ZEN) + confetti 연출 | ✅ |
| 받아쓰기 폴백 — 메인 호출이 USER_HEARD 빠뜨려도 단일 목적 호출로 보강 | ✅ |
| 룰베이스 메타 추출기 — EMOTION/INTENT/DECISION을 본문 키워드로 보완 | ✅ |
| 디버그 로그 화면 — 세션별 폴더 + 턴별 입력/메타/raw 응답 ([/debug-log](lib/features/debug_log/presentation/screens/debug_log_screen.dart)) | ✅ |
| BYO-key 모드 — 사용자 키 입력 + 라우팅 가드(키 미설정 시 설정 화면 강제) | ✅ |
| macOS 데스크탑 빌드 — 마이크/네트워크 entitlements 설정 완료 | ✅ |
| Mode B UX — 분석 중 spinner / 결과 확인 단계 / 채팅 상단 메뉴판 칩 | ✅ |

### ⚠️ 알려진 제약

- **Kanana-o 음성 모달리티에서 시스템 프롬프트 후반부를 자주 무시** — `[USER_HEARD]` `[INTENT]` `[EMOTION]` 같은 메타 태그가 매 응답마다 일관되게 나오지 않음. 이걸 보완하려고 받아쓰기 폴백 + 룰베이스 추출을 도입.
- **Kanana-o API CORS 미지원** — 웹 빌드는 미지원. 셀프 호스팅 프록시 필요.
- **녹음 sample rate** — record 패키지가 macOS에서 16kHz 강제를 일부 무시할 수 있어 WAV 파일 길이가 실제보다 길게 표기될 수 있음. 인식 자체는 동작.
- **음성은 60초 이내 권장** — Kanana-o 서버가 60s 초과 음성 거부. 클라이언트에서 50초 하드 리밋.

### ❌ 미구현 (Phase 2 이후)

- 눈치 모드(그룹 의사결정) — README의 컨셉 섹션 참고
- 결정 유형 카드 SNS 공유 OG 이미지

---

## 왜 "아무거나"인가?

### 한국 문화 맥락

"아무거나"는 단순한 단어가 아니라 **한국 문화의 상징적 코드**다.

한국인이라면 100% 공감하는 상황: "뭐 먹을래?" "아무거나~" — 이 말을 액면 그대로 받아들이는 한국인은 없다. 모두가 안다, **"아무거나"는 "아무거나"가 아니라는 것을**.

이 문화 현상이 프로덕트 이름이자 훅포인트가 되는 이유:

1. **즉각적 공감**: 설명이 필요 없다. 이름만 들어도 뭘 하는 앱인지 안다
2. **밈 잠재력**: "아무거나"는 이미 한국에서 밈처럼 소비되는 표현이다
3. **Kanana-o 쇼케이스**: "아무거나"의 뉘앙스를 AI가 읽는다는 컨셉 자체가 한국어 특화 AI의 가치를 증명한다

### 왜 Kanana-o여야 하는가?

GPT-4o나 Gemini로는 이 프로덕트를 동일하게 만들 수 없다. 그 이유:

| 능력 | Kanana-o | GPT-4o | Gemini |
|------|----------|--------|--------|
| 한국어 음성 인식 (CER) | **6.45** | 23.19 | 17.11 |
| 한국어 TTS (CER) | **2.23** | 3.44 | 4.78 |
| 한국어 감정 인식 | **압도적 우위** | 보통 | 보통 |
| 한국 방언 인식 | 지원 (제주, 경상) | 미지원 | 미지원 |
| 한국 문화 맥락 이해 | 최적화 | 일반적 | 일반적 |
| 옴니모달 통합 처리 | 네이티브 | 네이티브 | 부분 지원 |

> **핵심**: Kanana-o는 한국어 음성에서 억양, 말투, 목소리 떨림 등 비언어적 신호를 분석하고, 대화 맥락에 맞는 감정적이고 자연스러운 음성 응답을 생성한다. DPO(Direct Preference Optimization) 방식으로 감정 표현을 학습했기 때문에, 단순 TTS가 아닌 상황에 맞는 톤과 뉘앙스로 응답할 수 있다.

---

## 핵심 컨셉: 3대 한국 문화 훅포인트

### 훅 1: "아무거나" 번역 — 진입점 (Acquisition)

> **"아무거나라고 했지만... 목소리가 좀 지쳐있네요. 따뜻하고 든든한 거 땡기시죠?"**

**시나리오**: 사용자가 "아무거나~"라고 말할 때, 그 톤의 미세한 차이를 읽는다.

- 피곤한 톤 → 편안하고 든든한 음식 추천
- 들뜬 톤 → 새로운 도전 추천
- 짜증 섞인 톤 → 빠른 결정 유도
- 망설이는 톤 → 선택지를 좁혀주는 질문

#### 두 가지 모드

실제 "아무거나" 상황은 두 단계에서 발생한다. 각 단계에 맞는 모드를 제공한다.

**🍽️ 모드 A: "뭐 먹지?" (메뉴 선정 모드) — 메인**

> 식당 가기 전, 배달 시키기 전, "점심 뭐 먹지?" 하는 순간.
> 사용 빈도가 가장 높고, 진입 장벽이 없다.

사진 없이 음성 대화만으로 시작한다. AI가 상황 맥락을 대화형으로 파악하며 음식 장르부터 좁혀나간다.

```
AI가 파악하는 상황 맥락:
  - 감정/컨디션: 음성 톤에서 자동 추론 (피곤, 스트레스, 기대감 등)
  - 식사 상황: 혼밥 / 친구 / 가족 / 회식 / 데이트
  - 선호 방향: 매운 거 / 든든한 거 / 가벼운 거 / 새로운 거
  - 제약 조건: 예산, 알레르기, 최근에 먹은 것
  - 외부 맥락: 날씨, 시간대 (점심/저녁), 현재 위치
```

대화 예시:
```
사용자: 🎙️ "아 점심 뭐 먹지... 아무거나"
AI: "목소리가 좀 축 처져있네요. 오늘 힘든 하루?
     혼자 먹어요, 아니면 같이 먹는 사람 있어요?"
사용자: 🎙️ "혼자 먹어~ 빨리 먹고 와야 해"
AI: "그러면 빠르고 든든한 거로 갈게요.
     국밥류 어때요? 뚝딱 먹고 올 수 있잖아요.
     아니면 비 오니까 칼국수 땡기지 않아요?"
사용자: 🎙️ "오 칼국수 좋다"
AI: "역시! 칼국수 말할 때 목소리가 확 밝아졌어요 ㅋㅋ
     근처 칼국수 맛집 찾아볼까요?"
```

**📋 모드 B: "뭐 시키지?" (메뉴판 분석 모드) — 보조**

> 이미 식당에 앉았는데 메뉴가 너무 많을 때.
> Kanana-o Vision 쇼케이스 + 매일 쓰는 기능은 아니지만 임팩트 있는 데모.

메뉴판 사진을 촬영/업로드하면 AI가 메뉴 항목을 인식하고, 음성 대화를 통해 그 메뉴판 안에서 최적의 선택을 찾아준다.

```
사용자: [메뉴판 사진 업로드]
AI: "메뉴판 분석 완료! 18개 메뉴를 찾았어요.
     한식 7개, 분식 5개, 면류 4개, 사이드 2개.
     뭐가 땡기세요?"
사용자: 🎙️ "음... 아무거나~"
AI: "아까 혼자 빨리 먹어야 한다고 했잖아요.
     이 중에서 빨리 나오는 건 비빔밥이나 제육볶음인데,
     목소리 톤으로 보면 좀 든든한 게 나을 것 같아요.
     제육볶음 정식 어때요?"
```

#### 왜 이 구조인가?

| | 모드 A: 뭐 먹지? | 모드 B: 뭐 시키지? |
|---|---|---|
| **사용 시점** | 식사 전 (가장 빈번) | 식당 도착 후 |
| **진입 장벽** | 없음 (음성만) | 사진 촬영 필요 |
| **사용 빈도** | 매일 1-3회 | 주 1-2회 |
| **Kanana-o 활용** | Audio + LLM | Audio + Vision + LLM |
| **데모 임팩트** | 감정 분석 쇼케이스 | 멀티모달 통합 쇼케이스 |
| **프로덕트 역할** | 핵심 기능 (리텐션) | 킬러 데모 (WOW 팩터) |

> **MVP 전략**: 모드 A를 메인 진입점으로, 모드 B는 "메뉴판도 찍어볼래요?" 버튼으로 자연스럽게 연결. 데모에서는 모드 A → 모드 B 순서로 보여주되, 모드 A에서 이미 "오" 하게 만들고, 모드 B에서 "이것도 돼?" 하는 추가 임팩트를 주는 구조.

### 훅 2: "눈치" 모드 — 그룹 확장 (Activation)

> **"민수 씨는 고기 얘기할 때 목소리가 확 밝아졌고, 수현 씨는 가격 신경 쓰시는 것 같아요. 인당 2만원대 고깃집이 최적점이에요."**

**시나리오**: 그룹 의사결정에서 "눈치"를 AI가 대신 봐준다.

- 회식 장소 정할 때 → 각자 음성 입력 → 숨은 선호 교집합
- 친구 여행지 정할 때 → 각자 의견 + 톤 분석 → 모두가 만족하는 최적점
- 커플 데이트 코스 → 둘 다의 톤을 읽어 진짜 원하는 방향 파악

**한국적 맥락 반영**:
- 위계 인식: "부장님이 먼저 말씀하셨으니 부장님 선호를 좀 더 반영할게요"
- 눈치 문화: "다들 괜찮다고 했지만, 지연 씨 목소리에서 살짝 아쉬움이 느껴져요"
- 갈등 회피: 개인 의견을 직접 말하기 어려운 상황에서 AI가 중재

### 훅 3: 결정 유형 카드 — 바이럴 엔진 (Referral)

> **"당신은 [직감형 결정러] 입니다. 이미 정해놓고 물어보는 타입."**

**시나리오**: 결정 5회 이상 시 AI가 음성 패턴을 분석해 "결정 유형" 카드를 생성한다.

MBTI가 "너 MBTI 뭐야?"를 일상화시킨 것처럼, "너 결정 유형 뭐야?"를 만드는 것이 목표.

- 카카오톡 공유 최적화
- 인스타그램 스토리 사이즈 지원
- 유형 간 궁합 기능 → 커플/친구 사이 대화 소재

---

## 결정 유형 카드 시스템

### 4가지 결정 유형

#### 1. 직감형 결정러 (INTUIT)

```
코드: INTUIT
컬러: Coral (#D85A30)
한줄: "이미 정해놓고 물어보는 타입"
설명: 아무거나라고 하지만 0.3초 안에 답이 나와있음
특성:
  - 직감: 92%
  - 속도: 88%
  - 후회: 15%
궁합: 회피형과 찰떡 / 분석형과 충돌
```

#### 2. 분석형 결정러 (ANALYST)

```
코드: ANALYST
컬러: Teal (#1D9E75)
한줄: "별점 4.3 이상만 갑니다"
설명: 리뷰, 가격, 거리 다 따져야 직성이 풀림
특성:
  - 분석: 95%
  - 속도: 22%
  - 만족도: 90%
궁합: 직감형이 대신 정해줌 / 분석형끼리는 무한루프
```

#### 3. 분위기형 결정러 (VIBE)

```
코드: VIBE
컬러: Amber (#BA7517)
한줄: "다들 뭐 먹고 싶어?"
설명: 혼자면 빠른데 사람 모이면 눈치 9단
특성:
  - 눈치: 97%
  - 소신: 30%
  - 조율력: 85%
궁합: 직감형이 결정해주면 감사 / 분석형과는 서로 양보
```

#### 4. 초월형 결정러 (ZEN)

```
코드: ZEN
컬러: Purple (#7F77DD)
한줄: "진짜 아무거나"
설명: 결정에 에너지 안 쓰는 효율파. 뭐가 나와도 OK
특성:
  - 무관심: 90%
  - 적응력: 99%
  - 불만: 5%
궁합: 누구와도 평화 / 분위기형이 유일하게 답답해함
```

### 유형 판별 로직

```
입력 데이터:
  - 결정까지 소요 시간 (음성 입력 시점 ~ 최종 확정)
  - 감정 변화 패턴 (톤 변화 추이)
  - 추가 질문 횟수 (멀티턴 대화 수)
  - 타인 의견 참조 여부 (눈치 모드 사용 빈도)
  - 후회/변경 빈도 ("역시 다른 거로..." 패턴)

판별 기준:
  - 결정 속도 빠름 + 확신 톤 → 직감형
  - 결정 속도 느림 + 질문 많음 → 분석형
  - 그룹에서 의견 뒤로 미룸 + 동조 패턴 → 분위기형
  - 감정 변화 적음 + 결정 속도 빠름 + 무관심 톤 → 초월형
```

---

## Kanana-o 기술 매핑

### 모델 스펙

| 항목 | 상세 |
|------|------|
| **모델명** | Kanana-1.5-o-9.8B-instruct-2602 |
| **LLM 기반** | kanana-1.5-9.8B-instruct-2504 |
| **총 파라미터** | 11.6B |
| **입력** | Text / Image / Audio |
| **출력** | Text / Audio |
| **컨텍스트 길이** | 16K |
| **API 호환** | OpenAI SDK 호환 (base_url 변경만으로 사용 가능) |

### 핵심 기능 x 프로덕트 매핑

| Kanana-o 기능 | 프로덕트 활용 | 구현 방식 |
|---------------|-------------|-----------|
| **음성 감정 인식** | "아무거나" 톤 분석 (모드 A/B 공통) | 음성 입력 → 감정 라벨링 → 선호 추론 |
| **이미지 이해 (Vision)** | 메뉴판 인식 (모드 B 전용) | 사진 Base64 → 메뉴 항목 추출 → 추천 풀 생성 |
| **멀티턴 대화** | 대화형 결정 과정 (모드 A 핵심) | 세션 히스토리 유지 → 맥락 기반 재추론 |
| **자연스러운 TTS** | 감정 미러링 응답 | DPO 학습 기반 감정 표현 음성 합성 |
| **한국어 특화** | 문화 맥락 이해 + 상황 질문 | 한국 고유 표현/뉘앙스/식문화 처리 |
| **옴니모달 QA** | 사진+음성 동시 처리 (모드 B) | 메뉴판 보면서 음성 대화 |

### Kanana-o 모델 아키텍처 (프로덕트 관점)

```
사용자 음성 입력
    ↓
Audio Encoder (Whisper 기반) ← "사람의 귀" — 음성을 이해 가능한 정보로 변환
    ↓
Audio Projector ← LLM이 이해할 수 있는 형태로 가공
    ↓
LLM Backbone (Kanana-1.5-9.8B) ← "사람의 뇌" — 맥락 파악, 의도 해석, 감정 추론
    ↑
Vision Encoder + Projector ← "사람의 눈" — 메뉴판/상품 이미지 이해
    ↓
Voice Token LM ← "사람의 성대" — 말투, 톤, 감정 결정
    ↓
TTS (Voicebox + Univnet) ← "사람의 입" — 자연스러운 음성 생성
```

---

## 데모 시나리오: "아무거나 번역" 풀 플로우

### 시나리오 A: "뭐 먹지?" 모드 (메인 데모)

> 가장 먼저 보여주는 핵심 데모. 사진 없이 음성만으로 시작하며, Kanana-o의 감정 분석 능력을 정면으로 보여준다.

#### Step A-1: 음성으로 시작

```
[사용자 행동] 마이크 버튼 탭 → "아 점심 뭐 먹지... 아무거나" 발화
[앱 처리] record 패키지 → 16kHz mono WAV → Base64
[AI 처리]
  - STT: "아 점심 뭐 먹지 아무거나" 텍스트 변환
  - 감정 분석: 피곤함 72%, 기대감 45%, 망설임 감지
  - 톤 분석: "아무거나" 발화 시 살짝 상승 톤 → 실은 뭔가 원하는 게 있음
  - 맥락 추출: 점심 시간대, 혼자인 듯한 분위기
```

#### Step A-2: 감정 미러링 + 상황 질문

```
[AI 응답 - 텍스트 + 음성]
"아무거나라고 했지만... 목소리가 좀 지쳐있네요.
 혼자 먹어요? 같이 먹는 사람 있어요?"

[응답 톤] 부드럽고 공감하는 톤 (DPO 학습 기반)
[화면 표시] 감정 게이지 시각화
  - 피곤함 ████████░░ 72%
  - 기대감 ████░░░░░░ 45%
```

#### Step A-3: 맥락 대화 (멀티턴)

```
[사용자] 🎙️ "혼자~ 빨리 먹고 와야 해"
[AI 처리]
  - 맥락 업데이트: 혼밥 + 시간 제한 + 피곤함
  - 추천 방향: 빠르고 든든하고 위로가 되는 음식

[AI 응답]
"빨리 먹어야 하고, 좀 지친 상태면...
 국밥이나 칼국수 어때요?
 뚝딱 먹고 올 수 있고, 몸도 좀 따뜻해질 거예요.
 비도 오니까 칼국수 땡기지 않아요?"
```

#### Step A-4: 결정 순간 포착

```
[사용자] 🎙️ "오 칼국수 좋다!"
[AI 처리]
  - 톤 변화 감지: "칼국수" 언급 시 음성 밝아짐 → 확신 신호
  - 결정 확정: 칼국수

[AI 응답]
"역시! 칼국수 말할 때 목소리가 확 밝아졌어요 ㅋㅋ
 사실 처음부터 따뜻한 면 종류 땡겼던 거 아니에요?
 근처 칼국수 맛집 찾아볼까요?"

[화면 표시]
  - "오늘의 결정: 칼국수 🍜"
  - "결정까지 걸린 시간: 38초"
  - [선택] "근처 맛집 찾기" / "배달 앱 열기" / "결정 유형 보기"
```

#### Step A-5: 결정 유형 카드 생성

```
[화면 표시]
  - [결정 유형 카드] "당신은 [위로형 결정러] 입니다"
  - "피곤할 때 따뜻한 음식으로 향하는 타입"
  - "결정 속도: 빠른 편 (38초)"
  - [공유 버튼] 카카오톡 | 인스타그램 | 링크 복사
```

---

### 시나리오 B: "뭐 시키지?" 모드 (Vision 쇼케이스)

> 모드 A에서 "오" 하게 만든 후, "메뉴판도 찍어볼래요?" 버튼으로 연결. Kanana-o의 멀티모달 통합 능력을 보여주는 추가 임팩트.

#### Step B-1: 메뉴판 촬영

```
[사용자 행동] 메뉴판 사진 촬영 또는 업로드
[백엔드 처리] Base64 인코딩 → Kanana-o Vision API 호출
[AI 처리] 메뉴 항목 + 가격 + 카테고리 추출
[화면 표시] "메뉴판을 분석했어요! 총 12개 메뉴를 찾았습니다"
  - 한식 5개 | 면류 3개 | 볶음 2개 | 사이드 2개
```

#### Step B-2: 메뉴판 기반 음성 대화

```
[사용자] 🎙️ "뭐 시키지? 아무거나~"
[AI 처리]
  - 모드 A에서의 맥락 이어받기 (가능한 경우):
    "아까 칼국수 좋다고 했는데, 이 메뉴판에 칼국수는 없네요"
  - 또는 새로운 감정 분석 수행
  - 메뉴판 항목 중 톤 기반 매칭

[AI 응답]
"메뉴가 꽤 다양하네요!
 목소리 톤으로 보면 좀 든든한 게 나을 것 같아요.
 이 중에서 제육볶음 정식이 제일 잘 어울릴 것 같은데, 어때요?"
```

#### Step B-3: 멀티턴 재추론

```
[사용자] 🎙️ "음... 근데 어제도 볶음류 먹었는데"
[AI 처리]
  - 이전 맥락 참조: 든든한 음식 선호 유지
  - 새 조건 추가: 볶음류 제외
  - 메뉴판 재분석: 든든하면서 볶음 아닌 메뉴 필터링

[AI 응답]
"아 그럼 방향 바꿔서, 비빔밥 어때요?
 가격도 8,000원이라 부담 없고,
 야채도 들어가서 어제 고기 먹었으면 밸런스도 맞고요."
```

#### Step B-4: 결정 완료

```
[사용자] "오 그거 좋다!"
[AI 처리]
  - 결정 확정: 비빔밥
  - 결정 패턴 기록: 메뉴판 모드에서 2턴 만에 결정, 가격 민감도 낮음

[화면 표시]
  - "오늘의 결정: 비빔밥 🍚"
  - 메뉴판에서 비빔밥 위치 하이라이트
  - [결정 유형 카드 업데이트]
```

---

## 사용자 성장 루프

```
1. [혼자 써봄] → "뭐 먹지? 아무거나~" 해봄
     ↓
2. ["헐 신기해"] → AI가 내 톤에서 진짜 원하는 걸 맞춤 → 놀라움
     ↓
3. [친구한테 보여줌] → "야 이거 해봐" → 바이럴 시작
     ↓
4. [그룹으로 사용] → "우리 점심 뭐 먹지?" 눈치 모드 사용
     ↓
5. [결정 유형 카드] → "너 결정 유형 뭐야?" → SNS 공유
     ↓
6. [새 유저 유입] → 카드 본 사람이 직접 테스트 → 1번으로 돌아감
```

---

## 기술 아키텍처

### 전체 구조

```
┌─────────────────────────────────────────────┐
│            클라이언트 (Flutter App)             │
│  ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │ 음성 녹음  │ │ 카메라/   │ │ 채팅 UI      │  │
│  │ (record)  │ │ 이미지    │ │ (대화 표시)   │  │
│  └────┬─────┘ └────┬─────┘ └──────┬───────┘  │
│       └────────────┼──────────────┘           │
│  ┌──────────────────────────────────────┐    │
│  │ 오디오 전처리 (온디바이스)              │    │
│  │ - 16kHz mono WAV 녹음                 │    │
│  │ - Base64 인코딩                        │    │
│  └──────────────────────────────────────┘    │
│  ┌──────────────────────────────────────┐    │
│  │ 세션/히스토리 관리 (인메모리)            │    │
│  │ - 멀티턴 대화 히스토리                   │    │
│  │ - 결정 패턴 기록 + 유형 분석            │    │
│  └──────────────────────────────────────┘    │
│                    ↓                          │
│          HTTP/SSE 스트리밍 (직접 호출)          │
└────────────────────┼──────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│           Kanana-o API                       │
│  Endpoint: kanana-o.a2s-endpoint.            │
│            kr-central-2.kakaocloud.com/v1    │
│  Protocol: OpenAI SDK 호환                    │
│  Model: kanana-o                             │
└─────────────────────────────────────────────┘
```

### 기술 스택 (실제 구현)

| 영역 | 기술 | 선택 이유 |
|------|------|-----------|
| **앱 프레임워크** | Flutter 3.29+ / Dart 3.8+ | 단일 코드베이스로 iOS·Android·macOS·Web 동시 지원 |
| **상태 관리** | flutter_riverpod 2.x | StateNotifier 기반, override로 비동기 초기값 주입 |
| **라우팅** | go_router 14.x | 선언적 라우트, 딥링크 친화 |
| **음성 캡처** | record 5.x (mobile/web 분기) | 16kHz mono WAV. macOS는 `AudioEncoder.wav`로 헤더 직접 작성 |
| **음성 재생** | just_audio 0.9.x (StreamAudioSource) | Kanana-o가 보내는 24kHz 청크를 인메모리 스트림으로 재생 |
| **AI 통신** | http.Client + 자체 SSE 파서 ([kanana_client.dart](lib/core/network/kanana_client.dart)) | OpenAI SDK 호환. base_url/apiKey 런타임 주입 |
| **저장소** | shared_preferences | 사용자 키만 (BYO-key) |
| **백엔드** | 없음 (BYO-key, 클라이언트 → Kanana-o 직접 호출) | 운영 비용 0, 어뷰즈 표적 X |

---

## Kanana-o API 연동 가이드

### 기본 설정

Kanana-o는 OpenAI SDK 호환 인터페이스를 제공한다. `base_url`과 `model`만 변경하면 기존 OpenAI 코드를 재활용할 수 있다.

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://kanana-o.a2s-endpoint.kr-central-2.kakaocloud.com/v1",
    api_key="<KANANA_API_KEY>"
)
```

### 1. 이미지 분석 (메뉴판 인식)

```python
import base64

def b64_of_file(path: str) -> str:
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")

image_b64 = b64_of_file("menu_photo.jpg")

response = client.chat.completions.create(
    model="kanana-o",
    messages=[{
        "role": "user",
        "content": [
            {"type": "image_url", "image_url": {"url": image_b64}},
            {"type": "text", "text": """이 메뉴판의 모든 메뉴를 분석해주세요.
반드시 아래 형식으로만 답해주세요.

[FORMAT]
MENU: <메뉴명> | PRICE: <가격> | CATEGORY: <카테고리>
[/FORMAT]

--- 예시 ---
MENU: 김치찌개 | PRICE: 8000 | CATEGORY: 찌개류
MENU: 제육볶음 | PRICE: 9000 | CATEGORY: 볶음류"""}
        ]
    }]
)
```

> **팁**: 멀티모달 요청 시 출력 형식을 강제하려면 FORMAT 태그 + Few-shot 예시를 함께 사용해야 준수율이 높아진다. (레퍼런스 프로젝트 커나나에서 검증된 방식)

### 2. 모드 A: 음성만으로 대화 (메인 기능)

```python
audio_b64 = b64_of_file("user_voice.wav")  # 16kHz WAV

response = client.chat.completions.create(
    model="kanana-o",
    messages=[
        {
            "role": "system",
            "content": """당신은 '아무거나' 앱의 AI 결정 도우미입니다.
사용자의 음성 톤과 감정을 분석하여 숨은 선호를 파악하세요.

[역할]
- 사용자가 "아무거나"라고 말해도 톤에서 진짜 원하는 것을 추론
- 상황을 파악하기 위해 자연스럽게 질문 (혼밥인지, 시간 여유, 분위기 등)
- 감정 미러링: 사용자의 감정 상태를 읽고 공감하며 응답
- 친근하고 재미있는 톤으로 대화. 한국 음식 문화에 정통할 것

[감정 분석 가이드]
- 피곤한 톤 → 편안하고 따뜻한 음식 추천 (국밥, 찌개, 칼국수)
- 들뜬 톤 → 새롭고 특별한 음식 추천 (맛집 탐방, 이색 메뉴)
- 짜증 섞인 톤 → 빠르게 결정 도와주기 (선택지 2개로 좁혀서 제시)
- 망설이는 톤 → 선택지를 좁혀주는 질문하기

[상황 파악 질문 예시]
- "혼자 먹어요? 같이 먹는 사람 있어요?"
- "시간 여유 있어요? 빨리 먹어야 해요?"
- "어제 뭐 먹었어요?" (중복 회피)
- "매운 거 괜찮아요?"

[응답 규칙]
- 한 번에 3개 이상의 선택지를 주지 말 것. 최대 2개로 좁혀서 제시
- 사용자의 톤 변화를 언급하며 감정 미러링할 것
- 예: "칼국수 말할 때 목소리가 확 밝아졌어요 ㅋㅋ"
- 결정이 나면 축하하며 결정 유형 힌트를 줄 것"""
        },
        {
            "role": "user",
            "content": [
                {"type": "input_audio", "input_audio": {"data": audio_b64, "format": "wav"}}
            ]
        }
    ],
    modalities=["text", "audio"],
    extra_body={"latency_first": True},
    audio={"voice": "preset_spk_1"},
    stream=True,
)
```

### 3. 모드 B: 음성 + 이미지 동시 처리 (메뉴판 분석)

```python
image_b64 = b64_of_file("menu_photo.jpg")
audio_b64 = b64_of_file("user_voice.wav")  # 16kHz WAV

response = client.chat.completions.create(
    model="kanana-o",
    messages=[
        {
            "role": "system",
            "content": """당신은 '아무거나' 앱의 AI 결정 도우미입니다.
사용자의 음성 톤과 감정을 분석하여 숨은 선호를 파악하세요.

[역할]
- 사용자가 "아무거나"라고 말해도 톤에서 진짜 원하는 것을 추론
- 메뉴판 이미지가 있으면 해당 메뉴 중에서 추천
- 감정 미러링: 사용자의 감정 상태를 읽고 공감하며 응답
- 친근하고 재미있는 톤으로 대화

[감정 분석 가이드]
- 피곤한 톤 → 편안하고 따뜻한 메뉴 추천
- 들뜬 톤 → 새롭고 특별한 메뉴 추천
- 짜증 섞인 톤 → 빠르게 결정 도와주기
- 망설이는 톤 → 선택지를 좁혀주는 질문하기"""
        },
        {
            "role": "user",
            "content": [
                {"type": "image_url", "image_url": {"url": image_b64}},
                {"type": "input_audio", "input_audio": {"data": audio_b64, "format": "wav"}}
            ]
        }
    ],
    modalities=["text", "audio"],
    extra_body={"latency_first": True},
    audio={"voice": "preset_spk_1"},
    stream=True,
)
```

### 4. 멀티턴 대화 (히스토리 관리)

```python
# 세션별 대화 히스토리 관리
session_history = {}

def chat_with_context(session_id, new_message, image_b64=None, audio_b64=None):
    history = session_history.get(session_id, [])
    
    # 새 메시지 구성
    content = []
    if image_b64:
        content.append({"type": "image_url", "image_url": {"url": image_b64}})
    if audio_b64:
        content.append({"type": "input_audio", "input_audio": {"data": audio_b64, "format": "wav"}})
    if new_message:
        content.append({"type": "text", "text": new_message})
    
    history.append({"role": "user", "content": content})
    
    response = client.chat.completions.create(
        model="kanana-o",
        messages=history,
        modalities=["text", "audio"],
        extra_body={"latency_first": True},
        audio={"voice": "preset_spk_1"},
        stream=True,
    )
    
    # 응답을 히스토리에 추가
    assistant_text = extract_text_from_stream(response)
    history.append({"role": "assistant", "content": [{"type": "text", "text": assistant_text}]})
    session_history[session_id] = history
    
    return response
```

### 주요 연동 팁

1. **SSE 스트리밍**: HTTP SSE로 청크 단위 실시간 전달. 실제 구현은 [`kanana_client.dart`](lib/core/network/kanana_client.dart) 참고
2. **멀티모달 이미지 처리**: 이미지는 Base64 인코딩 후 Data URL 포맷으로 전달
3. **음성 파이프라인**: record 패키지로 16kHz mono WAV 직접 녹음 → Base64 인코딩
4. **음성 출력**: Kanana-o 응답 오디오는 24kHz 샘플레이트. just_audio StreamAudioSource로 인메모리 재생
5. **출력 형식 강제**: FORMAT 태그 + Few-shot 예시로 준수율 향상
6. **쿼터 관리**: 텍스트 모드로 로직 먼저 검증 → 음성은 나중에 테스트
7. **녹음 제한**: Kanana-o 서버 60초 제한. 클라이언트에서 50초 하드 리밋으로 자동 중지

---

## MVP 범위 및 로드맵

### Phase 1: 데모 MVP (4주)

> **목표**: 카카오 앰배서더 제출용 데모. 모드 A를 메인으로, 모드 B를 추가 임팩트로 보여준다.

**모드 A: "뭐 먹지?" (핵심)**:
- [x] 음성 녹음 + WAV 파이프라인 (mobile/web 분기, 50초 하드 리밋)
- [x] Kanana-o 음성 API 호출 (스트리밍 + TTS 응답)
- [x] 대화형 맥락 질문 + 멀티턴 (apiHistory에 transcript 누적)
- [x] 감정 게이지 (룰베이스 + 모델 메타 협력)
- [x] AI 음성 응답 자동 재생
- [x] 결정 완료 화면 + 결정 유형 카드 (4종, confetti)
- [x] 거부 메뉴 회피 (시스템 프롬프트 + history 컨텍스트)

**모드 B: "뭐 시키지?" (Vision)**:
- [x] 메뉴판 사진 업로드 (여러 장) / 카메라 (mobile only)
- [x] Kanana-o Vision API — 카테고리별 메뉴 분류
- [x] 분석 중 spinner / 결과 확인 단계 / 다시 찍기 분기
- [x] 메뉴판 기반 음성 대화 (메뉴 컨텍스트 history 주입)
- [x] 채팅 상단 메뉴판 썸네일 칩

**공통/인프라**:
- [x] 결정 유형 카드 디자인 4종
- [x] BYO-key 모드 (사용자 키 입력 + 라우팅 가드)
- [x] 디버그 로그 화면 (세션 폴더 + 턴별 raw/메타)
- [x] 반응형 모바일 UI (다크 테마)
- [ ] 카카오톡 공유 (결정 유형 카드 OG 이미지)

### Phase 2: 그룹 기능 (미착수)

- [ ] 눈치 모드 (그룹 링크 생성)
- [ ] 다수 음성 입력 수집 + 선호 교집합 분석
- [ ] 그룹 결정 히스토리
- [ ] 결정 유형 궁합

### Phase 3: 바이럴 최적화 (미착수)

- [ ] 결정 유형 카드 SNS 최적화 (OG 이미지)
- [ ] 인스타그램 스토리 사이즈 카드
- [ ] 결정 유형 통계 대시보드
- [ ] 음식 외 카테고리 확장 (쇼핑, 여행, 일상)

---

## 참고 자료

### Kanana-o 공식 자료

- [Kanana-o API 문서 (HuggingFace)](https://huggingface.co/kakaocorp/Kanana-1.5-o-9.8B-instruct-2602-API_Doc)
- [Kanana-o 공식 홈페이지](https://omni.kanana.ai/)
- [카카오 테크블로그 — Kanana-o 알아보기](https://tech.kakao.com/posts/702)
- [카카오 테크블로그 — Kanana-o 진화 과정](https://tech.kakao.com/posts/802)
- [카카오 테크블로그 — Kanana-v 알아보기](https://tech.kakao.com/posts/667)

### 레퍼런스 프로젝트

- [커나나 리뷰 블로그 (방구석 개발자)](https://snapcode.tistory.com/200)
- [커나나 시연 영상 (YouTube Shorts)](https://www.youtube.com/shorts/u-mUY1Mn_aI)

---

## 라이선스

MIT License — 자세한 내용은 [LICENSE](LICENSE) 파일을 참고하세요.

> ⚠️ **상표 안내**: "Kanana", "Kanana-o", "Kakao"는 카카오의 상표이며, 본 프로젝트는 해당 API/서비스를 사용할 뿐 카카오의 공식 프로덕트가 아닙니다. 본 프로젝트의 MIT 라이선스는 코드에만 적용되며, 카카오 상표 사용권을 부여하지 않습니다.

---

## 기여

이 프로젝트는 카카오 AI 앰배서더 Kanana-o 베타 테스트 프로그램의 일환으로 제작되었습니다.

### 관련 문서

- [lib/features/debug_log/](lib/features/debug_log/) — 매 턴의 입력/응답/메타 추적용 로그 화면
- [lib/features/chat/data/services/meta_extractor.dart](lib/features/chat/data/services/meta_extractor.dart) — 모델 메타 누락 시 룰베이스 추출
- [lib/core/network/kanana_client.dart](lib/core/network/kanana_client.dart) — Kanana-o 직접 호출 클라이언트 (OpenAI 호환 + SSE 스트리밍 파서)

---

> **"아무거나"는 단순한 앱이 아닙니다.**
> **한국인의 "아무거나"를 진짜로 번역할 수 있는 유일한 AI, Kanana-o의 가치를 증명하는 프로덕트입니다.**