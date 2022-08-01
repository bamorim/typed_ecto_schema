if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Repo do
    use TypedEctoSchema.TypeCheck
    @type! t() :: module()
  end
end
