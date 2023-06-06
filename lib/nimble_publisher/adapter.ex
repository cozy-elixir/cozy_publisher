defmodule NimblePublisher.Adapter do
  @moduledoc """
  The specification of adapters.
  """

  @typedoc "The option for current adapter."
  @type opts() :: keyword()

  @typedoc "The path of file."
  @type path() :: binary()

  @typedoc "The content of file."
  @type content() :: binary()

  @typedoc "The attributes parsed from file."
  @type attrs() :: map()

  @typedoc "The body parsed from file."
  @type body() :: binary()

  @doc """
  Prepares for future works, such as:

    * checking required dependencies
    * starting necessary applications

  """
  @callback init(opts()) :: :ok

  @doc """
  Parses the content of files.

  It must return:

    * a 2 element tuple with attributes and body - `{attrs, body}`
    * a list of 2 element tuple with attributes and body - `[{attrs, body} | _]`

  """
  @callback parse(path(), content(), opts()) :: {attrs(), body()} | [{attrs(), body()}]

  @doc """
  Transforms the parsed body.
  """
  @callback transform(path(), body(), opts()) :: any()

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)

      @impl true
      def init(_opts), do: :ok
      defoverridable init: 1

      @impl true
      def transform(_path, body, _opts), do: body
      defoverridable transform: 3
    end
  end
end
