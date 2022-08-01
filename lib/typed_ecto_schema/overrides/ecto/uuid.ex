if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.UUID do
    @moduledoc false
    use TypedEctoSchema.TypeCheck
    @type! raw() :: <<_::128>>
    @type! t() :: <<_::288>>
  end
end
