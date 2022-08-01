if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Decimal.Context do
    use TypedEctoSchema.TypeCheck

    @type! t() :: %Decimal.Context{
             flags: [Decimal.signal()],
             precision: pos_integer(),
             rounding: Decimal.rounding(),
             traps: [Decimal.signal()]
           }
  end
end
