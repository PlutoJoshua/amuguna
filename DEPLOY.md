# 배포 가이드 (Firebase Hosting + Functions)

amuguna를 일주일간 퍼블릭 베타로 열기 위한 단계별 배포 가이드. 사용자가 직접 실행해야 하는 커맨드만 정리했다.

---

## 1. 사전 준비 (한 번만)

```bash
# Firebase CLI
npm install -g firebase-tools

# 로그인
firebase login

# 프로젝트 생성 (Firebase Console에서 미리 만들어둬도 됨)
# 예: https://console.firebase.google.com → 프로젝트 추가 → 이름 "amuguna-beta"
```

프로젝트 루트에서:

```bash
firebase use --add   # 방금 만든 프로젝트 선택, alias는 "default"로
```

→ `.firebaserc` 파일 자동 생성.

### Blaze 요금제 업그레이드 (필수)
Firebase Functions는 **Blaze(종량제)** 에서만 동작. 무료 티어 안에서 쓰면 비용 0이지만 카드 등록 필요.

Console에서 "프로젝트 설정 → 요금제 → 업그레이드" 클릭.

### Firestore 초기화
Console에서 **Firestore Database → 데이터베이스 만들기 → 프로덕션 모드 → 리전 `asia-northeast3`** 로 생성.

---

## 2. 공용 Kanana-o API 키를 Secret Manager에 주입

이 키가 브라우저에 노출되지 않게 하려고 프록시를 세운 것. **절대 코드에 박지 말 것.**

```bash
firebase functions:secrets:set KANANA_API_KEY
# 프롬프트에 공용으로 쓸 Kanana-o 키 붙여넣고 Enter
```

`DAILY_USERS_LIMIT`, `PER_USER_DAILY` 은 기본값(20/5)으로 충분. 바꾸려면:

```bash
firebase functions:params:set DAILY_USERS_LIMIT 20
firebase functions:params:set PER_USER_DAILY 5
```

---

## 3. 프록시 함수 배포

```bash
cd functions
npm install          # 첫 배포 전 한 번
npm run build        # TypeScript 컴파일
cd ..

firebase deploy --only functions
```

성공하면 터미널에 URL이 출력됨. 예:
```
✔ functions[kananaProxy(asia-northeast3)] Successful create operation.
Function URL (kananaProxy): https://asia-northeast3-<project-id>.cloudfunctions.net/kananaProxy
```

하지만 실제로 앱은 **Hosting rewrite 경로** (`https://<project>.web.app/api/kanana-proxy/...`)로 접근한다. 그래서 4번도 필요.

---

## 4. Firestore 보안 규칙 배포

```bash
firebase deploy --only firestore:rules
```

`quota/*` 컬렉션은 클라이언트에서 직접 접근 차단. Admin SDK(= Functions)만 쓴다.

---

## 5. Flutter Web 빌드 + Hosting 배포

프로젝트 호스팅 주소는 보통 `https://<project-id>.web.app`. 빌드할 때 이 도메인을 `PROXY_BASE_URL`로 주입.

```bash
# 프로젝트 루트로 돌아가서
flutter build web --release \
  --dart-define=PROXY_BASE_URL=https://<project-id>.web.app

firebase deploy --only hosting
```

배포 끝나면 URL이 출력됨. 브라우저에서 열어 테스트.

---

## 6. 동작 확인 (스모크 테스트)

```bash
# 헬스체크
curl https://<project-id>.web.app/api/health

# 프록시 (빈 바디 → 404 또는 400 예상)
curl -X POST https://<project-id>.web.app/api/kanana-proxy/chat/completions \
  -H "Content-Type: application/json" \
  -H "X-Client-Id: test-curl-$(date +%s)" \
  -d '{"model":"kanana-o","messages":[{"role":"user","content":"ping"}],"modalities":["text"]}' \
  | head -c 500
```

두 번째 `curl`이 200 + Kanana-o 응답을 그대로 토해내면 프록시 성공. 401/403 나오면 Secret에 키가 제대로 박혔는지 확인.

그다음 브라우저로 배포된 URL 접속 → 홈 → "뭐 먹지?" → 음성 녹음 → AI 응답 흐름을 완주해봐야 웹 음성 E2E가 실제로 되는지 확증됨.

---

## 7. LinkedIn 글에 붙일 링크

- **공개 체험 링크**: `https://<project-id>.web.app`
- **하루 20명 선착순** — 자기 Kanana-o 키 있으면 설정(⚙️)에서 넣으면 무제한
- 혹시 앱 완전 공개가 부담스러우면 일주일 뒤 `firebase hosting:channel:delete`로 내릴 수 있음

---

## 8. 문제 해결

| 증상 | 원인 | 해결 |
|------|------|------|
| `401 invalid or expired api key` | Secret에 키 안 박힘/오타 | `firebase functions:secrets:set KANANA_API_KEY` 다시 |
| `CORS` 에러 로그 | Hosting rewrite 없이 직접 `.cloudfunctions.net` 호출 | 반드시 `<project>.web.app/api/kanana-proxy/...` 경로 사용 |
| `429 daily_users_exhausted` | 오늘 20명 다 써버림 | 정상 동작. 내일 0시 UTC 리셋. Firestore에서 `quota/<오늘>` 수동 삭제도 가능 |
| 웹에서 마이크 권한 거부 | 브라우저 사이트 권한 차단 | 주소창 왼쪽 🔒 → "마이크 허용" |
| 빌드 에러 `PROXY_BASE_URL not defined` | `--dart-define` 안 줌 | 5번 커맨드 그대로 복붙 |

---

## 9. 일주일 뒤 내리기

```bash
# Hosting 사이트 비우기 (완전 삭제는 Console에서)
firebase hosting:disable

# Functions 삭제
firebase functions:delete kananaProxy health --region asia-northeast3

# Secret 폐기
firebase functions:secrets:destroy KANANA_API_KEY
```

Kanana-o 키는 카카오 측에서 재발급받거나 회수 요청하면 깔끔.
