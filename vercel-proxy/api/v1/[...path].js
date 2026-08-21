import {
  enforceRateLimit,
  fatSecretRequest,
  isAuthorized,
  normalizeFood,
  normalizedPath,
  normalizeSearch,
} from "../../lib/proxy.js";

function send(response, status, payload) {
  response.status(status);
  response.setHeader("Content-Type", "application/json; charset=utf-8");
  response.setHeader("Cache-Control", "no-store, max-age=0");
  response.setHeader("X-Content-Type-Options", "nosniff");
  response.setHeader("Referrer-Policy", "no-referrer");
  response.send(JSON.stringify(payload));
}

function fail(response, status, code) {
  send(response, status, { error: { code } });
}

function requestIp(request) {
  const forwarded = request.headers["x-forwarded-for"];
  const first = Array.isArray(forwarded) ? forwarded[0] : String(forwarded ?? "").split(",")[0];
  return first.trim() || request.socket?.remoteAddress || "unknown";
}

export function requestPath(request) {
  const routedPath = normalizedPath(request.query?.path);
  if (routedPath) return routedPath;

  // Vercel's rewrite may invoke a catch-all function without preserving the
  // dynamic query key. Derive the route from the original URL as a fallback.
  const pathname = new URL(request.url ?? "/", "https://proxy.invalid").pathname;
  return pathname
    .replace(/^\/api\/v1\/?/, "")
    .replace(/^\/v1\/?/, "")
    .replace(/^\/+|\/+$/g, "");
}

export default async function handler(request, response) {
  try {
    if (request.method !== "GET") {
      response.setHeader("Allow", "GET");
      return fail(response, 405, "METHOD_NOT_ALLOWED");
    }

    const path = requestPath(request);
    if (path === "health") return send(response, 200, { status: "ok" });

    const proxyKey = String(process.env.PINCH_PROXY_API_KEY ?? "").trim();
    if (!proxyKey) return fail(response, 503, "SERVICE_UNAVAILABLE");
    if (!isAuthorized(request.headers.authorization, proxyKey)) {
      response.setHeader("WWW-Authenticate", "Bearer");
      return fail(response, 401, "UNAUTHORIZED");
    }

    const platform = String(request.headers["x-pinch-platform"] ?? "").toLowerCase();
    if (!new Set(["ios", "android"]).has(platform)) return fail(response, 400, "INVALID_CLIENT");
    if (!enforceRateLimit(requestIp(request), process.env.PINCH_RATE_LIMIT_PER_MINUTE)) {
      response.setHeader("Retry-After", "60");
      return fail(response, 429, "RATE_LIMITED");
    }

    if (path === "search") {
      const query = String(request.query.q ?? "").trim();
      if (query.length < 2 || query.length > 120) return fail(response, 400, "INVALID_QUERY");
      const limit = Math.max(1, Math.min(Number(request.query.limit) || 20, 20));
      const root = await fatSecretRequest({
        method: "foods.search",
        search_expression: query,
        max_results: String(limit),
        format: "json",
      });
      return send(response, 200, { foods: normalizeSearch(root) });
    }

    const foodMatch = /^food\/(\d{1,20})$/.exec(path);
    if (foodMatch) {
      const root = await fatSecretRequest({ method: "food.get.v5", food_id: foodMatch[1], format: "json" });
      const detail = normalizeFood(root);
      return detail ? send(response, 200, detail) : fail(response, 422, "SODIUM_UNAVAILABLE");
    }

    return fail(response, 404, "NOT_FOUND");
  } catch (error) {
    console.error("Pinch FatSecret proxy request failed", { name: error?.name });
    return fail(response, 503, "SERVICE_UNAVAILABLE");
  }
}
