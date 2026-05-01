# Reins

A Rack-based Ruby web framework with the surface of Rails.

Routing, controllers, views, an ORM, migrations, generators, middleware, environments, autoloading, and a small RSpec test framework — built one milestone at a time as a learning exercise.

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

The full walkthrough — including models, validations, and associations — lives in [GUIDE.md](GUIDE.md).

## CLI

```
reins new <name>                           # scaffold a runnable project
reins server                               # boot Puma on port 8000
reins routes                               # print the route table
reins console                              # IRB with the app loaded
reins generate controller Posts index show
reins generate model Post title:string body:text
reins generate scaffold Post title:string body:text
reins generate migration AddPublishedAtToPosts published_at:datetime
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

- [GUIDE.md](GUIDE.md) — Getting Started: build a blog from scratch
- [CHANGELOG.md](CHANGELOG.md) — release history

## Resources

- [Rack SPEC](https://github.com/rack/rack/blob/main/SPEC.rdoc)
- [Rails on Rack](https://guides.rubyonrails.org/rails_on_rack.html)

## License

MIT — see [LICENSE](LICENSE).
