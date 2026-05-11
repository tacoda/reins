# Reins

A Rack-based Ruby web framework with the surface of Rails — built around a **Cockburn-strict hexagonal architecture** internally.

Routing, controllers, views, an ORM, migrations, generators, middleware, environments, autoloading, an RSpec test framework — and every piece of infrastructure (Rack, SQLite, Erubis, Puma, Thor, the filesystem, the clock) sits behind a swappable adapter. App authors get a Rails-shaped surface; framework contributors and advanced app authors get a clean port/adapter seam they can extend from the CLI.

## Install

The gem is published as `reins-web` (the name `reins` was already taken on RubyGems).

```ruby
# Gemfile
gem "reins-web"
```

```sh
bundle install
```

Reins requires **Ruby 3.3+**.

## A new app in 30 seconds

```sh
reins new blog
cd blog
bin/setup
reins generate scaffold Post title:string body:text
reins db:migrate
reins server
```

Open `http://localhost:8000/posts` and you have working CRUD.

For a slim app with every adapter slot left as an explicit placeholder — useful when you want to wire your own adapters from scratch:

```sh
reins new blog --slim
```

The full walkthrough — including models, validations, associations, and the architecture — lives in [GUIDE.md](GUIDE.md).

## Architecture

```
              +-------------------+
   driving    |    application    |   driven
  adapters →  |       core        | →  adapters
              +-------------------+
```

The core is pure Ruby — no Rack, no SQLite, no Puma, no filesystem access. Driving adapters (Rack, Thor) translate the outside world into core requests; driven adapters (SQLite, Filesystem, Erubis, Puma, …) implement the interfaces the core depends on. The composition root (`Reins::Application`) wires the graph; a named **profile** (`:standard`, `:slim`, `:test`) picks default adapters.

See [GUIDE.md](GUIDE.md#architecture) for the contributor view.

## CLI

```
reins new <name> [--slim]                  # scaffold a runnable project
reins server                               # boot Puma on port 8000
reins routes                               # print the route table
reins console                              # IRB with the app loaded

reins generate controller Posts index show
reins generate model Post title:string body:text
reins generate scaffold Post title:string body:text
reins generate migration AddPublishedAtToPosts published_at:datetime

reins generate port NAME [--driving | --driven]   # new port module
reins generate adapter NAME --port=PORT           # new adapter for a port
reins generate port --PRESET                      # rack | sqlite | thor | puma | …
reins generate port --list                        # show every preset
reins generate test PORT_NAME                     # spy + use-case spec for a port
reins generate use_case NAME [dep ...]            # application service object

reins generate config [--slim]             # write the default config block
reins db:create / db:drop / db:migrate / db:rollback / db:schema:dump
reins test                                 # runs `bundle exec rspec`
```

## Development on Reins itself

```sh
bundle install
bundle exec rspec        # run the test suite
bundle exec rubocop      # lint
bundle exec rake build   # build the gem
```

The agent harness for this repository (CLAUDE.md, `.claude/`) was scaffolded with [sellier](https://github.com/tacoda/sellier).

## Documentation

- [GUIDE.md](GUIDE.md) — Getting Started: build a blog from scratch + architecture deep dive
- [CHANGELOG.md](CHANGELOG.md) — release history

## Resources

- [Rack SPEC](https://github.com/rack/rack/blob/main/SPEC.rdoc)
- [Hexagonal Architecture, Alistair Cockburn](https://alistair.cockburn.us/hexagonal-architecture/)

## License

MIT — see [LICENSE](LICENSE).
