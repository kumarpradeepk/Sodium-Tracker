<?php
declare(strict_types=1);

/**
 * Pinch's restricted FatSecret production proxy.
 *
 * It exposes only the two nutrition lookups the apps use. OAuth credentials
 * and access tokens must remain on this server; this file never returns them.
 *
 * Requires PHP 8.1+ with the cURL extension. See ../README.md before deploy.
 */

const API_PREFIX = 'Pinch FatSecret proxy';
const TOKEN_ENDPOINT = 'https://oauth.fatsecret.com/connect/token';
const API_ENDPOINT = 'https://platform.fatsecret.com/rest/server.api';

/** @return array<string, mixed> */
function loadConfig(): array
{
    $paths = array_filter([
        getenv('PINCH_FATSECRET_CONFIG') ?: null,
        // Local/deploy-root option: `private/` must never be web-accessible.
        dirname(__DIR__) . '/private/fatsecret-config.php',
        // cPanel subdomain option when the document root is directly under home.
        dirname(__DIR__) . '/pinch-api-private/fatsecret-config.php',
        // cPanel option when this file is in ~/public_html/pinch-api/.
        dirname(__DIR__, 3) . '/pinch-api-private/fatsecret-config.php',
    ]);

    foreach ($paths as $path) {
        if (is_file($path) && is_readable($path)) {
            /** @var array<string, mixed> $config */
            $config = require $path;
            return $config;
        }
    }

    throw new RuntimeException('Server configuration is unavailable.');
}

/** @param mixed $value */
function configString(array $config, string $key): string
{
    $value = $config[$key] ?? '';
    return is_string($value) ? trim($value) : '';
}

/** @param array<string, mixed> $payload */
function respond(int $status, array $payload): never
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store, max-age=0');
    header('X-Content-Type-Options: nosniff');
    header('Referrer-Policy: no-referrer');
    echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit;
}

function fail(int $status, string $code): never
{
    respond($status, ['error' => ['code' => $code]]);
}

function requestIp(): string
{
    // Do not trust X-Forwarded-For here: it is client-controlled unless a
    // trusted reverse proxy has already replaced REMOTE_ADDR.
    $ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
    return is_string($ip) ? $ip : 'unknown';
}

function cacheDirectory(array $config): string
{
    $directory = configString($config, 'cache_dir');
    if ($directory === '' || !is_dir($directory) || !is_writable($directory)) {
        throw new RuntimeException('Secure cache directory is unavailable.');
    }
    return rtrim($directory, '/');
}

function enforceRateLimit(array $config): void
{
    $cache = cacheDirectory($config);
    $limit = (int)($config['rate_limit_per_minute'] ?? 60);
    $limit = max(10, min($limit, 300));
    $window = (int)floor(time() / 60);
    $file = $cache . '/ratelimit-' . hash('sha256', requestIp()) . '.json';
    $handle = @fopen($file, 'c+');
    if ($handle === false) {
        // A broken rate-limit file should not make us disclose a backend error.
        fail(503, 'SERVICE_UNAVAILABLE');
    }

    try {
        if (!flock($handle, LOCK_EX)) {
            fail(503, 'SERVICE_UNAVAILABLE');
        }
        rewind($handle);
        $saved = json_decode(stream_get_contents($handle) ?: '{}', true);
        $count = is_array($saved) && ($saved['window'] ?? null) === $window
            ? (int)($saved['count'] ?? 0)
            : 0;
        if ($count >= $limit) {
            header('Retry-After: 60');
            fail(429, 'RATE_LIMITED');
        }
        rewind($handle);
        ftruncate($handle, 0);
        fwrite($handle, json_encode(['window' => $window, 'count' => $count + 1]));
        fflush($handle);
    } finally {
        flock($handle, LOCK_UN);
        fclose($handle);
    }
}

