if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Queryable do
    @moduledoc false
    use TypedEctoSchema.TypeCheck
    @type! t() :: term()
  end
end
