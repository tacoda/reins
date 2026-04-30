# Reins — Onboarding Guide

A short tour for developers building their first Reins app. If you've used Rails, most of this will look familiar; the API is intentionally Rails-shaped.

> Reins is pre-1.0. The pieces below all work; some are slimmer than their Rails counterparts. See [README.md](README.md) for the milestone roadmap.

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

## A minimal app

```ruby
# config.ru
require "reins"
require "rack/session"

class HomeController < Reins::Controller
  def index
    render plain: "Hello, world!"
  end
end

app = Reins::Application.new
app.route do
  root "home#index"
end

use Rack::Session::Cookie, secret: "x" * 64
run app
```

```sh
bundle exec reins server   # boots Puma on http://localhost:8000
```

## Project layout

```
config.ru                 # Rack entry point
config/
├── application.rb        # your app's Reins::Application subclass
└── database.yml          # database config (per env)
app/
├── controllers/          # FooController < Reins::Controller
├── models/               # Foo < Reins::Model::Base
└── views/
    ├── layouts/          # application.html.erb (used by default)
    └── <controller>/     # <action>.html.erb
db/
├── migrate/              # YYYYMMDDHHMMSS_<name>.rb files
└── schema.rb             # snapshot, written by `reins db:schema:dump`
public/                   # static files served at /
```

## Routing

Routes live inside `app.route do … end`. The DSL mirrors Rails.

```ruby
app.route do
  root "home#index"

  get  "/about",      "pages#about", as: :about
  post "/login",      "sessions#create"
  get  "/users/:id",  "users#show",
       as: :user,
       constraints: { id: /\d+/ }

  resources :posts                              # the seven RESTful routes

  match "/legacy", "legacy#go"                  # back-compat: any verb
end
```

`as: :user` generates `user_path(id)` and `user_url(id, host: "...")` helpers. Resources auto-generate `posts_path`, `post_path(id)`, `new_post_path`, `edit_post_path(id)`.

`reins routes` prints the full table.

## Controllers

```ruby
class PostsController < Reins::Controller
  before_action :authenticate
  before_action :set_post, only: [:show, :update, :destroy]
  after_action  :log

  def index
    @posts = Post.all
    # auto-renders app/views/posts/index.html.erb
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @post }
    end
  end

  def create
    @post = Post.new(post_params)
    if @post.save
      flash[:notice] = "Created."
      redirect_to post_path(@post)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    head :no_content
  end

  private

  def post_params
    params.require(:post).permit(:title, :body)
  end

  def authenticate
    redirect_to "/login" unless session[:user_id]
  end
end
```

Key surface:

- **`render`** — sets the response. `render :show`, `render plain:`, `render html:`, `render json:`, `render template:`, `status:`, `locals:`, `layout:`. One per request — second call raises `Reins::DoubleResponse`. If the action returns without rendering, the framework auto-renders `app/views/<controller>/<action>.html.erb`.
- **`redirect_to`** — sets `Location` and 302 (or override with `status:`).
- **`head`** — empty body with the given status.
- **`respond_to`** — dispatches by `Accept` header. HTML and JSON are supported.
- **`params`** — `Reins::Parameters`. `.require(:key)` raises if missing; `.permit(*keys)` filters.
- **`session`** / **`flash`** — needs `Rack::Session::Cookie` middleware in `config.ru`. `flash[:notice]` survives one request; `flash.now[:alert]` is current-request only.
- **Filters** — `before_action`, `after_action`, `around_action` with `:only`/`:except`. A `before_action` that emits a response halts the chain.

## Views

ERB templates under `app/views/<controller>/<action>.html.erb`. `<%= %>` auto-escapes; `<%== %>` emits raw output.

```erb
<%# app/views/layouts/application.html.erb %>
<!doctype html>
<html>
  <head>
    <title><%== yield :title %></title>
    <%= stylesheet_link_tag "app" %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
```

```erb
<%# app/views/posts/index.html.erb %>
<% content_for :title do "Posts" end %>
<%= render partial: "post", collection: @posts %>
<%= link_to "New post", new_post_path, class: "btn" %>
```

