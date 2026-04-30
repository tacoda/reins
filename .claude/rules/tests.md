---
description: Test patterns and TDD workflow for Reins
paths:
  - "spec/**/*_spec.rb"
---

# Tests

Tests are the primary quality gate. Every change must pass `bundle exec rubocop` and `bundle exec rspec` before commit.

## Philosophy

Tests verify **behavior, not implementation**. Feed input, check output and observable side effects.

- **Classical/Chicago-school testing.** State-based verification is the default.
- **Fakes and stubs over mocks.** Use real implementations for internal collaborators.
- **Mocks only at system boundaries.** External services (HTTP APIs, payment gateways, message queues) get mocked. The database is NOT a boundary — tests hit it directly via a transactional fixture.
- **Behavior verification is a last resort.** Only assert "X was called" when there is no observable state to check.
- **Never mock internal collaborators.** Mocking internals couples tests to implementation and hides real bugs.

## Test Pyramid

| Tier | Scope | Speed | When to add |
|---|---|---|---|
| Unit | A single class/function | Fast | All new code |
| Integration | Multiple components together | Medium | Cross-component seams |
| Acceptance | Top-level user-facing | Medium | New features (TDD entry point) |
| E2E | Full stack through the runtime | Slow | Major happy paths |

## TDD Workflow

1. **Red** — Write failing tests first. Present test descriptions for review.
2. **Green** — Implement the smallest change to make tests pass.
3. **Refactor** — Clean up only after green tests.
4. **Commit** — Follow the change approval flow in CLAUDE.md.

## Test Naming

Use descriptive names that read as specifications:
- `{actor}_{can|cannot}_{action}_{condition}`
- `{action}_{produces}_{outcome}`

## Arrange-Act-Assert

Structure every test with clear separation. One logical assertion per test.

## What NOT to Do

- Do not test implementation details (private methods, internal state)
- Do not mock internal collaborators
- Do not write tests that depend on execution order
- Do not assert on exact error message strings — assert on status codes and structure
- Do not use `sleep()` — use deterministic waits

## Naming Test Fixtures

Do **not** prefix test fixture classes (controllers, models) with milestone tags, ticket IDs, or topic codes — `M2RenderController`, `JIRA1234User`, etc. Names should describe the role of the fixture, not when it was added.

**Why:** Prefixes leak ephemeral context into permanent code. `RenderingController` reads as "the controller that exercises rendering"; `M2RenderController` reads as "the M2 milestone left this here." The milestone is in `git log`, not the class name.

**How to apply:** Use a semantic name. If two specs need the same name, namespace with a module (`module RenderingSpec; class HomeController; end; end`) instead of disambiguating with a prefix.

## Project-Specific Test Setup

- RSpec 3.13 with `spec/spec_helper.rb`; `--require spec_helper` is set in `.rspec`.
- `Rack::Test` is the HTTP-level test driver — `include Rack::Test::Methods` in any spec that exercises a `Reins::Application`.
- Run a single file: `bundle exec rspec spec/reins/view_spec.rb`. Run all: `bundle exec rspec`.
- The framework's own SQLite ORM specs should run against an isolated DB file under `Dir.mktmpdir` and call `Reins::Database.reset!` between examples — never share state with `test.db` at the repo root.
- App-author-facing test helpers (`Reins::TestCase`, controller test case, fixture loading) land in M8 — until then, app authors write specs by `include Rack::Test::Methods` directly.
