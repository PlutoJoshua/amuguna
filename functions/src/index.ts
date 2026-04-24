import {onRequest} from "firebase-functions/v2/https";
import {defineSecret, defineInt} from "firebase-functions/params";
import {logger} from "firebase-functions/v2";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

const KANANA_API_KEY = defineSecret("KANANA_API_KEY");
const DAILY_USERS_LIMIT = defineInt("DAILY_USERS_LIMIT", {default: 20});
const PER_USER_DAILY = defineInt("PER_USER_DAILY", {default: 5});

const KANANA_BASE_URL =
  "https://kanana-o.a2s-endpoint.kr-central-2.kakaocloud.com/v1";

/**
 * Kanana-o 프록시.
 *
 * 동작:
 * 1) `Authorization: Bearer <userKey>` 가 요청에 있으면 **그대로 forward** (쿼터 카운트 X).
 *    사용자가 본인 Kanana-o 키를 입력한 경로.
 * 2) 없으면 서버 비밀에 저장된 공용 키를 주입하고 **Firestore 쿼터 트랜잭션**:
 *    - `X-Client-Id` 헤더 기반 익명 식별
 *    - 하루 N명(기본 20) 신규 유저만 받음
 *    - 한 유저당 하루 M회(기본 5) 호출 제한
 * 3) 스트리밍(`body.stream === true`)은 SSE로 그대로 pass-through.
 */
export const kananaProxy = onRequest(
  {
    secrets: [KANANA_API_KEY],
    cors: true,
    memory: "512MiB",
    timeoutSeconds: 300,
    region: "asia-northeast3", // 서울 리전
  },
  async (req, res): Promise<void> => {
    // 경로: /api/kanana-proxy/chat/completions → req.path === "/chat/completions"
    // (Firebase Hosting rewrite가 /api/kanana-proxy 접두를 떼어내고 forward하는 것을 가정)
    if (req.method !== "POST") {
      res.status(405).json({error: "method_not_allowed"});
      return;
    }
    if (!req.path.endsWith("/chat/completions")) {
      res.status(404).json({error: "not_found", path: req.path});
      return;
    }

    const userAuth = req.header("Authorization");
    const clientId =
      req.header("X-Client-Id") ||
      req.ip ||
      "anonymous";

    let upstreamKey: string;
    let countQuota = false;

    if (userAuth && userAuth.startsWith("Bearer ")) {
      upstreamKey = userAuth.substring(7);
    } else {
      upstreamKey = KANANA_API_KEY.value();
      countQuota = true;
    }

    // 공용 키 경로에만 쿼터 적용
    if (countQuota) {
      const today = new Date().toISOString().slice(0, 10);
      const quotaRef = db.collection("quota").doc(today);

      try {
        await db.runTransaction(async (tx) => {
          const snap = await tx.get(quotaRef);
          const data = snap.exists ?
            (snap.data() as {
              users?: Record<string, number>;
              totalUsers?: number;
            }) :
            {};
          const users = data.users ?? {};
          const totalUsers = data.totalUsers ?? 0;

          const userCount = users[clientId] ?? 0;
          const isNewUser = !(clientId in users);

          if (isNewUser && totalUsers >= DAILY_USERS_LIMIT.value()) {
            throw new Error("daily_users_exhausted");
          }
          if (userCount >= PER_USER_DAILY.value()) {
            throw new Error("per_user_exhausted");
          }

          users[clientId] = userCount + 1;
          tx.set(
            quotaRef,
            {
              users,
              totalUsers: isNewUser ? totalUsers + 1 : totalUsers,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            {merge: true}
          );
        });
      } catch (e) {
        const msg = (e as Error).message;
        if (
          msg === "daily_users_exhausted" ||
          msg === "per_user_exhausted"
        ) {
          logger.info("Quota exhausted", {clientId, reason: msg});
          res.status(429).json({error: msg});
          return;
        }
        logger.error("Quota transaction error", {clientId, error: msg});
        res.status(500).json({error: "quota_internal_error"});
        return;
      }
    }

    // 업스트림 요청
    const isStream = req.body?.stream === true;
    const upstreamUrl = `${KANANA_BASE_URL}/chat/completions`;

    let upstream: Response;
    try {
      upstream = await fetch(upstreamUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${upstreamKey}`,
        },
        body: JSON.stringify(req.body),
      });
    } catch (e) {
      logger.error("Upstream fetch failed", {
        error: (e as Error).message,
        clientId,
      });
      res.status(502).json({error: "upstream_unreachable"});
      return;
    }

    if (!upstream.ok) {
      const text = await upstream.text();
      logger.warn("Upstream error", {
        status: upstream.status,
        body: text.slice(0, 500),
        clientId,
      });
      res.status(upstream.status).type(
        upstream.headers.get("content-type") ?? "text/plain"
      ).send(text);
      return;
    }

    // 스트리밍 pass-through
    if (isStream && upstream.body) {
      res.setHeader("Content-Type", "text/event-stream");
      res.setHeader("Cache-Control", "no-cache");
      res.setHeader("Connection", "keep-alive");
      res.setHeader("X-Accel-Buffering", "no"); // 일부 프록시 버퍼링 방지

      const reader = upstream.body.getReader();
      try {
        while (true) {
          const {done, value} = await reader.read();
          if (done) break;
          res.write(Buffer.from(value));
        }
      } catch (e) {
        logger.warn("Streaming abort", {error: (e as Error).message});
      } finally {
        res.end();
      }
      return;
    }

    // 비스트리밍
    const text = await upstream.text();
    res.setHeader(
      "Content-Type",
      upstream.headers.get("content-type") ?? "application/json"
    );
    res.status(upstream.status).send(text);
  }
);

/**
 * 헬스체크 — 배포 후 동작 확인용
 */
export const health = onRequest(
  {cors: true, region: "asia-northeast3"},
  (_req, res) => {
    res.json({
      status: "ok",
      service: "amuguna-kanana-proxy",
      timestamp: new Date().toISOString(),
    });
  }
);
