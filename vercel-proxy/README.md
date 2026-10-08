# Pinch FatSecret proxy on Vercel

This Vercel Function keeps the FatSecret OAuth 2 client secret and access
tokens off the iOS and Android apps. It intentionally exposes only:

- `GET /v1/health`
- `GET /v1/search?q=...&limit=...`
- `GET /v1/food/{numeric-id}`

Search and food requests require both headers:

```text
Authorization: Bearer <PINCH_PROXY_API_KEY>
X-Pinch-Platform: ios | android
```

Configure these encrypted Vercel environment variables for Production,
Preview, and Development as appropriate:

```text
FATSECRET_CLIENT_ID
FATSECRET_CLIENT_SECRET
PINCH_PROXY_API_KEY
PINCH_RATE_LIMIT_PER_MINUTE=60
```

`PINCH_PROXY_API_KEY` prevents casual unauthorized use, but it is embedded in
a compiled mobile application and can eventually be extracted. Keep Vercel
Firewall rate limiting enabled and use Apple App Attest plus Google Play
Integrity if the API later needs strong client attestation.

## iOS client configuration

The app needs the public HTTPS proxy URL plus the app-scoped `PINCH_PROXY_API_KEY`.
It must never contain `FATSECRET_CLIENT_SECRET` or OAuth access tokens.

For local builds, copy the repository-root `PinchProxyConfig.sample.plist` to
`Sodium Tracker/Resources/PinchProxyConfig.plist` and replace its `apiKey` value
with the existing app proxy key. This destination is gitignored and bundled by
Xcode. Provision it securely for CI/archive builds too, or supply the generated
Info.plist `PinchProxyAPIKey` setting. A process environment override supports
development runs. Never commit a real key to the sample file.

`Resources/FatSecretSecrets.plist` is explicitly excluded from the iOS target.
If any earlier distributed build included that legacy file, rotate the FatSecret
OAuth client secret and update the server together before shipping again.

Run `node --test test/proxy.test.mjs` to verify the proxy contract. Local changes
to this directory do not update the production Vercel Function until deployed.

## FatSecret IP allowlisting

Ordinary Vercel Functions do not have fixed egress addresses. For production,
enable Vercel Static IPs for this project and add both assigned egress IPs to
FatSecret's allowlist. Static IPs require a Pro or Enterprise team and are a
paid project add-on. Do not use the Edge runtime; Static IPs apply to Node.js
Functions, not Edge Middleware.
