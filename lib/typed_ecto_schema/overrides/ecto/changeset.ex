if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.Overrides.Ecto.Changeset do
    @moduledoc false
    use TypedEctoSchema.TypeCheck
    @type! types() :: map()
    @type! data() :: map()
    @type! constraint() :: %{
             type: :check | :exclusion | :foreign_key | :unique,
             constraint: String.t(),
             match: :exact | :suffix | :prefix,
             field: atom(),
             error_message: String.t(),
             error_type: atom()
           }
    @type! action() :: nil | :insert | :update | :delete | :replace | :ignore | atom()
    @type! error() :: {String.t(), Keyword.t()}
    @type! t() :: lazy(t(Ecto.Schema.t() | map() | nil))
    @type! t(data_type) :: %Ecto.Changeset{
             action: lazy(action()),
             changes: %{optional(atom()) => term()},
             constraints: [lazy(constraint())],
             data: data_type,
             empty_values: term(),
             errors: [{atom(), lazy(error())}],
             filters: %{optional(atom()) => term()},
             params: %{optional(String.t()) => term()} | nil,
             prepare: [(lazy(t()) -> lazy(t()))],
             repo: atom() | nil,
             repo_opts: Keyword.t(),
             required: [atom()],
             types:
               nil | %{required(atom()) => Ecto.Type.t() | {:assoc, term()} | {:embed, term()}},
             valid?: boolean(),
             validations: [{atom(), term()}]
           }
  end
end
