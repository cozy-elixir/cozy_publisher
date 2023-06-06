# CozyPublisher

<!-- MDOC -->

A minimal filesystem-based publishing engine that supports custom
adapters.

It aims to provide a more flexible mechanism for file parsing and transformation.

> This is a fork of [NimblePublisher](https://github.com/dashbitco/nimble_publisher).

## Overview

Suppose we have a batch of article files in following format:

    %{
      title: "Hello world"
    }
    ---
    Body of the "Hello world" article.

    This is a *markdown* document with support for code highlighters:

    ```elixir
    IO.puts "hello world"
    ```

And, we try to use `CozyPublisher` to publish them:

```elixir
use CozyPublisher,
  build: Article,
  from: Application.app_dir(:app_name, "priv/articles/**/*.md"),
  as: :articles
```

The example above will get all matched files in the given directory,
call `Article.build/3` for each file, passing the file path,
the metadata, and the article body, and define a module attribute
named `@articles` with all built articles returned by the
`Article.build/3` function.

## Options

- `:build` - the name of the module that will build each entry.
- `:from` - a wildcard pattern where to find all entries.
- `:as` - the name of the module attribute to store all built entries.
- `:adapter` - the adapter and its options. It allows following formats:
  - `nil` - (default) equals to `{CozyPublisher.Adapters.Default, []}`
  - `module()` - equals to `{module(), keyword()}`
  - `{module(), keyword()}`

## An example

Let's see a complete example using the default adapter, which has
Markdown and code highlighting support.

First add `cozy_publisher` and other required packages as dependencies:

    def deps do
      [
        {:cozy_publisher, "~> 1.0"},
        {:makeup, "~> 1.0"},
        {:makeup_elixir, ">= 0.0.0"},
        {:makeup_erlang, ">= 0.0.0"}
      ]
    end

In this example, we are building a blog. Each post stays in the
"posts" directory with the format:

    /posts/YEAR/MONTH-DAY-ID.md

A typical blog post will look like this:

    # /posts/2020/04-17-hello-world.md
    %{
      title: "Hello world!",
      author: "José Valim",
      tags: ~w(hello),
      description: "Let's learn how to say hello world"
    }
    ---
    This is the post.

Therefore, we will define a `Post` struct that expects all of the fields
above. We will also have a `:date` field that we will build from the
filename. Overall, it will look like this:

```elixir
defmodule MyApp.Blog.Post do
  @enforce_keys [:id, :author, :title, :body, :description, :tags, :date]
  defstruct [:id, :author, :title, :body, :description, :tags, :date]

  def build(path, attrs, body) do
    [year, month_day_id] = path |> Path.rootname() |> Path.split() |> Enum.take(-2)
    [month, day, id] = String.split(month_day_id, "-", parts: 3)
    date = Date.from_iso8601!("#{year}-#{month}-#{day}")
    struct!(__MODULE__, [id: id, date: date, body: body] ++ Map.to_list(attrs))
  end
end
```

Now, we are ready to define our `MyApp.Blog` with `CozyPublisher`:

```elixir
defmodule MyApp.Blog do
  alias CozyPublisher.Adapters.Default, as: DefaultAdapter
  alias MyApp.Blog.Post

  use CozyPublisher,
    build: Post,
    from: Application.app_dir(:my_app, "priv/posts/**/*.md"),
    as: :posts,
    adapter: {DefaultAdapter, highlighters: [:makeup_elixir, :makeup_erlang]}

  # The @posts variable is first defined by CozyPublisher.
  # Let's further modify it by sorting all posts by descending date.
  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

  # Let's also get all tags
  @tags @posts |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  # And finally export them
  def all_posts, do: @posts
  def all_tags, do: @tags
end
```

**Important**: Avoid injecting the `@posts` attribute into multiple functions,
as each call will make a complete copy of all posts. For example, if you want
to show define `recent_posts()` as well as `all_posts()`, DO NOT do this:

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

If you are using Phoenix, you can enable live reloading by simply telling Phoenix to watch the "posts" directory. Open up "config/dev.exs", search for `live_reload:` and add this to the list of patterns:

```elixir
live_reload: [
  patterns: [
    ...,
    ~r"posts/*/.*(md)$"
  ]
]
```

## Custom adapters

By using custom adapters, you can publish any kind of files, not limited to format required by the default adapter.

You may want to define a custom adapter using JSON metadata header:

```elixir
defmodule MyApp.Blog do
  use CozyPublisher,
    # ...
    adapter: {CustomAdapter, []}
end

defmodule CustomAdapter do
  use CozyPublisher.Adapter

  @impl true
  def parse(path, content, _opts) do
    [attrs, body] = :binary.split(content, ["\n---\n"])
    {Jason.decode!(attrs), body}
  end
end
```

You can also create adapters supporting [org](https://orgmode.org/) files, etc. Checkout `CozyPublisher.Adapter` for more details.

<!-- MDOC -->

## License

[Apache License 2.0](./LICENSE)
