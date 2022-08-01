if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Adapter.Transaction do
    use TypedEctoSchema.TypeCheck
    @type! adapter_meta() :: Ecto.Adapter.adapter_meta()
  end
end
