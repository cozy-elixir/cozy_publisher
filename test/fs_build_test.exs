defmodule FsBuildTest do
  use ExUnit.Case, async: true

  alias __MODULE__.Example

  doctest FsBuild

  defmodule DumbBuilder do
    def build(_path, body, attrs) do
      %{body: body, attrs: attrs}
    end
  end

  defmodule DumbAdapter do
    use FsBuild.Adapter

    @impl true
    def transform(path, content, _opts) do
      body =
        content
        |> :binary.split("\nxxx\n")
        |> List.last()
        |> String.upcase()

      attrs = %{path: path, length: String.length(body)}

      {body, attrs}
    end
  end

  setup do
    File.rm_rf!("test/tmp")
    :code.purge(Example)
    :code.delete(Example)
    :ok
  end

  test "does not require recompilation unless paths changed" do
    defmodule Example do
      use FsBuild,
        from: "test/fixtures/syntax.md",
        adapter: {DumbAdapter, []},
        build: DumbBuilder,
        as: :examples
    end

    refute Example.__mix_recompile__?()
  end

  test "requires recompilation if paths change" do
    defmodule Example do
      use FsBuild,
        from: "test/tmp/**/*.md",
        adapter: {DumbAdapter, []},
        build: DumbBuilder,
        as: :examples
    end

    refute Example.__mix_recompile__?()

    File.mkdir_p!("test/tmp")
    File.write!("test/tmp/example.md", "done!")

    assert Example.__mix_recompile__?()
  end

  test "allows for custom adapter with parser returning {body, attrs}" do
    defmodule CustomAdapter do
      use FsBuild.Adapter

      @impl true
      def transform(path, content, _opts) do
        body =
          content
          |> :binary.split("\nxxx\n")
          |> List.last()
          |> String.upcase()

        attrs = %{path: path, length: String.length(body)}

        {body, attrs}
      end
    end

    defmodule Example do
      use FsBuild,
        from: "test/fixtures/custom.parser",
        adapter: {CustomAdapter, []},
        build: DumbBuilder,
        as: :custom

      assert hd(@custom).body == "BODY\n"
      assert hd(@custom).attrs == %{path: "test/fixtures/custom.parser", length: 5}
    end
  end

  test "allows for custom adapter with parser returning a list of {body, attrs}" do
    defmodule CustomMultiAdapter do
      use FsBuild.Adapter

      @impl true
      def transform(path, content, _opts) do
        content
        |> String.split("\n***\n")
        |> Enum.map(fn content ->
          body =
            content
            |> :binary.split("\nxxx\n")
            |> List.last()
            |> String.upcase()

          attrs = %{path: path, length: String.length(body)}

          {body, attrs}
        end)
      end
    end

    defmodule Example do
      use FsBuild,
        from: "test/fixtures/custom.multi.parser",
        adapter: {CustomMultiAdapter, []},
        build: DumbBuilder,
        as: :custom

      assert hd(@custom).body == "BODY\n"
      assert hd(@custom).attrs == %{path: "test/fixtures/custom.multi.parser", length: 5}
      assert length(@custom) == 3
    end
  end
end
