Run pre-commit checks based on what changed on the current branch.

## Steps

1. Detect what changed relative to `main`:
   ```
   git diff --name-only origin/main...HEAD
   ```

2. Run checks based on scope:

   **Always:**
   - `bundle exec rubocop`

   **When code changed:**
   - `bundle exec rspec`

3. Report each check: passed or failed. If any failed, show the relevant error output. Do NOT proceed to commit — report results only.

## Rules

- Capture output through `tee` into `.test-output/` so failures can be inspected without re-running.
- Fix lint errors with auto-fix when available; re-run lint before reporting.
- Never run multiple test processes in parallel against the same database.
