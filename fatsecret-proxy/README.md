# Pinch FatSecret proxy

This is the production boundary for FatSecret. It uses the OAuth 2 client
credentials **only on the server**, caches the access token in a private
directory, and exposes a deliberately small HTTPS API for the Pinch iOS and
Android apps:

- `GET /v1/search?q=ramen&limit=20`
- `GET /v1/food/12345`
- `GET /v1/health`

It does not accept a FatSecret method, bearer token, client ID, or client
secret from an app. Responses are normalized, upstream bodies are not passed
through, and the proxy has an IP-based limit of 60 requests per minute by
default. The apps must continue to display FatSecret attribution.

## BigRock cPanel deployment

Use this only on a BigRock plan that gives the server a stable public **egress
IPv4 address**. Shared hosting may not offer that guarantee; verify it with
BigRock support before going live. A BigRock VPS with a dedicated IPv4 address
is suitable.

1. In cPanel, choose a subdomain such as `api.YOUR_DOMAIN` and enable its SSL
   certificate. Its document root should be `public_html/pinch-api`.
2. Upload the **contents** of `public/` to that document root (not the parent
   `fatsecret-proxy` directory).
3. In the account home directory, not under `public_html`, create:
   `pinch-api-private/cache` and set its permissions to `0700`.
4. Copy `private/fatsecret-config.php.example` to
   `~/pinch-api-private/fatsecret-config.php`; enter the real **OAuth 2**
   client ID and client secret and replace `CPANEL_USER` in `cache_dir`.
   Keep this file out of the web root and source control.
5. Check `https://api.YOUR_DOMAIN/v1/health` returns `{"status":"ok"}`.
6. Obtain the server's **outbound** IPv4 from BigRock, then add exactly
   `OUTBOUND_IP/32` in FatSecret **Manage API Keys**. Do not whitelist the
   mobile clients or `0.0.0.0/0` for production.
7. Set `FatSecretProxyURL` for the iOS app and `FATSECRET_PROXY_URL` in the
   Android release build to `https://api.YOUR_DOMAIN/v1`.

The built-in cPanel path fallback expects:

```
/home/CPANEL_USER/public_html/pinch-api/index.php
/home/CPANEL_USER/pinch-api-private/fatsecret-config.php
```

If the host uses another document root, set the `PINCH_FATSECRET_CONFIG`
environment variable to the absolute config path instead.

## Required production controls

- Require PHP 8.1+ and the cURL extension; do not deploy on a plan that cannot
  provide them.
- Use HTTPS only. Do not expose a debug endpoint or request/response logging.
- Restrict cPanel and SSH access with MFA. Rotate the FatSecret secret if it
  was ever copied into an app, committed, or pasted into an unsafe channel.
- A public mobile API can still be abused. Before broad release, put this
  behind a WAF/rate-limit layer and add Apple App Attest / Play Integrity
  verification so only genuine Pinch apps can call it.
- Keep FatSecret attribution visible in the product as required by its terms.
