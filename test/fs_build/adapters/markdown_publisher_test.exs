defmodule FsBuild.Adapters.MarkdownPublisherTest do
  use ExUnit.Case, async: true

  alias FsBuild.Adapters.MarkdownPublisher
  alias __MODULE__.Example

  doctest MarkdownPublisher

  defmodule DumbBuilder do
    def build(_path, body, attrs) do
      %{body: body, attrs: attrs}
    end
  end

  setup do
    :code.purge(Example)
    :code.delete(Example)
    :ok
  end

  test "builds all matching entries" do
    defmodule Example do
      use FsBuild,
        build: DumbBuilder,
        from: "test/fixtures/**/*.md",
        as: :examples,
        adapter: {MarkdownPublisher, []}

      assert [
               %{
                 body: _,
                 attrs: %{hello: "world"}
               },
               %{
                 body: _,
                 attrs: %{hello: "world"}
               },
               %{
                 body: _,
                 attrs: %{syntax: "nohighlight"}
               },
               %{
                 body: _,
                 attrs: %{syntax: "highlight"}
               }
             ] = @examples
    end
  end

  test "converts to markdown" do
    defmodule Example do
      use FsBuild,
        build: DumbBuilder,
        from: "test/fixtures/markdown.{md,markdown}",
        as: :examples,
        adapter: {MarkdownPublisher, []}

      Enum.each(@examples, fn example ->
        assert example.attrs == %{hello: "world"}
        assert example.body == "<p>\nThis is a markdown <em>document</em>.</p>\n"
      end)
    end
  end

  test "handles code blocks" do
    defmodule Example do
      use FsBuild,
        build: DumbBuilder,
        from: "test/fixtures/nosyntax.md",
        as: :examples,
        adapter: {MarkdownPublisher, []}

      assert hd(@examples).attrs == %{syntax: "nohighlight"}
      assert hd(@examples).body =~ "<pre><code>IO.puts &quot;syntax&quot;</code></pre>"
    end
  end

  test "handles highlight blocks" do
    defmodule Example do
      use FsBuild,
        build: DumbBuilder,
        from: "test/fixtures/syntax.md",
        as: :highlights,
        adapter: {MarkdownPublisher, highlighters: [:makeup_elixir]}

      assert hd(@highlights).attrs == %{syntax: "highlight"}
      assert hd(@highlights).body =~ "<pre><code class=\"makeup elixir\">"
    end
  end

  test "raises if missing separator" do
    assert_raise RuntimeError,
                 ~r/could not find separator --- in "test\/fixtures\/invalid.noseparator"/,
                 fn ->
                   defmodule Example do
                     use FsBuild,
                       build: DumbBuilder,
                       from: "test/fixtures/invalid.noseparator",
                       as: :example,
                       adapter: {MarkdownPublisher, []}
                   end
                 end
  end

  test "raises if not a map" do
    assert_raise RuntimeError,
                 ~r/expected attributes for \"test\/fixtures\/invalid.nomap\" to return a map/,
                 fn ->
                   defmodule Example do
                     use FsBuild,
                       build: DumbBuilder,
                       from: "test/fixtures/invalid.nomap",
                       as: :example,
                       adapter: {MarkdownPublisher, []}
                   end
                 end
  end
end
