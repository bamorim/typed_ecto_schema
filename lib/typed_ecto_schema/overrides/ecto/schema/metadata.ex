if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Schema.Metadata do
    use TypedEctoSchema.TypeCheck
    @type! t() :: lazy(t(module()))
    @type! t(schema) :: %Ecto.Schema.Metadata{
             context: lazy(context()),
             prefix: Ecto.Schema.prefix(),
             schema: schema,
             source: Ecto.Schema.source(),
             state: lazy(state())
           }
    @type! context() :: any()
    @type! state() :: :built | :loaded | :deleted
  end
end
