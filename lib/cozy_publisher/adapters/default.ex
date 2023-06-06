defmodule CozyPublisher.Adapters.Default do
  @moduledoc """
  The default adapter used by `CozyPublisher`.

  Files with the `.md` or `.markdown` extension will be converted to
  HTML with `Earmark`. Other files will be kept as is.

  ## Required dependencies

    * `:earmark`
    * `:makeup`

  ## Options

    * `:earmark_options` - an `%Earmark.Options{}` struct
    * `:highlighters` - which code highlighters to use. `CozyPublisher`
      uses `Makeup` for syntax highlighting and you will need to add its
      `.css` classes. You can generate the CSS classes by calling
      `Makeup.stylesheet(:vim_style, "makeup")` inside iex -S mix.
      You can replace `:vim_style` by any style of your choice
      [defined here](https://elixir-makeup.github.io/makeup_demo/elixir.html).

  """

  require Logger

  @behaviour CozyPublisher.Adapter

  @impl true
  def init(opts) do
    check_dep_earmark!()
    check_dep_makeup!()

    for highlighter <- Keyword.get(opts, :highlighters, []) do
      Application.ensure_all_started(highlighter)
    end

    :ok
  end

  defp check_dep_earmark!() do
    unless Code.ensure_loaded?(Earmark) do
      Logger.error("""
      Could not find required dependency.

      Please add :earmark to your dependencies:

          {:earmark, "~> 1.4"}

      """)

      raise "missing dependency - :earmark"
    end
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
  def parse(path, content, _opts) do
    case parse_content(path, content) do
      {:ok, attrs, body} ->
        {attrs, body}

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
            {:ok, attrs, body}

          {other, _} ->
            {:error,
             "expected attributes for #{inspect(path)} to return a map, got: #{inspect(other)}"}
        end
    end
  end

  @impl true
  def transform(path, body, opts) do
    path
    |> Path.extname()
    |> String.downcase()
    |> as_html(body, opts)
  end

  if Code.ensure_loaded?(Earmark) do
    defp as_html(extname, body, opts) when extname in [".md", ".markdown"] do
      earmark_opts = Keyword.get(opts, :earmark_options, %Earmark.Options{})
      highlighters = Keyword.get(opts, :highlighters, [])
      body |> Earmark.as_html!(earmark_opts) |> highlight(highlighters)
    end

    defp as_html(_extname, body, _opts) do
      body
    end

    defp highlight(html, []) do
      html
    end

    defp highlight(html, _) do
      __MODULE__.Highlighter.highlight(html)
    end
  else
    defp as_html(_extname, body, _opts) do
      body
    end
  end
end
