import { writeFileSync } from 'node:fs';

const endpoint = 'http://127.0.0.1:8089/mcp';
const initialized = await fetch(endpoint, {
  method: 'POST',
  headers: {'Content-Type': 'application/json', Accept: 'application/json, text/event-stream'},
  body: JSON.stringify({jsonrpc: '2.0', id: 1, method: 'initialize', params: {
    protocolVersion: '2024-11-05', capabilities: {},
    clientInfo: {name: 'PinchMarketResearch', version: '1.0'},
  }}),
});
if (!initialized.ok) throw new Error(`Initialization failed: ${initialized.status}`);
const session = initialized.headers.get('mcp-session-id');
const requests = [
  {name: 'get_app_keywords', arguments: {appName: 'Sodium Tracker: Pinch Daily'}},
  ...['us', 'ca', 'de'].map(store => ({name: 'search_app_store', arguments: {
    appId: '6800595930', keyword: 'sodium tracker', store, platform: 'iphone', limit: 10,
  }})),
];
const results = await Promise.all(requests.map(async (params, index) => {
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {'Content-Type': 'application/json', Accept: 'application/json, text/event-stream', 'Mcp-Session-Id': session},
    body: JSON.stringify({jsonrpc: '2.0', id: index + 2, method: 'tools/call', params}),
    signal: AbortSignal.timeout(60000),
  });
  const raw = await response.json();
  return {queriedAt: new Date().toISOString(), params, status: response.status, raw};
}));
writeFileSync(new URL('./astro-two-country-evidence-2026-09-09.json', import.meta.url), JSON.stringify({endpoint, results}, null, 2));
for (const item of results) {
  console.log(JSON.stringify({params: item.params, response: item.raw}));
}
