if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Query.Builder do
    @moduledoc false
    use TypedEctoSchema.TypeCheck
    @type! quoted_type() :: Ecto.Type.primitive() | {non_neg_integer(), atom() | Macro.t()}
  end
end
