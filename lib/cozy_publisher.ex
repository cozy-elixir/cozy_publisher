defmodule CozyPublisher do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias CozyPublisher.Adapters.Default, as: DefaultAdapter

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      {from, paths} = CozyPublisher.__extract__(__MODULE__, opts)

      for path <- paths do
        @external_resource Path.relative_to_cwd(path)
      end

      def __mix_recompile__? do
        unquote(from) |> Path.wildcard() |> Enum.sort() |> :erlang.md5() !=
          unquote(:erlang.md5(paths))
      end

      # TODO: Remove me once we require Elixir v1.11+.
      def __phoenix_recompile__?, do: __mix_recompile__?()
    end
  end

  @doc false
  def __extract__(module, opts) do
    builder = Keyword.fetch!(opts, :build)
    from = Keyword.fetch!(opts, :from)
    as = Keyword.fetch!(opts, :as)

    {adapter_module, adapter_opts} =
      case Keyword.get(opts, :adapter) do
        nil ->
          {DefaultAdapter, []}

        {adapter_module, adapter_opts} ->
          {adapter_module, adapter_opts}

        adapter_module ->
          {adapter_module, []}
      end

    :ok = adapter_module.init(adapter_opts)

    paths = from |> Path.wildcard() |> Enum.sort()

    entries =
      Enum.flat_map(paths, fn path ->
        content = File.read!(path)
        parsed_content = adapter_module.parse(path, content, adapter_opts)
        build_entry(builder, path, parsed_content, adapter_module, adapter_opts)
      end)

    Module.put_attribute(module, as, entries)
    {from, paths}
  end

  defp build_entry(builder, path, {_attr, _body} = parsed_content, adapter_module, adapter_opts) do
    build_entry(builder, path, [parsed_content], adapter_module, adapter_opts)
  end

  defp build_entry(builder, path, parsed_contents, adapter_module, adapter_opts)
       when is_list(parsed_contents) do
    Enum.map(parsed_contents, fn {attrs, body} ->
      body = adapter_module.transform(path, body, adapter_opts)
      builder.build(path, attrs, body)
    end)
  end
end
