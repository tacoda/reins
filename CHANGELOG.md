# Changelog

## 2.0.0 — 2026-05-11

Reins 2.0 is an architectural release: every Rails-shaped feature from 1.x is preserved, but the framework is reorganized internally as a **Cockburn-strict hexagon** — pure core, explicit ports, swappable adapters. App authors who only use the public API (`Reins::Controller`, `Reins::Model::Base`, `route { resources :foo }`, the CLI) see no breaking changes. App authors and contributors who reach into the framework will find a new, smaller, more testable internal surface.

### Architecture

- **Pure core** under `lib/reins/core/**`. Forbidden from requiring or referencing `rack`, `sqlite3`, `erubis`, `puma`, `thor`, `fileutils`, or `zeitwerk`. Enforced by `spec/reins/core_boundary_spec.rb`.
- **Driving ports** under `lib/reins/ports/driving/**`: `HttpApp`, `CommandInvoker`.
- **Driven ports** under `lib/reins/ports/driven/**`: `Repository`, `SchemaInspector`, `SchemaMigrator`, `TemplateStore`, `TemplateEngine`, `FileSystem`, `ProcessRunner`, `Server`, `EnvReader`, `Clock`, `Autoloader`. Each port declares its direction and method signatures through a small DSL (`extend Reins::Port; direction :driven; contract …`) and is registered in `Reins::Port.all`.
- **Adapters** under `lib/reins/adapters/{driving,driven}/**`: `Rack` (driving), `Thor` (driving), `Sqlite`, `Memory`, `Filesystem`, `Erubis`, `Puma`, `System`, `Zeitwerk`, `Noop`. Each adapter `include`s its port module and implements every method on the contract.

### CLI

The CLI itself is now structured as a driving port. `Reins::Core::Cli::Commands::*` are pure command classes; `Reins::Core::Cli::Invoker` implements the `CommandInvoker` port; `Reins::Adapters::Driving::Thor::Cli` is the Thor-flavored driving adapter that parses argv. `Reins::Cli` is an alias kept for backward compatibility.

New CLI commands and flags:

- `reins generate port NAME [--driving | --driven]` — scaffold a new port. Defaults to `--driven`.
- `reins generate adapter NAME --port=PORT [--driving]` — scaffold an adapter implementing a port. Reads the port's `CONTRACT` to seed method stubs and a contract spec.
- `reins generate port --PRESET` — scaffold a known port+adapter pair: `--rack`, `--thor`, `--sqlite`, `--memory`, `--puma`, `--filesystem`, `--erubis`, `--clock`, `--env`.
- `reins generate port --list` — print the preset registry.
- `reins new myapp --slim` — scaffold an app where every adapter slot is left for the developer to wire. The generated Gemfile pins only `reins-web` and `rackup`; the default `reins new` Gemfile is derived from the `:standard` profile and pins `puma`, `sqlite3`, `erubis`, `zeitwerk`, and `rackup` automatically.

### Composition root

- `Reins::Application.new(profile:, adapters:)` selects a named profile and applies optional per-adapter overrides. Default profile is `:standard`; `:test` uses in-memory adapters; `:slim` wires nothing. `Reins::Profile.fetch(name)` returns the profile's gem list and adapter map.
- `Reins::Configurator` translates a Hash of declarations (instances / Classes / Procs) into a wired adapter map. `Configurator#load(path)` reads a Ruby config file whose last expression is a Hash and applies it — the basis for an app-author-friendly `config/adapters.rb`.
- `Reins::Application#adapters` exposes the wired graph at runtime.
- `Reins::Database.path=` resets the cached SQLite connection when the path changes, so swapping environments mid-process picks up the new database file cleanly.

### Behavior preserved

Everything that worked in 1.x continues to work in 2.0. No public API has been removed; the user-facing API (`Reins::Controller`, `Reins::Model::Base`, the routing DSL, the CLI commands, the test helpers) is identical. The reorganization is internal.

### Migration from 1.x

If you only use the public API: no changes required.

