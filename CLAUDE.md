# CLAUDE.md

Guidance for Claude Code when working in **Reins**.

## Project Overview

A Rack-based Ruby web framework with the surface of Rails — internally structured as a **Cockburn-strict hexagon** (pure core, explicit ports, swappable adapters). Reins 2.0 is the first release built around this architecture; 1.x shipped the Rails-shaped features (routing, controllers, views, ORM, migrations, generators, middleware, environments), 2.0 reorganizes them behind ports and adds CLI tooling for app authors to extend the hexagon with their own ports and adapters.

**Tech Stack:** Ruby (>= 3.3), Rack, Erubis, SQLite3, Thor, Puma, RSpec

**Main branch:** `main`
**Task tracker:** none
**CI:** GitHub Actions

## Layout

```
lib/reins/
├── core/                       # pure domain — no rack/sqlite/erubis/puma/thor/fileutils/zeitwerk
│   ├── generators/             # Blueprint, BlueprintWriter, PortGenerator,
│   │                           # AdapterGenerator, PortPresets
│   ├── http/                   # Request, Response value objects
│   ├── model/                  # Query value object (Relation/Persistence
│   │                           # live in lib/reins/model/ and route through
│   │                           # the Repository port)
│   └── cli/                    # Commands::*, Invoker
├── ports/
│   ├── driving/                # HttpApp, CommandInvoker
│   └── driven/                 # Repository, SchemaInspector, SchemaMigrator,
│                               # TemplateStore, TemplateEngine, FileSystem,
│                               # ProcessRunner, Server, EnvReader, Clock,
│                               # Autoloader
├── adapters/
│   ├── driving/
│   │   ├── rack/               # Rack::App + env↔Request, Response↔tuple translators
│   │   └── thor/               # Thor::Cli — thin shim into Core::Cli::Invoker
│   └── driven/
│       ├── sqlite/             # Repository, SchemaInspector, SchemaMigrator
│       ├── memory/             # In-memory test adapters for every port that has them
│       ├── filesystem/         # Real (disk-backed FileSystem), TemplateStore
│       ├── erubis/             # TemplateEngine
│       ├── puma/               # Server
│       ├── system/             # Clock, EnvReader, ProcessRunner
│       ├── zeitwerk/           # Autoloader
│       └── noop/               # Autoloader (test fake)
├── profile.rb                  # named bundles (gems + adapters): :standard, :slim, :test
├── configurator.rb             # translates Hash declarations into wired instances
└── reins.rb                    # composition root: Reins::Application wires the graph

spec/reins/                     # mirrors lib/ layout
assets/                         # default 404/422/500 pages shipped with generated apps
```

The user-facing API stays Rails-shaped — `Reins::Controller`, `Reins::Model::Base`, `route { resources :foo }`. Internals route through ports; app authors see them only when they want to add their own port/adapter pair via the CLI.

## The Harness

The harness is the system that lets an AI agent produce correct, high-quality code consistently. It has four parts plus the discipline that makes them work.

1. **Guidance** — `CLAUDE.md` (this file) and `.claude/rules/`. Path-scoped rules auto-load when touching matching files. These shape what the agent writes before it writes a single line.
2. **Guardrails** — automated checks (`bundle exec rubocop`, `bundle exec rspec`, `bundle exec rake build`). The core-purity boundary spec (`spec/reins/core_boundary_spec.rb`) and the ports-catalog spec (`spec/reins/ports_spec.rb`) are part of this layer — they're the executable form of the hexagon rule.
3. **Flywheel** — the feedback loop. When a reviewer flags a pattern, update the relevant rule file in `.claude/rules/`, reload it, then re-apply. Every review improves every future conversation.
4. **Executable Workflows** — `.claude/agents/` for isolated read-only analysis, `.claude/commands/` for single-step utilities, `.claude/skills/` for multi-phase workflows.

The harness is only as strong as the code it governs. Write new code to harness standards. Refactor existing code when you touch it. Delete dead code.

| Rule file | Scope |
|---|---|
| `.claude/rules/design-principles.md` | Always loaded — SOLID, KISS, YAGNI, DRY, hexagon-aware patterns |
| `.claude/rules/hexagon.md` | Loaded when touching `lib/reins/core/**`, `lib/reins/ports/**`, `lib/reins/adapters/**` |
| `.claude/rules/tests.md` | Loaded when editing tests — TDD workflow, patterns |
| `.claude/rules/security.md` | Loaded for auth, queries, file I/O, response shapes |
| `.claude/rules/commits.md` | Loaded before commit — conventional commits |

## Commands

```
bundle exec rubocop       # static checks
bundle exec rspec         # full test suite
bundle exec rake build    # build the gem
```

## Change Approval Flow

During implementation, auto-accept edits. When changes are ready to commit:

1. **Self-review** — spawn the self-review agent on the diff
2. **Show diff** — present changes and findings, ask for feedback
3. **Feedback given** — update the relevant rule file, reload it, re-apply
4. **Approved** — run `/pre-commit`
5. **Checks pass** — commit and push (conventional commits, no co-authors)

## TDD Workflow

1. **Red** — write failing tests first; present a list of test descriptions for review
2. **Green** — implement the smallest change to make tests pass
3. **Refactor** — clean up only after green; spawn the refactor-changes agent on the diff
4. **Commit** — follow the change approval flow

## Pre-Commit Verification

Run `/pre-commit` immediately before `git commit` — every time. Checks that ran earlier in a task do not count if any code has changed since.
