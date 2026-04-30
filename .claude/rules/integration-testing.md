---
description: Manual smoke testing of framework changes via the best_quotes sample app
paths:
  - "lib/reins/**"
  - "lib/reins.rb"
  - "bin/reins"
---

# Local Integration Testing

The unit specs verify framework behavior in isolation. **Real apps catch what unit specs miss** — load order, autoload paths, file-based templates, request/response wiring under Puma. Use `../best_quotes` as the local integration testbed.

## Setup

`../best_quotes/Gemfile` must point at the working tree:

```ruby
gem "reins-web", path: "../reins"
```

The gem name is `reins-web`, not `reins` (the latter is taken on RubyGems by an unrelated project). After any change to the framework, run `bundle install` inside `best_quotes/` so it picks up the latest tree.

## When to run an integration smoke

After any of the following lands in the framework:

- A change to the request lifecycle (`Reins::Application#call`)
- A change to the routing DSL or rule matching
- A change to controller dispatch or rendering
- A change to the autoloader
- A change to the CLI (`reins server`, `reins routes`, generators)

The unit specs run on every change; the smoke is for the categories above.

## How to run a smoke

From `../best_quotes`:

```sh
bundle install
bundle exec reins server   # boots Puma on http://localhost:8000
```

Hit the routes (curl or browser) that exercise the changed code. For an M1+ change, run `bundle exec reins routes` first to confirm the route table looks right.

If `best_quotes` doesn't boot or its routes 404 after a framework change, treat that as a regression — fix in the framework, not in best_quotes — unless the change is a documented API break, in which case update best_quotes' `config.ru` to the new API and note the migration in CHANGELOG.

## What NOT to do

- Do not commit changes to `best_quotes` from a framework PR. The two repos move independently.
- Do not modify framework code to keep best_quotes booting on a deprecated API. If best_quotes uses something we've dropped, update best_quotes (in its own repo) to the current API.
- Do not skip the smoke just because the unit specs are green. The categories above have repeatedly shipped regressions that unit specs missed.