```erb
<%# app/views/posts/_post.html.erb %>
<article><%= post.title %></article>
```

`Reins::View::Helpers` (mixed into both Views and Controllers): `link_to`, `tag`, `image_tag`, `url_for`, `stylesheet_link_tag`, `javascript_include_tag`, `content_for`/`yield`.

`Reins::View::Forms`: `form_with`, `text_field`, `text_area`, `submit`, `hidden_field`, `label`.

Layouts default to `app/views/layouts/application.html.erb` if it exists. Override per-controller (`layout "marketing"`, optionally with `:only`/`:except`) or per-call (`render :show, layout: "admin"` / `layout: false`).

## Models

```ruby
class Post < Reins::Model::Base
  belongs_to :author
  has_many   :comments
  has_one    :cover_image

  validates :title, presence: true, length: { in: 1..100 }
  validates :slug,  format: /\A[a-z0-9-]+\z/, uniqueness: true

  before_save :generate_slug
end
```

Class-level interface:

```ruby
Post.all                                  # → Relation (lazy)
Post.where(status: "published").order(:created_at).limit(10)
Post.where("created_at > ?", a_time)
Post.find(1)            # raises Reins::Model::RecordNotFound
Post.find_by(slug: "x") # nil on miss
Post.create!(title: "x")
Post.transaction { ... }
Post.count
Post.pluck(:title)
```

Instance interface:

```ruby
post = Post.new(title: "x")
post.valid?
post.errors.full_messages       # ["Title can't be blank", ...]
post.save                       # false on validation failure
post.save!                      # raises Reins::Model::RecordInvalid
post.update(title: "y")
post.destroy
post.persisted?                 # / post.new_record?
```

Auto-timestamps: when `created_at` and/or `updated_at` columns exist, they're populated automatically.

All SQL is parameterized. `Post.where("title = '#{user_input}'")` is wrong — pass the bind: `Post.where("title = ?", user_input)`.

## Migrations

```sh
reins generate migration CreatePosts
# writes db/migrate/<timestamp>_create_posts.rb
```

```ruby
class CreatePosts < Reins::Migration
  def change
    create_table :posts do |t|
      t.string  :title
      t.text    :body
      t.references :author
      t.timestamps
    end

    add_index :posts, :title
  end
end
```

```sh
reins db:create
reins db:migrate         # apply pending
reins db:rollback        # undo the last one
reins db:rollback 3      # undo the last three
reins db:schema:dump     # snapshot to db/schema.rb
reins db:drop
```

Use `change` for reversible migrations (Reins inverts `create_table`, `add_column`, `add_index`). For everything else, define explicit `up` and `down`.

`change_column` isn't supported in SQLite — write `up`/`down` with a table-rebuild.

## Configuration

`config/database.yml`:

```yaml
development:
  database: db/development.sqlite3
test:
  database: db/test.sqlite3
production:
  database: db/production.sqlite3
```

`REINS_ENV` selects the section (defaults to `development`). The CLI's `db:*` commands and your app should call `Reins::DatabaseConfig.load!` before any DB work.

## Common errors

- **`Reins::DoubleResponse`** — your action called `render`/`redirect_to`/`head` twice.
- **`Reins::MissingTemplate`** — auto-render couldn't find the template. Check `app/views/<controller>/<action>.html.erb`.
- **`Reins::ParameterMissing`** — `params.require(...)` got a nil/empty value.
- **`Reins::SessionMiddlewareMissing`** — you used `session` or `flash` without mounting `Rack::Session::Cookie`.
- **`Reins::Model::RecordNotFound`** — `Model.find(id)` couldn't find a row. Use `find_by` for the nil-on-miss form.
- **`Reins::Model::RecordInvalid`** — `save!`/`create!` failed validation. The exception carries the record.
- **`Reins::IrreversibleMigration`** — `change` used an op that can't be auto-inverted. Add an explicit `down`.

## Where to look next

- `README.md` — milestone roadmap and links
- `lib/reins/` — the framework source. Each module is small; the public API is what's documented above.
- `spec/reins/` — RSpec specs that double as runnable examples.

## License

MIT.
