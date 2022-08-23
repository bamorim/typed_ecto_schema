if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Adapter.Schema do
    @moduledoc false
    use TypedEctoSchema.TypeCheck

    @type! on_conflict() ::
             {:raise, list(), []}
             | {:nothing, list(), [atom()]}
             | {[atom()], list(), [atom()]}
             | {Ecto.Query.t(), list(), [atom()]}
    @type! options() :: Keyword.t()
    @type! placeholders() :: [term()]
    @type! returning() :: [atom()]
    @type! constraints() :: Keyword.t()
    @type! filters() :: Keyword.t()
    @type! fields() :: Keyword.t()
    @type! schema_meta() :: %{
             autogenerate_id: {schema_field :: atom(), source_field :: atom(), Ecto.Type.t()},
             context: term(),
             prefix: binary() | nil,
             schema: atom(),
             source: binary()
           }
    @type! adapter_meta() :: Ecto.Adapter.adapter_meta()
  end
end
