if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Changeset.Relation do
    @moduledoc false
    use TypedEctoSchema.TypeCheck

    @type! t() :: %{
             :__struct__ => atom(),
             :cardinality => :one | :many,
             :on_replace => :raise | :mark_as_invalid | atom(),
             :relationship => :parent | :child,
             :ordered => boolean(),
             :owner => atom(),
             :related => atom(),
             :field => atom(),
             optional(atom()) => any()
           }
  end
end
