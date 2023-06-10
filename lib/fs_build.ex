defmodule FsBuild do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC -->")
             |> Enum.fetch!(1)

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      {from, paths} = FsBuild.__extract__(__MODULE__, opts)

      for path <- paths do
        @external_resource Path.relative_to_cwd(path)
      end

      def __mix_recompile__? do
        unquote(from) |> Path.wildcard() |> Enum.sort() |> :erlang.md5() !=
          unquote(:erlang.md5(paths))
      end
    end
  end

  @doc false
  def __extract__(module, opts) do
    builder = Keyword.fetch!(opts, :build)
    from = Keyword.fetch!(opts, :from)
    as = Keyword.fetch!(opts, :as)
    {adapter_module, adapter_opts} = Keyword.fetch!(opts, :adapter)

    :ok = adapter_module.init(adapter_opts)

    paths = from |> Path.wildcard() |> Enum.sort()

    entries =
      Enum.flat_map(paths, fn path ->
        content = File.read!(path)
        transformed_content = adapter_module.transform(path, content, adapter_opts)
        build_entry(builder, path, transformed_content)
      end)

    Module.put_attribute(module, as, entries)
    {from, paths}
  end

  defp build_entry(builder, path, {_data, _metadata} = transformed_content) do
    build_entry(builder, path, [transformed_content])
  end

  defp build_entry(builder, path, transformed_contents) when is_list(transformed_contents) do
    Enum.map(transformed_contents, fn {data, metadata} ->
      builder.build(path, data, metadata)
    end)
  end
end
