---
description: Commit and pull request rules for Reins
---

# Commits & Pull Requests

## Conventional Commits

Format: `<type>(<scope>): <subject>`

Common types:
- `feat` — new feature
- `fix` — bug fix
- `refactor` — behavior-preserving structural change
- `test` — adding or improving tests
- `docs` — documentation only
- `chore` — tooling, dependencies, non-code changes

## Rules

- One logical change per commit. Separate **structural** (refactor) and **behavioral** (feat/fix) changes into different commits.
- The codebase stays releasable on `main` at all times. Use feature flags to decouple deploy from release.
- Pre-commit checks must pass before commit. CI is a backstop, not a substitute.
- Do **not** add co-authors to commit messages.
- Do **not** mention the AI agent in commit messages or PR descriptions.

## Pull Requests

- Title is short (under 70 characters); details go in the body.
- Body explains the **why**, not the what.
- Include a test plan when the change touches user-facing behavior.

## Project-Specific Notes

- **Milestone-tagged commits.** While we're working through M0–M9, prefix the subject scope with the milestone where useful: `feat(view): auto-escape ERB output (M3)`. Drop once the milestone closes.
- **Tidying separate from features.** Pure cleanup (the M0 typo fixes, dropping FileModel) ships in `refactor:` or `chore:` commits with no behavior change. Do not bundle a tidying with a feature commit.
- **Specs alongside the change.** `feat:` and `fix:` commits include their RSpec specs. A standalone `test:` commit is for filling gaps in coverage of existing behavior, not for staging tests ahead of an unmerged change.
- **Public API additions.** A new public method or DSL keyword is a `feat:`. Note the version bump intent in the body so the next release bump is obvious.
