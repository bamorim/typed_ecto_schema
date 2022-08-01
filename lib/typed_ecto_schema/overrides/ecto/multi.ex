if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Multi do
    @moduledoc false
    use TypedEctoSchema.TypeCheck
    @typep! names() :: MapSet.t()
    @typep! operations() :: [{lazy(name()), lazy(operation())}]
    @typep! operation() ::
              {:changeset, Ecto.Changeset.t(), Keyword.t()}
              | {:run, lazy(run())}
              | {:put, any()}
              | {:inspect, Keyword.t()}
              | {:merge, lazy(merge())}
              | {:update_all, Ecto.Query.t(), Keyword.t()}
              | {:delete_all, Ecto.Query.t(), Keyword.t()}
              | {:insert_all, lazy(schema_or_source()), [map() | Keyword.t()], Keyword.t()}
    @typep! schema_or_source() :: binary() | {binary(), module()} | module()
    @type! t() :: %Ecto.Multi{names: lazy(names()), operations: lazy(operations())}
    @type! name() :: any()
    @type! merge() :: (lazy(changes()) -> lazy(t())) | {module(), atom(), [any()]}
    @type! fun(result) :: (lazy(changes()) -> result)
    @type! run() ::
             (Ecto.Repo.t(), lazy(changes()) -> {:ok | :error, any()})
             | {module(), atom(), [any()]}
    @type! changes() :: map()
  end
end
