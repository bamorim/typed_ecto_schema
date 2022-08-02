if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Schema.Metadata do
    @moduledoc false
    use TypedEctoSchema.TypeCheck
    @type! t() :: t(module())
    @type! t(schema) :: %Ecto.Schema.Metadata{
             context: context(),
             prefix: Ecto.Schema.prefix(),
             schema: schema,
             source: Ecto.Schema.source(),
             state: state()
           }
    @type! context() :: any()
    @type! state() :: :built | :loaded | :deleted
  end
end
