---
description: OWASP Top 10 mapped to Reins
---

# Security

Security review is required when a change touches: authentication, authorization, queries (SQL or otherwise), file I/O, external API calls, or response shapes.

## Access Control
- Every new route is behind the right middleware
- Authorization decisions go through policies, not inline checks
- Default-deny: opt in to access, never opt out

## Injection
- No string concatenation into queries — use parameterized queries / query builders
- No string concatenation into shell commands — use argv arrays
- No string concatenation into file paths — validate against an allowlist of base directories
- HTML output escapes by default; opt in to raw output explicitly

## Data Exposure
- Response shapes (resources, serializers, DTOs) only expose fields that the caller is authorized to see
- Sensitive fields (passwords, tokens, PII) never leave the database in logs, errors, or responses
- Error messages do not leak internal state to unauthorized callers

## Configuration
- Secrets come from environment variables, never from source
- Features default to **off**; opt in via configuration
- `env()` is read in config layers only — application code reads from config

## Dependencies
- Pin dependency versions
- Run dependency audit (`bundle exec bundler-audit check --update`) regularly
- Update on a cadence; security patches promptly

## Project-Specific Security Notes

Reins is a web framework — its security posture is what its users inherit. Treat every public method as a documented attack surface.

- **SQL injection (current debt).** `Reins::Model::SQLite` interpolates values into SQL via `to_sql` in `lib/reins/sqlite_model.rb`. M4 replaces this with parameterized statements end-to-end. Until then, do not add new code paths that interpolate user input into SQL — extend the parameterized path instead.
- **HTML escaping.** `Reins::View#h` is the canonical escape helper; M3 will make ERB `<%= %>` auto-escape and add an explicit raw-output opt-in. Treat any direct `String#+` into a template as suspect.
- **Untrusted input.** Request params come from `Rack::Request#params`. Validate at the controller boundary; never feed raw `params` into model attributes (M4 strong-params resolves this for app authors).
- **Error pages.** The catch-all in `Reins::Application#call` reads `public/500.html` as a static file. Do not leak backtraces to clients in production — dev-only exception page lands in M7.
- **Autoloading.** `const_missing` in `lib/reins/dependencies.rb` derives a file path from a constant name. Never feed an untrusted string into `Object.const_get` or the loader (M7 replaces this with a Zeitwerk-style scoped loader).
- **Secrets.** No secrets in source. The framework itself takes none today; when M5 introduces `config/database.yml` and M7 introduces environments, ENV-only.
