import test from "node:test";
import assert from "node:assert/strict";
import { isAuthorized, normalizeFood, normalizedPath, normalizeSearch } from "../lib/proxy.js";
import { requestPath } from "../api/v1/[...path].js";

test("missing or invalid sodium is not converted into zero", () => {
  for (const sodium of [null, undefined, "", " ", -1, "NaN", "Infinity", 1e30]) {
    assert.equal(normalizeFood({ food: { servings: { serving: { sodium } } } }), null);
  }
  assert.deepEqual(normalizeFood({ food: { servings: { serving: { sodium: "0" } } } }),
    { name: "Food", serving: "1 serving", sodiumMg: 0 });
});

test("checks bearer authorization without accepting malformed headers", () => {
  assert.equal(isAuthorized("Bearer test-key", "test-key"), true);
  assert.equal(isAuthorized("test-key", "test-key"), false);
  assert.equal(isAuthorized("Bearer wrong", "test-key"), false);
});

test("normalizes catch-all paths", () => {
  assert.equal(normalizedPath(["food", "123"]), "food/123");
  assert.equal(normalizedPath("/search/"), "search");
});

test("recovers a rewritten route from the request URL", () => {
  assert.equal(requestPath({ query: {}, url: "/v1/health" }), "health");
  assert.equal(requestPath({ query: {}, url: "/api/v1/food/123?x=1" }), "food/123");
  assert.equal(requestPath({ query: { path: ["food", "456"] }, url: "/" }), "food/456");
});

test("normalizes the restricted search response", () => {
  assert.deepEqual(normalizeSearch({ foods: { food: { food_id: "1", food_name: "Soup" } } }), [{
    id: "1",
    name: "Soup",
    brand: null,
    summary: "",
  }]);
});

test("returns only the first sodium-bearing serving", () => {
  assert.deepEqual(normalizeFood({ food: {
    food_name: "Soup",
    servings: { serving: [{ serving_description: "1 cup", sodium: "330", calories: "90" }] },
  } }), { name: "Soup", serving: "1 cup", sodiumMg: 330, calories: 90 });
});
