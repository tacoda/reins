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

Reins is a **Cockburn-strict hexagon** wearing a Rails-shaped surface. See `.claude/rules/hexagon.md` for the architectural rules — the principles below sit on top of that structure.

- **Dependencies point inward.** Adapters depend on ports; ports stand alone; the core depends on nothing infrastructural. The composition root (`Reins::Application`) is the only place concrete adapters get wired into the core. New framework code does not bypass this.
- **Cross a port with a value.** Anything passing through a driven port is a Ruby value object — a `Query`, `Template::Source`, `Blueprint::File`, `Request`, `Response`. Not a Rack env, not a `SQLite3::Statement`. The adapter does the translation on each side. This is the rule that keeps the core pure.
- **Deep modules over wide.** Prefer one well-named class with rich behavior over several thin wrappers. Ports themselves are deliberately narrow (a `CONTRACT` of a handful of methods) precisely so the surface stays small as implementations grow.
- **Rails-shaped public surface.** App authors write `class FooController < Reins::Controller`, `class User < Reins::Model::Base`, `route { resources :users }`. They should rarely need to know the hexagon is there. When they do — to plug in their own port/adapter — the CLI generators make it a 30-second affair.
- **No global mutable state.** `Reins.config`, `Reins.logger`, `Reins.application` are accessed through a controlled singleton wired at boot. The core never reaches for a global; every dependency is injected at the composition root.
- **Views are dumb.** `Reins::View` evaluates a template against a set of instance variables. Logic belongs in controllers or helpers, not in the view class. (The template engine lives behind `Ports::Driven::TemplateEngine`; template loading behind `Ports::Driven::TemplateStore`.)
