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

To go deeper, read the source — `lib/reins/` is intentionally small (one file per concern) and the specs in `spec/reins/` double as runnable examples.

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
