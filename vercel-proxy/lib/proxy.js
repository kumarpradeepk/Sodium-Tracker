import { timingSafeEqual } from "node:crypto";

export const TOKEN_ENDPOINT = "https://oauth.fatsecret.com/connect/token";
export const API_ENDPOINT = "https://platform.fatsecret.com/rest/server.api";

const tokenCache = { value: "", expiresAt: 0 };
const rateWindows = new Map();

export function constantTimeEqual(left, right) {
  const leftBuffer = Buffer.from(String(left));
  const rightBuffer = Buffer.from(String(right));
  return leftBuffer.length === rightBuffer.length && timingSafeEqual(leftBuffer, rightBuffer);
}

export function isAuthorized(header, expectedKey) {
  if (!expectedKey || !header?.startsWith("Bearer ")) return false;
  return constantTimeEqual(header.slice(7).trim(), expectedKey.trim());
}

export function normalizedPath(pathValue) {
  if (Array.isArray(pathValue)) return pathValue.map(String).join("/");
  return String(pathValue ?? "").replace(/^\/+|\/+$/g, "");
}

export function asList(value) {
  if (!value || typeof value !== "object") return [];
  return Array.isArray(value) ? value : [value];
}

export function normalizeSearch(root) {
  return asList(root?.foods?.food).flatMap((food) => {
    const id = String(food?.food_id ?? "").trim();
    const name = String(food?.food_name ?? "").trim();
    if (!id || !name) return [];
    const brand = String(food?.brand_name ?? "").trim();
    return [{
      id,
      name,
      brand: brand || null,
      summary: String(food?.food_description ?? "").trim(),
    }];
  });
}

export function normalizeFood(root) {
  const food = root?.food ?? {};
  for (const serving of asList(food?.servings?.serving)) {
    const sodium = Number(serving?.sodium);
    if (!Number.isFinite(sodium)) continue;
    const detail = {
      name: String(food?.food_name ?? "Food").trim() || "Food",
      serving: String(serving?.serving_description ?? "1 serving").trim() || "1 serving",
      sodiumMg: Math.round(sodium),
    };
    const calories = Number(serving?.calories);
    if (Number.isFinite(calories)) detail.calories = Math.round(calories);
    return detail;
  }
  return null;
}

export function enforceRateLimit(ip, limit = 60, now = Date.now()) {
  const safeLimit = Math.max(10, Math.min(Number(limit) || 60, 300));
  const window = Math.floor(now / 60_000);
  const key = `${ip}:${window}`;
  const count = rateWindows.get(key) ?? 0;
  if (count >= safeLimit) return false;
  rateWindows.set(key, count + 1);
  if (rateWindows.size > 2_000) {
    for (const savedKey of rateWindows.keys()) {
      if (!savedKey.endsWith(`:${window}`)) rateWindows.delete(savedKey);
    }
  }
  return true;
}

async function jsonFetch(url, options) {
  const response = await fetch(url, { ...options, signal: AbortSignal.timeout(12_000) });
  const payload = await response.json().catch(() => null);
  return { response, payload };
}

export async function accessToken(env = process.env, forceRefresh = false) {
  if (!forceRefresh && tokenCache.value && tokenCache.expiresAt > Date.now() + 60_000) {
    return tokenCache.value;
  }
  const id = String(env.FATSECRET_CLIENT_ID ?? "").trim();
  const secret = String(env.FATSECRET_CLIENT_SECRET ?? "").trim();
  if (!id || !secret) throw new Error("FatSecret OAuth configuration is incomplete");
  const basic = Buffer.from(`${id}:${secret}`).toString("base64");
  const { response, payload } = await jsonFetch(TOKEN_ENDPOINT, {
    method: "POST",
    headers: {
      Accept: "application/json",
      Authorization: `Basic ${basic}`,
      "Content-Type": "application/x-www-form-urlencoded",
      "User-Agent": "Pinch-FatSecret-Proxy/2.0",
    },
    body: "grant_type=client_credentials&scope=basic",
  });
  if (!response.ok || typeof payload?.access_token !== "string") {
    throw new Error("FatSecret token request failed");
  }
  tokenCache.value = payload.access_token;
  tokenCache.expiresAt = Date.now() + Math.max(120, Number(payload.expires_in) || 3600) * 1000;
  return tokenCache.value;
}

export async function fatSecretRequest(parameters, env = process.env) {
  for (let attempt = 0; attempt < 2; attempt += 1) {
    const token = await accessToken(env, attempt === 1);
    const { response, payload } = await jsonFetch(API_ENDPOINT, {
      method: "POST",
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/x-www-form-urlencoded",
        "User-Agent": "Pinch-FatSecret-Proxy/2.0",
      },
      body: new URLSearchParams(parameters).toString(),
    });
    if (response.status === 401 && attempt === 0) {
      tokenCache.value = "";
      tokenCache.expiresAt = 0;
      continue;
    }
    if (!response.ok || !payload || payload.error) throw new Error("FatSecret API request failed");
    return payload;
  }
  throw new Error("FatSecret API request failed");
}