/** @return array{token: string, expires_at: int}|null */
function readCachedToken(string $cache): ?array
{
    $file = $cache . '/fatsecret-token.json';
    if (!is_file($file)) {
        return null;
    }
    $data = json_decode((string)@file_get_contents($file), true);
    if (!is_array($data) || !is_string($data['token'] ?? null) || !is_int($data['expires_at'] ?? null)) {
        return null;
    }
    return $data['expires_at'] > time() + 60 ? $data : null;
}

/** @param array{token: string, expires_at: int} $token */
function writeCachedToken(string $cache, array $token): void
{
    $file = $cache . '/fatsecret-token.json';
    $tmp = $file . '.' . bin2hex(random_bytes(8)) . '.tmp';
    if (@file_put_contents($tmp, json_encode($token), LOCK_EX) === false || !@rename($tmp, $file)) {
        @unlink($tmp);
        throw new RuntimeException('Token cache write failed.');
    }
    @chmod($file, 0600);
}

function clearCachedToken(string $cache): void
{
    @unlink($cache . '/fatsecret-token.json');
}

/** @return array{status: int, body: string} */
function curlRequest(string $url, array $options): array
{
    $handle = curl_init($url);
    if ($handle === false) {
        throw new RuntimeException('Unable to initialize request.');
    }
    curl_setopt_array($handle, $options + [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CONNECTTIMEOUT => 8,
        CURLOPT_TIMEOUT => 12,
        CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_2TLS,
        CURLOPT_USERAGENT => 'Pinch-FatSecret-Proxy/1.0',
    ]);
    $body = curl_exec($handle);
    $status = (int)curl_getinfo($handle, CURLINFO_RESPONSE_CODE);
    $error = curl_error($handle);
    curl_close($handle);
    if ($body === false) {
        throw new RuntimeException('Upstream request failed: ' . $error);
    }
    return ['status' => $status, 'body' => (string)$body];
}

/** @return array{token: string, expires_at: int} */
function accessToken(array $config, bool $forceRefresh = false): array
{
    $cache = cacheDirectory($config);
    if (!$forceRefresh && ($saved = readCachedToken($cache)) !== null) {
        return $saved;
    }

    $id = configString($config, 'fatsecret_client_id');
    $secret = configString($config, 'fatsecret_client_secret');
    if ($id === '' || $secret === '') {
        throw new RuntimeException('FatSecret OAuth configuration is incomplete.');
    }

    $response = curlRequest(TOKEN_ENDPOINT, [
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => 'grant_type=client_credentials&scope=basic',
        CURLOPT_HTTPHEADER => ['Content-Type: application/x-www-form-urlencoded', 'Accept: application/json'],
        CURLOPT_USERPWD => $id . ':' . $secret,
        CURLOPT_HTTPAUTH => CURLAUTH_BASIC,
    ]);
    $decoded = json_decode($response['body'], true);
    if ($response['status'] !== 200 || !is_array($decoded) || !is_string($decoded['access_token'] ?? null)) {
        throw new RuntimeException('FatSecret token request failed.');
    }
    $token = [
        'token' => $decoded['access_token'],
        'expires_at' => time() + max(120, (int)($decoded['expires_in'] ?? 3600)),
    ];
    writeCachedToken($cache, $token);
    return $token;
}

/** @param array<string, string> $parameters
 *  @return array<string, mixed> */
function fatSecretRequest(array $config, array $parameters): array
{
    for ($attempt = 0; $attempt < 2; $attempt++) {
        $token = accessToken($config, $attempt === 1);
        $response = curlRequest(API_ENDPOINT, [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => http_build_query($parameters, '', '&', PHP_QUERY_RFC3986),
            CURLOPT_HTTPHEADER => [
                'Authorization: Bearer ' . $token['token'],
                'Content-Type: application/x-www-form-urlencoded',
                'Accept: application/json',
            ],
        ]);
        if ($response['status'] === 401 && $attempt === 0) {
            clearCachedToken(cacheDirectory($config));
            continue;
        }
        $decoded = json_decode($response['body'], true);
        if ($response['status'] !== 200 || !is_array($decoded) || isset($decoded['error'])) {
            throw new RuntimeException('FatSecret API request failed.');
        }
        return $decoded;
    }
    throw new RuntimeException('FatSecret API request failed.');
}

