# Getting Started with Reins

This guide walks you through building a small blog from scratch using Reins. By the end you'll have created posts, listed them, validated them, and added comments — exercising every layer of the framework.

If you've used Rails, the shape will feel familiar. The differences are noted as we go.

## Prerequisites

- **Ruby 3.3+**. Check with `ruby -v`.
- **Bundler**. `gem install bundler` if needed.
- The `reins` CLI, available once `reins-web` is installed:

  ```sh
  gem install reins-web
  reins -h
  ```

## 1. Create the application

```sh
reins new blog
cd blog
bin/setup
```

`reins new` writes the project skeleton; `bin/setup` runs `bundle install` and creates the development database. The tree:

```
blog/
├── Gemfile             # reins-web pinned, plus rspec, puma, rerun
├── config.ru           # Rack entry point
├── bin/{reins,setup,console}
├── config/
│   ├── application.rb  # Blog::Application < Reins::Application
│   ├── routes.rb       # Reins.application.route do ... end
│   ├── database.yml    # one section per env
│   └── environments/{development,test,production}.rb
├── app/
│   ├── controllers/{application_controller,welcome_controller}.rb
│   ├── models/application_record.rb
│   └── views/
│       ├── layouts/application.html.erb
│       └── welcome/index.html.erb
├── db/migrate/
├── public/{404,422,500}.html
└── spec/spec_helper.rb
```

Boot it:

```sh
reins server
```

Visit `http://localhost:8000` — you'll see "It works!" served from `app/views/welcome/index.html.erb`.

## 2. Say hello

The welcome page is rendered by `WelcomeController#index`. Open `app/views/welcome/index.html.erb` and edit it:

```erb
<h1>Welcome to my blog</h1>
<p>Built with <a href="https://rubygems.org/gems/reins-web">Reins</a>.</p>
```

Refresh — restart the server with `Ctrl-C` and `reins server` again. (For automatic reloading during development, run the server with `bundle exec rerun reins server`.)

`reins routes` shows the route table:

```
Prefix  Verb  URI Pattern  Controller#Action
root    GET   /            welcome#index
```

## 3. Generate a Post resource

A blog needs posts. Generate the scaffold:

```sh
reins generate scaffold Post title:string body:text
```

This creates:

- `app/models/post.rb` — `class Post < ApplicationRecord`
- `db/migrate/<ts>_create_posts.rb` — table definition
- `app/controllers/posts_controller.rb` — full CRUD (index/show/new/create/edit/update/destroy)
- `app/views/posts/{index,show,new,edit}.html.erb` plus `_form.html.erb`
- A line appended to `config/routes.rb`: `resources :posts`
- `spec/models/post_spec.rb` and `spec/controllers/posts_controller_spec.rb` stubs

Apply the migration:

```sh
reins db:migrate
```

Boot the server again and visit `http://localhost:8000/posts`. You can create, list, edit, and delete posts.

`reins routes` now includes the seven RESTful routes for posts:

```
   Prefix  Verb    URI Pattern         Controller#Action
     root  GET     /                   welcome#index
    posts  GET     /posts              posts#index
new_post   GET     /posts/new          posts#new
           POST    /posts              posts#create
     post  GET     /posts/:id          posts#show
edit_post  GET     /posts/:id/edit     posts#edit
           PUT     /posts/:id          posts#update
           PATCH   /posts/:id          posts#update
           DELETE  /posts/:id          posts#destroy
```

The named-route helpers (`posts_path`, `post_path(id)`, `new_post_path`, `edit_post_path(id)`) are available in views and controllers.

## 4. Add validations

Open `app/models/post.rb`:

```ruby
class Post < ApplicationRecord
  validates :title, presence: true, length: { in: 1..100 }
  validates :body,  presence: true
end
```

Visit `/posts/new`, submit an empty form. The scaffold renders the form again with errors — but it doesn't show them yet. Edit `app/views/posts/_form.html.erb` to display errors:

```erb
<%= form_with(url: "/posts", method: record.persisted? ? :put : :post) %>
  <% if record.errors.full_messages.any? %>
    <ul class="errors">
      <% record.errors.full_messages.each do |msg| %>
        <li><%== msg %></li>
      <% end %>
    </ul>
  <% end %>

  <div>
    <%= label :title %><br>
    <%= text_field :title, value: record.title %>
  </div>
  <div>
    <%= label :body %><br>
    <%= text_area :body, value: record.body %>
  </div>
  <div><%= submit %></div>
</form>
```

Now invalid submissions show their errors inline. The scaffold's `create` action already returns 422 on validation failure — this is just how the user sees it.

