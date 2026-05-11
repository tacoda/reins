## Path Scope

This rule auto-loads when touching:
- `lib/reins/core/**`
- `lib/reins/ports/**`
- `lib/reins/adapters/**`
- `spec/reins/core/**`, `spec/reins/adapters/**`, `spec/reins/ports/**`

---

# Hexagonal Architecture

Reins is a **Cockburn-strict hexagon**: a pure application core, explicit ports, swappable adapters.

```
            +-------------------+
  driving   |    application    |   driven
 adapters → |       core        | → adapters
            +-------------------+
```

The user-facing API (`Reins::Controller`, `Reins::Model::Base`, `route { ... }`) stays Rails-shaped. The hexagon is **internal structure** — app authors don't see it unless they want to plug in their own adapters.

## Layout

```
lib/reins/
├── core/                # pure — no rack/sqlite/erubis/puma/thor/fileutils/zeitwerk
├── ports/
│   ├── driving/         # HttpApp, CommandInvoker
│   └── driven/          # Repository, SchemaInspector, TemplateStore, …
└── adapters/
    ├── driving/         # rack/, thor/
    └── driven/          # sqlite/, memory/, filesystem/, erubis/, puma/, system/
```

## The Three Hard Rules

1. **The core is pure.** No file under `lib/reins/core/**` may `require "rack" | "sqlite3" | "erubis" | "puma" | "thor" | "fileutils" | "zeitwerk"`, or reference those top-level constants. The `core_boundary_spec` enforces this — never weaken it.
2. **Dependencies point inward.** `core/` never reaches into `adapters/`. `ports/` never reaches into `adapters/` or `core/`. `adapters/` may depend on `ports/` and `core/`. The composition root (`Reins::Application`) is the only place that wires concrete adapters into the core.
3. **Cross a port with a value.** Anything passing through a port is a Ruby value — a `Request`, `Response`, `Query`, `Template::Source`, `Blueprint::File`. Not a Rack env. Not a `SQLite3::Statement`. The adapter does the translation on each side.

## Adding a new port

A port is a Ruby module under `lib/reins/ports/{driving,driven}/<name>.rb` exposing one constant — a frozen `CONTRACT = { method_name: arity, … }` hash. The contract is the type signature. Adapter generators read it to scaffold method stubs and contract specs.

Prefer the CLI: `reins generate port NAME [--driving|--driven]`. The default is `--driven`.

## Adding a new adapter

An adapter implements a port. It lives under `lib/reins/adapters/{driving,driven}/<tech>/<name>.rb`, `include`s the port module, and defines every method named in the contract. Contract specs (`spec/reins/adapters/.../*_spec.rb`) assert this:

```ruby
it "responds to every method on the FOO port contract" do
  Reins::Ports::Driven::Foo::CONTRACT.each_key do |name|
    expect(adapter).to respond_to(name), "missing #{name}"
  end
end
```

Prefer the CLI: `reins generate adapter NAME --port=PORT`.

## Presets

Common port+adapter pairs ship as named presets. Use them — don't reinvent:

| Flag | Generates |
|---|---|
| `--rack` | `Ports::Driving::HttpApp` + `Adapters::Driving::Rack::App` |
| `--thor` | `Ports::Driving::CommandInvoker` + `Adapters::Driving::Thor::Cli` |
| `--sqlite` | `Ports::Driven::Repository` (+ `SchemaInspector`, `SchemaMigrator`) + `Adapters::Driven::Sqlite::*` |
| `--memory` | In-memory `Repository`, `FileSystem`, `SchemaInspector` (test adapters) |
| `--puma` | `Ports::Driven::Server` + `Adapters::Driven::Puma::Server` |
| `--filesystem` | `Ports::Driven::FileSystem` + `Adapters::Driven::Filesystem::Real` |
| `--erubis` | `Ports::Driven::TemplateEngine` + `Adapters::Driven::Erubis::TemplateEngine` |
| `--clock` | `Ports::Driven::Clock` + `Adapters::Driven::System::Clock` (+ `FixedClock`) |
| `--env` | `Ports::Driven::EnvReader` + `Adapters::Driven::System::EnvReader` |

`reins generate port --list` prints the registry.

## Profiles

`Reins::Application.new` selects a **profile** — a named bundle of adapter defaults. `:standard` is the default (Rack + SQLite + Thor + Puma + Erubis + Filesystem + System). `:slim` wires nothing, leaving every adapter slot explicitly nil so the developer sees what's configurable.

App authors override at the composition root:

```ruby
class Blog::Application < Reins::Application
  profile :standard

  adapters do |a|
    a.clock = MyFixedClock.new   # for testing, or any custom adapter
  end
end
```

## Tests

- Unit-test the core against in-memory adapters (`Memory::Repository`, `Memory::FileSystem`). The core never sees disk or SQLite in a unit spec.
- Unit-test each adapter against its port: every method named in `CONTRACT` must be defined.
- Integration-test through the driving adapter (`Adapters::Driving::Rack::App`) for HTTP behavior; through `Filesystem::Real` for generators on disk.

## What NOT to do

- Don't add an adapter that bypasses its port. If `Sqlite::Repository` needs a method the `Repository` port doesn't expose, add it to the contract first, audit existing adapters, then implement.
- Don't smuggle infrastructure into the core via a "convenience" require. The boundary spec will catch it; weakening the boundary spec is a code-review red flag.
- Don't let `Reins::Controller` or `Reins::Model::Base` reach into a concrete adapter (`Reins::Database.connection`, `SQLite3::*`). They depend on the wired port — that's it.
- Don't make adapter generators "smart". They scaffold the contract methods raising `NotImplementedError` and let the implementer fill in the body. Cleverness here makes future ports harder to add.