/** @return list<array<string, mixed>> */
function asList(mixed $value): array
{
    if (!is_array($value)) {
        return [];
    }
    if (array_is_list($value)) {
        return $value;
    }
    return [$value];
}

/** @param mixed $value */
function stringValue(mixed $value): ?string
{
    if (is_string($value) || is_int($value) || is_float($value)) {
        $value = trim((string)$value);
        return $value === '' ? null : $value;
    }
    return null;
}

/** @param mixed $value */
function numericValue(mixed $value): ?float
{
    return is_numeric($value) ? (float)$value : null;
}

/** @return list<array{id: string, name: string, brand: ?string, summary: string}> */
function search(string $query, int $limit, array $config): array
{
    $root = fatSecretRequest($config, [
        'method' => 'foods.search',
        'search_expression' => $query,
        'max_results' => (string)$limit,
        'format' => 'json',
    ]);
    $foods = is_array($root['foods'] ?? null) ? $root['foods'] : [];
    $results = [];
    foreach (asList($foods['food'] ?? null) as $food) {
        if (!is_array($food)) {
            continue;
        }
        $id = stringValue($food['food_id'] ?? null);
        $name = stringValue($food['food_name'] ?? null);
        if ($id === null || $name === null) {
            continue;
        }
        $results[] = [
            'id' => $id,
            'name' => $name,
            'brand' => stringValue($food['brand_name'] ?? null),
            'summary' => stringValue($food['food_description'] ?? null) ?? '',
        ];
    }
    return $results;
}

/** @return array{name: string, serving: string, sodiumMg: int, calories?: int} */
function foodDetails(string $id, array $config): array
{
    $root = fatSecretRequest($config, [
        'method' => 'food.get.v2',
        'food_id' => $id,
        'format' => 'json',
    ]);
    $food = is_array($root['food'] ?? null) ? $root['food'] : [];
    $servings = is_array($food['servings'] ?? null) ? $food['servings'] : [];
    foreach (asList($servings['serving'] ?? null) as $serving) {
        if (!is_array($serving) || ($sodium = numericValue($serving['sodium'] ?? null)) === null) {
            continue;
        }
        $detail = [
            'name' => stringValue($food['food_name'] ?? null) ?? 'Food',
            'serving' => stringValue($serving['serving_description'] ?? null) ?? '1 serving',
            'sodiumMg' => (int)round($sodium),
        ];
        if (($calories = numericValue($serving['calories'] ?? null)) !== null) {
            $detail['calories'] = (int)round($calories);
        }
        return $detail;
    }
    fail(422, 'SODIUM_UNAVAILABLE');
}

try {
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'GET') {
        header('Allow: GET');
        fail(405, 'METHOD_NOT_ALLOWED');
    }

    $path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
    if (preg_match('~/(?:v1/)?health$~', $path)) {
        respond(200, ['status' => 'ok']);
    }

    $config = loadConfig();
    enforceRateLimit($config);

    if (preg_match('~/(?:v1/)?search$~', $path)) {
        $query = trim((string)($_GET['q'] ?? ''));
        $length = function_exists('mb_strlen') ? mb_strlen($query) : strlen($query);
        if ($length < 2 || $length > 120) {
            fail(400, 'INVALID_QUERY');
        }
        $limit = max(1, min((int)($_GET['limit'] ?? 20), 20));
        respond(200, ['foods' => search($query, $limit, $config)]);
    }

    if (preg_match('~/(?:v1/)?food/([0-9]{1,20})$~', $path, $matches)) {
        respond(200, foodDetails($matches[1], $config));
    }

    fail(404, 'NOT_FOUND');
} catch (Throwable $error) {
    // Do not reveal network details, credentials, upstream bodies, or paths.
    error_log(API_PREFIX . ': request failed (' . get_class($error) . ')');
    fail(503, 'SERVICE_UNAVAILABLE');
}
