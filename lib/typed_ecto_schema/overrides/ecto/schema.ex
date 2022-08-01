if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Schema do
    use TypedEctoSchema.TypeCheck
    @type! embeds_many(t) :: [t]
    @type! embeds_one(t) :: t
    @type! many_to_many(t) :: [t] | Ecto.Association.NotLoaded.t()
    @type! has_many(t) :: [t] | Ecto.Association.NotLoaded.t()
    @type! has_one(t) :: t | Ecto.Association.NotLoaded.t()
    @type! belongs_to(t) :: t | Ecto.Association.NotLoaded.t()
    @type! t() :: lazy(schema()) | lazy(embedded_schema())
    @type! embedded_schema() :: %{optional(atom()) => any(), __struct__: atom()}
    @type! schema() :: %{
             optional(atom()) => any(),
             __struct__: atom(),
             __meta__: Ecto.Schema.Metadata.t()
           }
    @type! prefix() :: String.t() | nil
    @type! source() :: String.t()
  end
end
