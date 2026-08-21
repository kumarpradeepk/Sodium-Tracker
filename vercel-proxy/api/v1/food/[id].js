// Vercel does not consistently dispatch a nested path to the sibling
// catch-all function. Keep the public contract at /v1/food/{id}, while
// reusing the same authorization, rate-limit, and normalization handler.
export { default } from "../[...path].js";
