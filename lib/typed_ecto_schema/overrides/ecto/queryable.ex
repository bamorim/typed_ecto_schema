if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Queryable do
    use TypedEctoSchema.TypeCheck
    @type! t() :: term()
  end
end
