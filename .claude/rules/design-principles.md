---
description: Core design principles governing all code in Reins
---

# Design Principles

## Core Philosophy
- **Manage complexity ruthlessly.** Every decision should reduce cognitive load. Optimize for the reader.
- **Make change easy, then make the easy change.** Localize modifications, minimize risk.
- **Empiricism over dogma.** Validate through working software and fast feedback.
- **Pull complexity downward.** Simple interfaces over simple implementations (deep modules).
- **When in doubt, choose the boring solution.**

## Construction
- Names reveal intent; length proportional to scope; use domain vocabulary
- Functions: small, **one level of abstraction**, few arguments (<=3), no hidden side effects
- Command-Query Separation: do something OR answer something, not both
- **Program to interfaces, not implementations.** Depend on abstractions; create implementations behind interfaces rather than branching on type.
- **SOLID** — Single Responsibility, Open/Closed, Liskov, Interface Segregation, Dependency Inversion
- **DRY** — every piece of knowledge has one authoritative representation
- **Rule of Three** — tolerate duplication twice; extract on the third occurrence
- **YAGNI** — don't build for hypothetical future requirements
- **KISS** — the simplest solution that works is the best solution
- Comments explain **why**, not what. Delete commented-out code.

## Tell, Don't Ask
Tell objects what to do instead of querying their state and deciding for them. Encapsulate state checks as named methods on the object that owns the state. The caller should never reach through an object's internals to make decisions.

## Error Handling
- Fail fast: detect and report at the earliest point
- Provide context: what happened, where, and what to do
- Don't return null; don't pass null — use null objects, optionals, or throw
- Validate inputs at boundaries; assert invariants internally

## Anti-Patterns
- Premature optimization and premature abstraction
- Speculative generality ("we might need this someday")
- Big bang rewrites — prefer incremental improvement
- Clever code that's hard to understand
- Shallow modules with complex interfaces
- Anemic domain models (data without behavior)
- Forced DRY on incidental duplication

## Project-Specific Patterns

Reins is a Rack application that calls into user code. The framework's own conventions:

- **Rack-app composition.** Everything ultimately resolves to a callable that returns `[status, headers, body]`. `Reins::Application#call` delegates to `RouteObject#check_url`, which returns either a `Proc` or a `Controller.action(...)` proc. Add new request-handling capabilities by composing into this chain — do not bypass it.
- **Routing DSL.** Routes are defined inside `route { match "...", "controller#action" }`. M1 adds verb-scoped DSL (`get`/`post`/...) and resource expansion. Keep `RouteObject` as the single source of truth for URL → callable resolution.
- **Controller actions are Rack apps.** `Controller.action(act, rp)` returns a proc usable wherever a Rack app is expected. The `dispatch` method is the only place that decides between an explicit `response(...)` and an action's return value — preserve that single decision point when extending controller behavior.
- **Views are dumb.** `Reins::View` exists to evaluate a template against a set of instance variables. Logic belongs in controllers or helpers, not in the view class.
- **Autoloading.** `lib/reins/dependencies.rb` overrides `Object.const_missing` to lazy-require by underscored name. M7 replaces this with a Zeitwerk-style loader; until then, every file under `lib/reins/` should be requirable on its own and define exactly one top-level constant.
- **No global mutable state in lib/reins.** The current `DB = SQLite3::Database.new "test.db"` global is debt — M0 extracts it into `Reins::Database`. New framework code must be configurable, not globally bound.
- **Deep modules over wide.** Prefer one well-named class with rich behavior over several thin wrappers. The framework gets used through a small surface; keep that surface small even when the implementation grows.
