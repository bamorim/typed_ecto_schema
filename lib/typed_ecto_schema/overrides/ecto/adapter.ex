if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Adapter do
    @moduledoc false
    use TypedEctoSchema.TypeCheck
    @type! adapter_meta() :: map()
    @type! t() :: module()
  end
end
