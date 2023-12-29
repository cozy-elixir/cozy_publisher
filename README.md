# FsBuild

[![CI](https://github.com/cozy-elixir/fs_build/actions/workflows/ci.yml/badge.svg)](https://github.com/cozy-elixir/fs_build/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/fs_build.svg)](https://hex.pm/packages/fs_build)

<!-- MDOC -->

A filesystem-based build engine which provides a flexible mechanism for
parsing and processing files.

> This is a fork of [NimblePublisher](https://github.com/dashbitco/nimble_publisher).

## Overview

```elixir
use FsBuild,
  from: Application.app_dir(:app_name, "priv/articles/**/*.md"),
  adapter: {FsBuild.Adapters.MarkdownPublisher, []},
  build: Article,
  as: :articles
```

The example above will:

1. get all files whose path match the given pattern.
2. extract `data` and `metadata` from files by using adapter
   `FsBuild.Adapters.MarkdownPublisher`.
3. call `Article.build/3` for each file, passing the `data` and
   `metadata` arguments.
4. define a module attribute named `@articles` with all built articles
   returned by `Article.build/3` function.

## Options

- `:from` - a wildcard pattern where to find all files.
- `:adapter` - the adapter and its options - `{module(), any()}`.
- `:build` - this option can be:
  - the name of module which has `build/3` function inside.
  - a function whose arity number is 3.
- `:as` - the name of the module attribute to store all built files.

## An example

Let's build a blog by using the built-in adapter -
`FsBuild.Adapters.MarkdownPublisher`, which has Markdown and code
highlighting support.

First, add `fs_build` and other required packages as dependencies:

    def deps do
      [
        {:fs_build, "~> 1.0"},
        {:earmark, "~> 1.4"},
        {:makeup, "~> 1.0"},
        {:makeup_elixir, ">= 0.0.0"},
        {:makeup_erlang, ">= 0.0.0"}
      ]
    end

Each post stays in the `priv/posts/` directory with the format:

    priv/posts/YEAR/MONTH-DAY-ID.md

A typical post will look like this:

    # priv/posts/2020/04-17-hello-world.md
    %{
      title: "Hello world!",
      author: "José Valim",
      tags: ~w(hello),
      description: "Let's learn how to say hello world"
    }
    ---
    This is the post.

Then, we define a `Post` struct that expects all of the fields
above. We will also have a `:date` field that we will build from the
filename. Overall, it will look like this:

```elixir
defmodule MyApp.Blog.Post do
  @enforce_keys [:id, :author, :title, :body, :description, :tags, :date]
  defstruct [:id, :author, :title, :body, :description, :tags, :date]

  def build(path, body, attrs) do
    [year, month_day_id] = path |> Path.rootname() |> Path.split() |> Enum.take(-2)
    [month, day, id] = String.split(month_day_id, "-", parts: 3)
    date = Date.from_iso8601!("#{year}-#{month}-#{day}")
    struct!(__MODULE__, [id: id, date: date, body: body] ++ Map.to_list(attrs))
  end
end
```

Now, we are ready to define our `MyApp.Blog` with `FsBuild`:

```elixir
defmodule MyApp.Blog do
  alias FsBuild.Adapters.MarkdownPublisher
  alias MyApp.Blog.Post

  use FsBuild,
    from: Application.app_dir(:my_app, "priv/posts/**/*.md"),
    adapter: {MarkdownPublisher, highlighters: [:makeup_elixir, :makeup_erlang]},
    build: Post,
    as: :posts

  # The @posts module attribute is first defined by FsBuild.
  # Let's further modify it by sorting all posts by descending date.
  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

  # Let's also get all tags
  @tags @posts |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  # And finally export them
  def all_posts, do: @posts
  def all_tags, do: @tags
end
```

**Important**: Avoid injecting the `@posts` module attribute into multiple
functions, as each call will make a complete copy of all posts. For example,
if you want to show define `recent_posts()` as well as `all_posts()`,
**DO NOT** do this:

```elixir
def all_posts, do: @posts
def recent_posts, do: Enum.take(@posts, 3)
```

Instead do this:

```elixir
def all_posts, do: @posts
def recent_posts, do: Enum.take(all_posts(), 3)
```

### Other helpers

You may want to define other helpers to traverse your published resources.
For example, if you want to get posts by ID or with a given tag, you can
define additional functions as shown below:

```elixir
defmodule NotFoundError do
  defexception [:message, plug_status: 404]
end

def get_post_by_id!(id) do
  Enum.find(all_posts(), &(&1.id == id)) ||
    raise NotFoundError, "post with id=#{id} not found"
end

def get_posts_by_tag!(tag) do
  case Enum.filter(all_posts(), &(tag in &1.tags)) do
    [] -> raise NotFoundError, "posts with tag=#{tag} not found"
    posts -> posts
  end
end
```

### Live reloading

If you are using Phoenix, you can enable live reloading by simply telling
Phoenix to watch the `priv/posts/` directory. Open up `config/dev.exs`,
search for `live_reload:` and add this to the list of patterns:

```elixir
live_reload: [
  patterns: [
    ...,
    ~r"priv/posts/*/.*(md)$"
  ]
]
```

## Custom adapters

By using custom adapters, you can process any kind of files. For example,
[org](https://orgmode.org/) files, JSON files, YAML files, etc.

Checkout `FsBuild.Adapter` for more details.

<!-- MDOC -->

## License

[Apache License 2.0](./LICENSE)
