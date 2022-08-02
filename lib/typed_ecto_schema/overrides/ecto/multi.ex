if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Multi do
    @moduledoc false
    use TypedEctoSchema.TypeCheck
    @typep! names() :: MapSet.t()
    @typep! operations() :: [{name(), lazy(operation())}]
    @typep! operation() ::
              {:changeset, Ecto.Changeset.t(), Keyword.t()}
              | {:run, run()}
              | {:put, any()}
              | {:inspect, Keyword.t()}
              | {:merge, merge()}
              | {:update_all, Ecto.Query.t(), Keyword.t()}
              | {:delete_all, Ecto.Query.t(), Keyword.t()}
              | {:insert_all, schema_or_source(), [map() | Keyword.t()], Keyword.t()}
    @typep! schema_or_source() :: binary() | {binary(), module()} | module()
    @type! t() :: %Ecto.Multi{names: names(), operations: operations()}
    @type! name() :: any()
    @type! merge() :: (changes() -> t()) | {module(), atom(), [any()]}
    @type! fun(result) :: (changes() -> result)
    @type! run() ::
             (Ecto.Repo.t(), changes() -> {:ok | :error, any()}) | {module(), atom(), [any()]}
    @type! changes() :: map()
  end
end
