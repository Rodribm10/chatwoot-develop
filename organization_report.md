# Organization Report: Unused Placeholders & Dependency Notes

## Changes Applied

| File | Change | Reason | Risk | Scope |
| :-- | :-- | :-- | :-- | :-- |
| `app/services/jasmine/semantic_search_service.rb` | Added `[FUTURE]` tags near placeholder variables | Clarify unused placeholders without removal | Low | Local |
| `app/services/wuzapi/provisioning_service.rb` | Added `[INTENTIONAL]` tag for unused argument | Preserve interface while documenting intent | Low | Local |
| `db/migrate/20260110193000_fix_status_suites_headers.rb` | Added `[INTENTIONAL]` tag for unused rescue variable | Clarify debug retention | Low | Local |
| `enterprise/app/services/captain/assistant/agent_runner_service.rb` | Added `[FUTURE]` tag for reserved keywords list | Clarify planned behavior | Low | Local |
| `enterprise/app/services/llm/base_ai_service.rb` | Added `[INTENTIONAL]` tag for reserved api_key | Clarify planned interface | Low | Local |
| `app/javascript/dashboard/routes/dashboard/jasmine/components/JasmineToolCard.vue` | Added `[INTENTIONAL]` tag for unused watcher param | Clarify placeholder | Low | Local |
| `app/javascript/dashboard/routes/dashboard/jasmine/components/JasmineToolsTab.vue` | Added `[INTENTIONAL]` tag for unused handler param | Clarify placeholder | Low | Local |
| `app/javascript/dashboard/routes/dashboard/jasmine/pages/JasmineInboxDashboard.vue` | Added `[INTENTIONAL]`/`[FUTURE]` tags | Clarify reserved store and edit flow | Low | Local |
| `app/javascript/dashboard/store/captain/assistant.js` | Added `[INTENTIONAL]` tag for factory arg | Document contract compatibility | Low | Local |
| `docs/dependency_notes.md` | Added dependency scan notes | Avoid JSON comments while documenting | Low | Docs |

## Skipped / Preserved

| File | Item | Reason | Risk | Scope |
| :-- | :-- | :-- | :-- | :-- |
| `app/services/jasmine/semantic_search_service.rb` | Remove unused locals | User requested no automatic removals | Low | Local |
| `app/javascript/dashboard/routes/dashboard/jasmine/components/JasmineToolCard.vue` | Remove unused watcher param | User requested no automatic removals | Low | Local |
| `app/javascript/dashboard/routes/dashboard/jasmine/components/JasmineToolsTab.vue` | Remove unused handler param | User requested no automatic removals | Low | Local |
| `app/javascript/dashboard/routes/dashboard/jasmine/pages/JasmineInboxDashboard.vue` | Remove unused store/saveEditDoc | User requested no automatic removals | Low | Local |
| `app/javascript/dashboard/store/captain/assistant.js` | Remove unused factory param | User requested no automatic removals | Low | Local |
| `package.json` | Comments | JSON does not support comments | Low | Config |

## Structural Suggestions (For Future)

- Consider adopting a dedicated unused-code scanner for Ruby (e.g., `debride`) and JS (e.g., `depcheck`) before removal.
