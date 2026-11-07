# A-Mail API contract (client side)

Proposed base URL: `https://api.adverune.store` (configurable, not yet live). All routes are under `/v1`.

**Envelope**
```json
{ "success": true, "data": {}, "error": null, "meta": { "page": 1, "per_page": 25, "has_more": false } }
{ "success": false, "data": null, "error": { "code": "validation", "message": "…", "fields": { "username": "taken" } } }
```
**Auth**: `Authorization: Bearer <access_token>`. On `401` the client calls `POST /v1/auth/refresh-token` with the refresh token once, rotates both tokens, and retries; if refresh fails the session is cleared.

Endpoint names mirror the planned PHP structure (see `lib/core/constants/api_endpoints.dart`): `auth/*`, `users/*`, `emails/*`, `folders/*`, `labels/*`, `attachments/*`, `contacts/*`, `notifications/*`, `devices/*`, `storage/*`.
