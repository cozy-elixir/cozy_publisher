defmodule FsBuild.Adapter do
  @moduledoc """
  The specification of adapters.
  """

  @typedoc "The option for current adapter."
  @type opts() :: keyword()

  @typedoc "The path of file."
  @type path() :: binary()

  @typedoc "The content of file."
  @type content() :: binary()

  @typedoc "The main data transformed from file."
  @type data() :: any()

  @typedoc "The metadata transformed from file."
  @type metadata() :: map()

  @doc """
  Prepares for following works, such as:

    * checking required dependencies
    * starting necessary applications
    * ...

  """
  @callback init(opts()) :: :ok

  @doc """
  Transforms the content of files.

  It must return:

    * a 2 element tuple with attributes and body - `{data, metadata}`
    * a list of 2 element tuple with attributes and body - `[{data, metadata} | _]`

  """
  @callback transform(path(), content(), opts()) ::
              {data(), metadata()} | [{data(), metadata()}]

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)

      @impl true
      def init(_opts), do: :ok
      defoverridable init: 1
    end
  end
end