## 5. Customize the index view

Open `app/views/posts/index.html.erb`. The scaffold writes a bare table; replace it with something more useful:

```erb
<h1>All posts</h1>

<p><%= link_to "New post", new_post_path, class: "btn" %></p>

<% @records.each do |post| %>
  <article>
    <h2><%= link_to post.title, post_path(post.id) %></h2>
    <p><%= post.body %></p>
  </article>
<% end %>
```

`link_to`, `new_post_path`, and `post_path` are all built-in helpers.

## 6. Use `Reins.logger`

The framework writes to `log/<env>.log` at the configured level. Add a log line to your `create` action in `app/controllers/posts_controller.rb`:

```ruby
def create
  @record = Post.new(record_params)
  if @record.save
    Reins.logger.info("Created post #{@record.id} — #{@record.title.inspect}")
    redirect_to "/posts/#{@record.id}"
  else
    render :new, status: :unprocessable_entity
  end
end
```

Tail the log:

```sh
tail -f log/development.log
```

## 7. Add comments

Posts need comments. Generate a model + migration:

```sh
reins generate model Comment post_id:integer body:text
reins db:migrate
```

Wire up the association in `app/models/post.rb`:

```ruby
class Post < ApplicationRecord
  has_many :comments, foreign_key: "post_id"

  validates :title, presence: true, length: { in: 1..100 }
  validates :body,  presence: true
end
```

And in `app/models/comment.rb`:

```ruby
class Comment < ApplicationRecord
  belongs_to :post

  validates :body, presence: true
end
```

Now in `app/views/posts/show.html.erb` you can render the comments:

```erb
<h1><%= @record.title %></h1>
<p><%= @record.body %></p>

<h2>Comments</h2>
<% @record.comments.each do |comment| %>
  <article>
    <p><%= comment.body %></p>
  </article>
<% end %>
```

`@record.comments` returns a `Reins::Model::Relation`, so you can chain: `@record.comments.order(created_at: :desc).limit(5)`.

To let users post comments, add a route in `config/routes.rb`:

```ruby
Reins.application.route do
  root "welcome#index"
  resources :posts

  post "/posts/:post_id/comments", "comments#create", as: :post_comments
end
```

Generate a `CommentsController`:

```sh
reins generate controller Comments create
```

And edit `app/controllers/comments_controller.rb`:

```ruby
class CommentsController < ApplicationController
  def create
    post = Post.find(params[:post_id])
    comment = Comment.new(body: params[:body], post_id: post.id)
    if comment.save
      redirect_to post_path(post.id)
    else
      render plain: "Comment invalid: #{comment.errors.full_messages.join(', ')}",
             status: :unprocessable_entity
    end
  end
end
```

Add a comment form to `app/views/posts/show.html.erb`:

```erb
<h2>Add a comment</h2>
<form action="<%= post_comments_path(post_id: @record.id) %>" method="post">
  <%= text_field :body %>
  <%= submit "Post comment" %>
</form>
```

Visit a post — write a comment — submit. It appears.

## 8. Test the model

Open `spec/models/post_spec.rb` (the generator wrote a stub) and add some real specs:

```ruby
require "spec_helper"

RSpec.describe Post, type: :model do
  it "requires a title" do
    expect(Post.new(title: nil, body: "x")).not_to be_valid
  end

  it "saves a valid post" do
    post = Post.new(title: "Hello", body: "World")
    expect(post.save).to be(true)
    expect(Post.count).to eq(1)
  end
end
```

The `type: :model` metadata wraps each example in a database transaction that rolls back at the end — so tests don't leak state. Run them:

```sh
reins test
```

Or directly:

```sh
bundle exec rspec
```

## 9. Test the controller

```ruby
# spec/controllers/posts_controller_spec.rb
require "spec_helper"

RSpec.describe PostsController, type: :controller do
  let(:app) { Rack::Builder.parse_file("config.ru") }

  it "GET /posts returns 200" do
    get "/posts"
    expect(last_response).to have_http_status(:ok)
  end

  it "POST /posts with valid params redirects to the new post" do
    post "/posts", post: { title: "Hi", body: "There" }
    expect(last_response).to redirect_to("/posts/1")
  end
end
```

The `type: :controller` metadata includes `Rack::Test::Methods` and the custom matchers (`have_http_status`, `redirect_to`).

## 10. Deploy notes

For production:

```sh
REINS_ENV=production reins db:create
REINS_ENV=production reins db:migrate
REINS_ENV=production reins server
```

