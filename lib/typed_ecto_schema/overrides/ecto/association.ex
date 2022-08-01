if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Association do
    @moduledoc false
    use TypedEctoSchema.TypeCheck

    @type! t() :: %{
             :__struct__ => atom(),
             :on_cast => nil | (... -> any()),
             :cardinality => :one | :many,
             :relationship => :parent | :child,
             :owner => atom(),
             :owner_key => atom(),
             :field => atom(),
             :unique => boolean(),
             optional(atom()) => any()
           }
  end
end
