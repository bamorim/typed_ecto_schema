if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Decimal do
    use TypedEctoSchema.TypeCheck
    @type! decimal() :: lazy(t()) | integer() | String.t()
    @type! t() :: %Decimal{coef: lazy(coefficient()), exp: lazy(exponent()), sign: lazy(sign())}
    @type! rounding() :: :down | :half_up | :half_even | :ceiling | :floor | :half_down | :up
    @type! signal() :: :invalid_operation | :division_by_zero | :rounded | :inexact
    @type! sign() :: 1 | -1
    @type! exponent() :: integer()
    @type! coefficient() :: non_neg_integer() | :NaN | :inf
  end
end
