if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Type do
    @moduledoc false
    use TypedEctoSchema.TypeCheck

    @typep! private_composite() ::
              {:maybe, lazy(t())} | {:in, lazy(t())} | {:param, :any_datetime}
    @type! composite() :: {:array, lazy(t())} | {:map, lazy(t())} | private_composite()
    @type! base() ::
             :integer
             | :float
             | :boolean
             | :string
             | :map
             | :binary
             | :decimal
             | :id
             | :binary_id
             | :utc_datetime
             | :naive_datetime
             | :date
             | :time
             | :any
             | :utc_datetime_usec
             | :naive_datetime_usec
             | :time_usec
    @type! custom() :: module() | {:parameterized, module(), term()}
    @type! primitive() :: base() | composite()
    @type! t() :: primitive() | custom()
  end
end