`config/environments/production.rb` already sets `eager_load = true` (so the autoloader requires every file at boot — no per-request `Module#autoload`) and `log_level = :info`. Add or remove middleware in that file.

## What you've used

You've now exercised every layer of Reins:

- **Routing** — `root`, `resources`, named verb routes
- **Controllers** — filters, render, redirect, params, flash
- **Views** — layouts, partials, helpers, auto-escape
- **Models** — validations, associations, the chainable `Relation`
- **Migrations** — scaffolded, `db:migrate`, `db:rollback`
- **Generators** — `new`, `generate scaffold`, `generate model`, `generate controller`
- **Environments / autoloading** — Zeitwerk-backed, `Reins.env`, `Reins.config`
- **Testing** — `type: :model`, `type: :controller`, custom matchers

To go deeper, read the source — `lib/reins/` is laid out as a hexagon (see below) and the specs in `spec/reins/` double as runnable examples.

## Architecture

Reins 2.0 is internally a **Cockburn-strict hexagon**: pure core, explicit ports, swappable adapters. You don't have to think about this to use the framework — `Reins::Controller`, `Reins::Model::Base`, and `route { resources :foo }` work exactly like you'd expect. The architecture matters when you want to test in isolation, swap out an adapter (in-memory database for tests, a different template engine, a fake clock), or add your own port for a domain capability.

### Why hexagonal?

Alistair Cockburn named the pattern in 2005 to describe a single, recurring problem: applications get strangled by their I/O. The HTTP framework, the database, the template engine, the queue — each ends up touching every layer of the codebase, so a change to "use a different database" becomes a change everywhere. Hexagonal flips this: the **application** is one thing, and every piece of I/O is an **adapter** the application can swap. Driving adapters (the things that initiate calls into the app — HTTP, CLI, a message queue) live on one side. Driven adapters (the things the app initiates calls *to* — the database, the file system, a third-party API) live on the other. Between the two: the **ports**, which are the application's interface contracts.

The "strict" in *Cockburn-strict* means three rules are non-negotiable:

1. The core has no knowledge of the outside world — no infrastructure libraries imported, no `Rack`/`SQLite3`/`Puma` constants referenced.
2. Dependencies point inward. Adapters depend on ports; ports depend on nothing; the core depends on the ports it consumes.
3. Anything crossing a port is a plain value object, not an infrastructure type.

The payoff: the entire core can be tested without booting Rack, opening a database, or touching disk. Swapping SQLite for Postgres becomes "write a new adapter against the existing Repository port." Adding a new capability (say, payment processing) becomes "define a port, write the adapter."

```
              +-------------------+
   driving    |    application    |   driven
  adapters →  |       core        | →  adapters
              +-------------------+
```

- **Core** (`lib/reins/core/**`) — pure domain. Knows nothing about Rack, SQLite, Erubis, Puma, Thor, or the filesystem. The boundary is enforced by a spec (`spec/reins/core_boundary_spec.rb`); the core can't even `require` those libraries.
- **Ports** (`lib/reins/ports/{driving,driven}/**`) — Ruby modules with a frozen `CONTRACT` hash listing the methods adapters must implement. Driving ports (`HttpApp`, `CommandInvoker`) are how the outside world talks to the core. Driven ports (`Repository`, `SchemaInspector`, `TemplateStore`, `TemplateEngine`, `FileSystem`, `ProcessRunner`, `Server`, `EnvReader`, `Clock`, `Autoloader`) are how the core reaches the outside.
- **Adapters** (`lib/reins/adapters/{driving,driven}/**`) — concrete implementations. `Adapters::Driving::Rack::App` is the Rack-facing entry point; `Adapters::Driven::Sqlite::Repository` is the default persistence adapter; `Adapters::Driven::Memory::Repository` is the in-memory one used by tests.

### Profiles

`Reins::Application` picks a **profile** at boot — a named bundle of default adapters:

| Profile | Repository | Server | Template | Clock | EnvReader |
|---|---|---|---|---|---|
| `:standard` (default) | SQLite | Puma | Erubis + Filesystem | System | System |
| `:test` | Memory | (none) | Erubis + Filesystem | Fixed | Memory |
| `:slim` | nil | nil | nil | nil | nil |

`reins new myapp` uses `:standard`; `reins new myapp --slim` uses `:slim` so every adapter slot is visible (and nil) in your `config/application.rb` — you fill them in yourself.

### Adding your own port and adapter

App authors can extend the hexagon. Say you're integrating Stripe:

```sh
reins generate port payment_gateway          # → app/ports/payment_gateway.rb
reins generate adapter stripe --port=payment_gateway
                                              # → app/adapters/stripe.rb
```

