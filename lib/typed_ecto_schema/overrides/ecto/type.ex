if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Type do
    use TypedEctoSchema.TypeCheck

    @typep! private_composite() ::
              {:maybe, lazy(t())} | {:in, lazy(t())} | {:param, :any_datetime}
    @type! composite() :: {:array, lazy(t())} | {:map, lazy(t())} | lazy(private_composite())
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
    @type! primitive() :: lazy(base()) | lazy(composite())
    @type! t() :: lazy(primitive()) | lazy(custom())
  end
end
