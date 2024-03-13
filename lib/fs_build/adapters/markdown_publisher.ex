if Code.ensure_loaded?(Earmark) do
  defmodule FsBuild.Adapters.MarkdownPublisher do
    @moduledoc """
    An adapter for building a Markdown publishing system.

    ## Required dependencies

      * `:earmark`
      * `:makeup`

    ## Options

      * `:earmark_options` - an `%Earmark.Options{}` struct
      * `:highlighters` - which code highlighters to use. `FsBuild`
        uses `Makeup` for syntax highlighting and you will need to add its
        `.css` classes. You can generate the CSS classes by calling
        `Makeup.stylesheet(:vim_style, "makeup")` inside iex -S mix.
        You can replace `:vim_style` by any style of your choice
        [defined here](https://elixir-makeup.github.io/makeup_demo/elixir.html).

    """

    require Logger

    @behaviour FsBuild.Adapter

    @impl true
    def init(opts) do
      check_dep_makeup!()

      for highlighter <- Keyword.get(opts, :highlighters, []) do
        Application.ensure_all_started(highlighter)
      end

      :ok
    end

    defp check_dep_makeup!() do
      unless Code.ensure_loaded?(Makeup) do
        Logger.error("""
        Could not find required dependency.

        Please add :makeup to your dependencies:

            {:makeup, "~> 1.0"}

        """)

        raise "missing dependency - :makeup"
      end
    end

    @impl true
    def transform(path, content, opts) do
      {body, attrs} = parse_content!(path, content)
      html_body = as_html(body, opts)

      {html_body, attrs}
    end

    defp parse_content!(path, content) do
      case parse_content(path, content) do
        {:ok, body, attrs} ->
          {body, attrs}

        {:error, message} ->
          raise """
          #{message}

          Each entry must have a map with attributes, followed by --- and a body. For example:

              %{
                title: "Hello World"
              }
              ---
              Hello world!

          """
      end
    end

    defp parse_content(path, content) do
      case :binary.split(content, ["\n---\n", "\r\n---\r\n"]) do
        [_] ->
          {:error, "could not find separator --- in #{inspect(path)}"}

        [code, body] ->
          case Code.eval_string(code, []) do
            {%{} = attrs, _} ->
              {:ok, body, attrs}

            {other, _} ->
              {:error,
               "expected attributes for #{inspect(path)} to return a map, got: #{inspect(other)}"}
          end
      end
    end

    defp as_html(body, opts) do
      earmark_opts = Keyword.get(opts, :earmark_options, Earmark.Options.make_options!())
      highlighters = Keyword.get(opts, :highlighters, [])
      body |> Earmark.as_html!(earmark_opts) |> highlight(highlighters)
    end

    defp highlight(html, []) do
      html
    end

    defp highlight(html, _) do
      __MODULE__.Highlighter.highlight(html)
    end
  end
end
