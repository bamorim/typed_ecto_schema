if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Query do
    @moduledoc false
    use TypedEctoSchema.TypeCheck

    @opaque! dynamic() :: %Ecto.Query.DynamicExpr{
               binding: term(),
               file: term(),
               fun: term(),
               line: term()
             }
    @type! t() :: %Ecto.Query{
             aliases: term(),
             assocs: term(),
             combinations: term(),
             distinct: term(),
             from: term(),
             group_bys: term(),
             havings: term(),
             joins: term(),
             limit: term(),
             lock: term(),
             offset: term(),
             order_bys: term(),
             prefix: term(),
             preloads: term(),
             select: term(),
             sources: term(),
             updates: term(),
             wheres: term(),
             windows: term(),
             with_ctes: term()
           }
  end
end
