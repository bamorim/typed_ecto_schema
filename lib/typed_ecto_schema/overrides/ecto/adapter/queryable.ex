if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Adapter.Queryable do
    @moduledoc false
    use TypedEctoSchema.TypeCheck
    @type! selected() :: term()
    @type! options() :: Keyword.t()
    @type! cached() :: term()
    @type! prepared() :: term()
    @type! query_cache() ::
             {:nocache, lazy(prepared())}
             | {:cache, cache_function :: (cached() -> :ok), lazy(prepared())}
             | {:cached, update_function :: (cached() -> :ok),
                reset_function :: (prepared() -> :ok), lazy(cached())}
    @type! query_meta() :: %{sources: tuple(), preloads: term(), select: map()}
    @type! adapter_meta() :: Ecto.Adapter.adapter_meta()
  end
end
