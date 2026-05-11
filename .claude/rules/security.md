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

- **SQL is adapter-only.** All SQL string construction lives inside `lib/reins/adapters/driven/sqlite/**`. The core model layer (`Reins::Model::Base`, `Reins::Model::Relation`) builds parameterized `Query` values and hands them to the `Repository` port. New persistence code that needs SQL belongs in a Sqlite adapter, parameterized end-to-end — the core never sees a SQL string.
- **HTML escaping.** `Reins::View#h` is the canonical escape helper, and ERB `<%= %>` auto-escapes by default. `<%== %>` is the raw-output opt-in. Treat any direct `String#+` into a template as suspect.
- **Untrusted input.** Request params come from a `Reins::Core::Http::Request` value (the Rack adapter does the translation). Validate at the controller boundary via `Reins::Parameters#require` / `#permit`; never feed raw params into model attributes.
- **Error pages.** Static error pages (`public/{404,422,500}.html`) are read by the Rack driving adapter, not the core. The core returns a `Reins::Core::Http::Response` with a status code; the adapter chooses what body to serve. Do not leak backtraces to clients in production.
- **Autoloading.** The Zeitwerk autoloader (`Reins::Autoloader`) derives a constant name from a file path, not the other way around. Never feed an untrusted string into `Object.const_get` or any loader API.
- **Filesystem access from the core.** The core never touches the filesystem directly. All read/write goes through `Reins::Ports::Driven::FileSystem`. If you find yourself wanting to call `File.read` from a core file, you're holding it wrong — inject the FS port instead.
- **Subprocess execution.** The core never calls `Kernel#system` or backticks. Shell-outs (e.g. `reins test`) go through `Reins::Ports::Driven::ProcessRunner`. Pass argv arrays — never a single shell-interpolated string.
- **Secrets.** No secrets in source. `Reins::Ports::Driven::EnvReader` is the only path to process environment; the core reads through it in the config layer and never directly.