The port file declares its direction and contract through a small DSL:

```ruby
require "reins/port"

module PaymentGateway
  extend Reins::Port

  direction :driven

  contract  charge: 3,   # (amount, currency, source_id)
            refund: 1    # (charge_id)
end
```

The `extend Reins::Port` line is the visible signal that this module is a port. `direction` and `contract` set up the constants (`DIRECTION`, `CONTRACT`) and register the port in `Reins::Port.all`.

The adapter `include`s the port and implements each method. A test adapter is the same pattern with an in-memory store. Wire it at the composition root in `config/application.rb`:

```ruby
class Blog::Application < Reins::Application
  profile :standard

  adapters do |a|
    a.payment_gateway = MyApp::Adapters::Stripe.new(api_key: ENV.fetch("STRIPE_KEY"))
  end
end
```

The framework's own ports ship as presets — useful when you want to swap one out wholesale or learn the pattern:

```sh
reins generate port --rack          # framework's HTTP driving port + Rack adapter
reins generate port --sqlite        # Repository + SchemaInspector + SchemaMigrator + SQLite adapters
reins generate port --puma          # Server port + Puma adapter
reins generate port --memory        # in-memory test adapters for repository, file_system, etc.
reins generate port --list          # print every preset
```

The contract behind each preset is the same idea: a port module with a `CONTRACT` hash, one or more adapters that `include` it and define every method. The generators write the scaffold; you fill in the body.

### Testing your adapter

Every adapter spec asserts the port contract:

```ruby
it "responds to every method on the PaymentGateway port contract" do
  PaymentGateway::CONTRACT.each_key do |name|
    expect(adapter).to respond_to(name), "missing #{name}"
  end
end
```

That's the contract test. Beyond that, write the behavior specs you'd write for any class — feed input, check output.

### Autoloading and dependency injection

These are sometimes confused. They solve different problems and Reins uses both, at different layers:

- **Zeitwerk** (autoloading) answers *where does this constant's file live?* Used inside your app's `app/` tree so you don't have to `require` files. Convention-over-configuration.
- **Dependency injection** (Reins::Application's composition root) answers *which implementation does this port get?* Used to swap adapters at boot — production uses SQLite, tests use an in-memory adapter, your staging environment might use a third.

The autoloader itself lives behind a port (`Reins::Ports::Driven::Autoloader`) so the core stays pure of Zeitwerk. The default adapter wraps Zeitwerk; a noop adapter is available for tests that don't want the autoloader running.

### Further reading

If you've read this far and want to go deeper:

- [Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/) — Alistair Cockburn's original write-up. The canonical reference. Short.
- [Hexagonal Architecture: three principles and an implementation example](https://octo.com/insights/hexagonal-architecture-three-principles-and-an-implementation-example) — a clearer, longer treatment of the strict variant.
- [Ports & Adapters Architecture, Tom Stuart](https://blog.thecodewhisperer.com/permalink/ports-adapters-and-the-functional-core-imperative-shell) — connects hexagonal to functional core / imperative shell.
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) and [Onion Architecture](https://jeffreypalermo.com/2008/07/the-onion-architecture-part-1/) — Cockburn's hexagon predates both. The shapes differ; the rule (inward-pointing dependencies, infrastructure at the edges) is the same.
- [Hanami](https://hanamirb.org/) — a Ruby framework that takes a hexagonal-adjacent shape (providers, slices) further than Reins. Worth reading alongside Reins to see two interpretations of the same idea.

## Common errors

- **`Reins::DoubleResponse`** — your action called `render`/`redirect_to`/`head` twice.
- **`Reins::MissingTemplate`** — auto-render couldn't find the template. Check `app/views/<controller>/<action>.html.erb`.
- **`Reins::ParameterMissing`** — `params.require(...)` got a nil/empty value.
- **`Reins::SessionMiddlewareMissing`** — you used `session` or `flash` without mounting `Rack::Session::Cookie`.
- **`Reins::Model::RecordNotFound`** — `Model.find(id)` couldn't find a row. Use `find_by` for the nil-on-miss form.
- **`Reins::Model::RecordInvalid`** — `save!`/`create!` failed validation. The exception carries the record.
- **`Reins::IrreversibleMigration`** — `change` used an op that can't be auto-inverted. Add an explicit `down`.

## Where to go next

- [README.md](README.md) — top-level overview and CLI reference
- [CHANGELOG.md](CHANGELOG.md) — what landed in each milestone
- The framework source: `lib/reins/` is small enough to read end-to-end in an afternoon.

## License

MIT.
