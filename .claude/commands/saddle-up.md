Customize the freshly-scaffolded harness for this project by replacing every `[PLACEHOLDER]` token with a real value.

## Steps

1. **Inventory placeholders.** Recursively grep the harness for tokens of the form `[A-Z][A-Z0-9_]+` enclosed in square brackets:
   ```
   git grep -nE '\[[A-Z][A-Z0-9_]+\]' -- CLAUDE.md .claude/
   ```
   Build a deduplicated list. The exact set varies, but expect at least:
   `PROJECT_NAME`, `PROJECT_DESCRIPTION`, `TECH_STACK`, `MAIN_BRANCH`, `TASK_TRACKER`, `CI_PROVIDER`, `LINT_COMMAND`, `TEST_COMMAND`, `BUILD_COMMAND`, `FRONTEND_TEST_COMMAND`, `BUILD_TOOL`, `TEST_PATHS`, `DEPENDENCY_AUDIT_COMMAND`, `PROJECT_LAYOUT`, `PROJECT_PATTERNS`, `TEST_SETUP_NOTES`, `SECURITY_NOTES`, `COMMIT_NOTES`.

2. **Inspect the project to derive values.** Read whichever of these exist and use them as evidence:
   - `package.json`, `pyproject.toml`, `composer.json`, `Cargo.toml`, `go.mod`, `Gemfile` — language and dependency stack
   - `Makefile`, `justfile`, `package.json#scripts` — actual lint/test/build commands
   - `README.md` — project description, getting-started commands
   - `.github/workflows/`, `.gitlab-ci.yml`, `.circleci/` — CI provider and pipeline shape
   - `git symbolic-ref refs/remotes/origin/HEAD` — main branch name
   - `tests/`, `test/`, `spec/`, `__tests__/` — test paths
   - The directory tree (one level) — project layout

3. **Propose a value for each placeholder.** Present the full list as a markdown table:

   | Placeholder | Proposed value | Source / reason |
   |---|---|---|

   Keep proposed values short and concrete. For descriptive placeholders (`PROJECT_DESCRIPTION`, `PROJECT_LAYOUT`, `PROJECT_PATTERNS`), draft a short paragraph or bullet list, not a single line.

4. **Ask for feedback.** The user may correct any value, ask for more research, or say a placeholder should be removed entirely.

5. **Once approved, replace each token across the harness.** Use exact string replacement — every occurrence of `[NAME]` becomes the chosen value. Replace inside fenced code blocks too. Do not invent placeholders that the user did not approve.

6. **Verify.** Re-run the grep from step 1. The only matches that should remain are placeholders the user explicitly asked to keep.

7. **Stage the changes.** Show the diff and ask if the user wants to commit.

## Rules

- Do not invent project facts. If evidence is missing, say "unknown" in the proposed value column and ask the user.
- Do not delete sections of the harness without asking.
- Do not add new rule files, agents, commands, or skills as part of this command — that is a separate decision.