If you reach into the framework internals (e.g. `Reins::Database.connection` for raw queries, or custom middleware injection at the application level): the high-level API still works, but you can now take the relevant port as a constructor argument. See the architecture section of [GUIDE.md](GUIDE.md#architecture) for the contributor view and the end-to-end PaymentGateway example.

---

## 1.0.0 — 2026-04-30

First stable release. Reins is a Rack-based Ruby web framework with the surface
of Rails: routing, controllers, views, ORM, migrations, generators, middleware,
environments, autoloading, and a small RSpec test framework.

### M0 — Tidying
- Replaced the proof-of-concept Minitest test with RSpec (`bundle exec rspec`).
- Scaffolded an agent harness (`CLAUDE.md`, `.claude/`) for AI-assisted work.
- Fixed the `Erubis::Eruby` typo, replaced `URI.escape` with `CGI.escapeHTML`,
  fixed the `reins new` scaffold path bug.
- Extracted the global SQLite connection into `Reins::Database`.
- Dropped the FileModel proof-of-concept.
- Added RuboCop and a GitHub Actions CI workflow.

### M1 — Routing v2
- Rails-shaped routing DSL: `get`/`post`/`put`/`patch`/`delete`, `root`,
  `resources`, `match` (any verb), path `constraints:`, and named-route helpers
  via `as:`.
- `Reins::Application` emits real 404 / 405 (with `Allow` header) responses.
- New `reins routes` CLI command prints the route table.
- URL helpers (`posts_path`, `post_path(id)`, `*_url`) mixed into both
  controllers and views.

### M2 — Controllers v2
- `render` returns a real response with one-shot semantics — supports `:show`,
  `plain:`, `html:`, `json:`, `template:`, `status:` (numeric or symbolic), and
  `locals:`. Auto-renders the action's view when no explicit response is set.
- `redirect_to` and `head` complete the response surface.
- Action filters: `before_action` / `after_action` / `around_action` with
  `:only` / `:except`, inherited via the ancestor chain.
- `respond_to` for HTML and JSON.
- `Reins::Parameters` (strong parameters: `require` / `permit`).
- `session` and `flash` over `Rack::Session`.
- New error classes: `DoubleResponse`, `MissingTemplate`, `ParameterMissing`,
  `SessionMiddlewareMissing`.

### M3 — Views v2
- ERB auto-escape via `Erubis::EscapedEruby` — `<%= %>` escapes,
  `<%== %>` is raw.
- Layouts: `app/views/layouts/application.html.erb` is the implicit default.
  Class-level `layout "name"` and per-call `layout: false` overrides.
- Partials: `<%= render "shared/header" %>`, locals, collection rendering.
- `content_for` / `yield(:section)`.
- View helpers: `link_to`, `tag`, `image_tag`, `url_for`,
  `stylesheet_link_tag`, `javascript_include_tag`.
- Form helpers: `form_with`, `text_field`, `text_area`, `submit`,
  `hidden_field`, `label`.
- All helpers are mixed into both `Reins::View` and `Reins::Controller`.

### M4 — Model v2
- `Reins::Model::Base` with chainable lazy `Reins::Model::Relation`
  (`where`, `order`, `limit`, `offset`, `count`, `pluck`, `first`, `last`,
  `find`, `find_by`).
- Validations: `presence`, `length`, `format`, `uniqueness` plus a
  `Reins::Model::Errors` object.
- Lifecycle callbacks: `before_validation` through `after_destroy` plus
  `after_initialize`.
- Associations: `belongs_to`, `has_many`, `has_one` with `class_name:` and
  `foreign_key:` overrides.
- Auto-timestamps (`created_at`, `updated_at`) when the columns exist.
- `Reins::Model.transaction { ... }`.
- All SQL is fully parameterized — no string interpolation of values
  anywhere in the data path.
- New error classes: `Reins::Model::RecordNotFound`,
  `Reins::Model::RecordInvalid`.
- Replaced the proof-of-concept `Reins::Model::SQLite` class.

### M5 — Migrations & DB tooling
- `Reins::Migration` with the standard DSL: `create_table`, `add_column`,
  `add_index`, `references`, `timestamps`, `rename_column`, etc.
- `Reins::Migrator` applies / rolls back, tracks state in `schema_migrations`,
  inverts `change`-only migrations for the supported ops.
- `Reins::Schema.define` and `Reins::Schema.dump` — `db/schema.rb` round-trip.
- `Reins::DatabaseConfig` reads `config/database.yml` per `REINS_ENV`.
- New CLI commands: `reins generate migration`, `reins db:create` /
  `db:drop` / `db:migrate` / `db:rollback` / `db:schema:dump`.

### M6 — Generators & app skeleton
- `reins new myapp` produces a complete, runnable project tree
  (`config.ru`, `Gemfile`, `bin/{reins,setup,console}`, `config/`, `app/`,
  `db/`, `public/`, `spec/`, `tmp/`).
- `Reins.application` singleton accessor.
- Generators: `reins generate controller`, `reins generate model`,
  `reins generate scaffold` (model + migration + RESTful controller +
  views + form partial + appended `resources` route).
- `reins console` opens IRB with the app loaded.
- Naive pluralization shared with M1's `resources` and M4's `table_name`.

### M7 — Middleware, environments, autoloading
- `Reins.env` value object with `development?`/`test?`/`production?`
  predicates.
- `Reins.config` and `Reins.configure { |c| ... }` — `eager_load`,
  `reload_classes`, `log_level`, `log_path`, plus a `MiddlewareStack`.
- `Reins::MiddlewareStack` — `use`, `insert_before`, `insert_after`,
  `delete`, `each`. Default stack: `Rack::ContentLength`, `Rack::Head`.
- `Application#call` runs requests through the configured stack.
- `Reins.logger` writing to `log/<env>.log`.
- **Zeitwerk autoloader** — `Reins::Autoloader.setup(paths)`,
  `eager_load!`, `reload!`. Replaced the `const_missing` hack.
- `Reins::ReloadMiddleware` for dev-style reload-on-change.
- Generator now writes meaningful env files and `public/{404,422,500}.html`
  error pages.

### M8 — Testing framework
- `require "reins/spec"` — RSpec metadata-driven contexts:
  `type: :model` (transactional rollback per example),
  `type: :controller` / `type: :integration` (Rack::Test).
- Custom matchers: `have_http_status(:ok)`, `redirect_to(url)`.
- `Reins::Spec::Fixtures.load(model, yml)` — YAML fixture loader.
- `reins test` shells out to `bundle exec rspec`.
- Generators (`model`, `controller`, `scaffold`) write spec stubs.

### M9 — Release
- Version bumped to 1.0.0.
- This changelog.
- README polished for 1.0.
- LICENSE (MIT) added.
- gemspec `files` glob expanded to ship `README.md`, `GUIDE.md`,
  `CHANGELOG.md`, `LICENSE`, and `assets/`.
