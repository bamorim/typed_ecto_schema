if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Association.NotLoaded do
    @moduledoc false
    use TypedEctoSchema.TypeCheck

    @type! t() :: %Ecto.Association.NotLoaded{
             __cardinality__: atom(),
             __field__: atom(),
             __owner__: any()
           }
  end
end
