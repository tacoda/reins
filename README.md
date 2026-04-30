# Reins

A Rack-based Ruby web framework. Reins is a learning exercise: rebuild Rails from scratch, one feature at a time.

> **Status:** pre-1.0. The proof-of-concept request lifecycle works. Rails-core features (resourceful routing, validations, associations, migrations, generators, middleware) are landing milestone by milestone toward 1.0. See [Roadmap](#roadmap).

## Install

The gem is published as `reins-web` (the name `reins` was already taken on RubyGems).

```ruby
# Gemfile
gem "reins-web"
```

```sh
bundle install
```

## A minimal app

```ruby
# config.ru
require "reins"

class GreetController < Reins::Controller
  def index
    response("Hello, world!")
  end
end

app = Reins::Application.new
app.route do
  match "", "greet#index"
end
run app
```

```sh
bundle exec reins server   # boots Puma on http://localhost:8000
```

## CLI

```
reins new <name>     # scaffold a project (work-in-progress; full generators land in M6)
reins server         # run the app under Puma on port 8000
```

## Development

```sh
bundle install
bundle exec rspec        # run the test suite
bundle exec rubocop      # lint
bundle exec rake build   # build the gem
```

The agent harness for this repository (CLAUDE.md, `.claude/`) is scaffolded with [sellier](https://github.com/tacoda/sellier).

## Roadmap

| Milestone | Theme |
|---|---|
| M0 | Tidying — RSpec, harness, bug fixes |
| M1 | Routing v2 — HTTP verbs, resources, named routes |
| M2 | Controllers v2 — filters, redirects, strong params, JSON |
| M3 | Views v2 — layouts, partials, helpers, auto-escape |
| M4 | Model v2 — validations, associations, query interface |
| M5 | Migrations and database tooling |
| M6 | Generators and application skeleton |
| M7 | Middleware, environments, Zeitwerk-style autoloading |
| M8 | Testing framework for Reins apps |
| M9 | 1.0 release |

## Resources

- [Rack SPEC](https://github.com/rack/rack/blob/main/SPEC.rdoc)
- [Rails on Rack](https://guides.rubyonrails.org/rails_on_rack.html)

## License

MIT.
