if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.ParameterizedType do
    use TypedEctoSchema.TypeCheck
    @type! params() :: term()
    @type! opts() :: keyword()
  end
end
