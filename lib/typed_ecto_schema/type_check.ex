if Code.ensure_loaded?(TypeCheck) do
  defmodule TypedEctoSchema.TypeCheck do
    @moduledoc """
    If you use TypeCheck, you can use this module to enable our default overrides.

    You can either use this module directly

        defmodule MySchema do
          use TypedEctoSchema.TypeCheck
          use TypedEctoSchema

          typed_schema "source" do
            field(:int, :integer)
          end
        end

    Or you can use `TypedEctoSchema.TypeCheck.overrides/0` instead

        defmodule MySchema do
          use TypeCheck, overrides: TypedEctoSchema.TypeCheck.overrides()
          use TypedEctoSchema

          typed_schema "source" do
            field(:int, :integer)
          end
        end

    This is useful if you also have your own overrides you want to mix in.

    Consider also creating your own `MyApp.TypeCheck` to simplify using it.
    """

    @overrides [
      {{Ecto.Adapter.Transaction, :adapter_meta, 0},
       {TypedEctoSchema.Overrides.Ecto.Adapter.Transaction, :adapter_meta, 0}},
      {{Ecto.Query, :dynamic, 0}, {TypedEctoSchema.Overrides.Ecto.Query, :dynamic, 0}},
      {{Ecto.Query, :t, 0}, {TypedEctoSchema.Overrides.Ecto.Query, :t, 0}},
      {{Ecto.UUID, :raw, 0}, {TypedEctoSchema.Overrides.Ecto.UUID, :raw, 0}},
      {{Ecto.UUID, :t, 0}, {TypedEctoSchema.Overrides.Ecto.UUID, :t, 0}},
      {{Ecto.Adapter, :adapter_meta, 0},
       {TypedEctoSchema.Overrides.Ecto.Adapter, :adapter_meta, 0}},
      {{Ecto.Adapter, :t, 0}, {TypedEctoSchema.Overrides.Ecto.Adapter, :t, 0}},
      {{Ecto.Changeset.Relation, :t, 0},
       {TypedEctoSchema.Overrides.Ecto.Changeset.Relation, :t, 0}},
      {{Ecto.Association, :t, 0}, {TypedEctoSchema.Overrides.Ecto.Association, :t, 0}},
      {{Ecto.Changeset, :types, 0}, {TypedEctoSchema.Overrides.Ecto.Changeset, :types, 0}},
      {{Ecto.Changeset, :data, 0}, {TypedEctoSchema.Overrides.Ecto.Changeset, :data, 0}},
      {{Ecto.Changeset, :constraint, 0},
       {TypedEctoSchema.Overrides.Ecto.Changeset, :constraint, 0}},
      {{Ecto.Changeset, :action, 0}, {TypedEctoSchema.Overrides.Ecto.Changeset, :action, 0}},
      {{Ecto.Changeset, :error, 0}, {TypedEctoSchema.Overrides.Ecto.Changeset, :error, 0}},
      {{Ecto.Changeset, :t, 0}, {TypedEctoSchema.Overrides.Ecto.Changeset, :t, 0}},
      {{Ecto.Changeset, :t, 1}, {TypedEctoSchema.Overrides.Ecto.Changeset, :t, 1}},
      {{Decimal.Context, :t, 0}, {TypedEctoSchema.Overrides.Decimal.Context, :t, 0}},
      {{Decimal, :decimal, 0}, {TypedEctoSchema.Overrides.Decimal, :decimal, 0}},
      {{Decimal, :t, 0}, {TypedEctoSchema.Overrides.Decimal, :t, 0}},
      {{Decimal, :rounding, 0}, {TypedEctoSchema.Overrides.Decimal, :rounding, 0}},
      {{Decimal, :signal, 0}, {TypedEctoSchema.Overrides.Decimal, :signal, 0}},
      {{Decimal, :sign, 0}, {TypedEctoSchema.Overrides.Decimal, :sign, 0}},
      {{Decimal, :exponent, 0}, {TypedEctoSchema.Overrides.Decimal, :exponent, 0}},
      {{Decimal, :coefficient, 0}, {TypedEctoSchema.Overrides.Decimal, :coefficient, 0}},
      {{Ecto.Queryable, :t, 0}, {TypedEctoSchema.Overrides.Ecto.Queryable, :t, 0}},
      {{Ecto.ParameterizedType, :params, 0},
       {TypedEctoSchema.Overrides.Ecto.ParameterizedType, :params, 0}},
      {{Ecto.ParameterizedType, :opts, 0},
       {TypedEctoSchema.Overrides.Ecto.ParameterizedType, :opts, 0}},
      {{Ecto.Association.NotLoaded, :t, 0},
       {TypedEctoSchema.Overrides.Ecto.Association.NotLoaded, :t, 0}},
      {{Ecto.Schema, :embeds_many, 1}, {TypedEctoSchema.Overrides.Ecto.Schema, :embeds_many, 1}},
      {{Ecto.Schema, :embeds_one, 1}, {TypedEctoSchema.Overrides.Ecto.Schema, :embeds_one, 1}},
      {{Ecto.Schema, :many_to_many, 1},
       {TypedEctoSchema.Overrides.Ecto.Schema, :many_to_many, 1}},
      {{Ecto.Schema, :has_many, 1}, {TypedEctoSchema.Overrides.Ecto.Schema, :has_many, 1}},
      {{Ecto.Schema, :has_one, 1}, {TypedEctoSchema.Overrides.Ecto.Schema, :has_one, 1}},
      {{Ecto.Schema, :belongs_to, 1}, {TypedEctoSchema.Overrides.Ecto.Schema, :belongs_to, 1}},
      {{Ecto.Schema, :t, 0}, {TypedEctoSchema.Overrides.Ecto.Schema, :t, 0}},
      {{Ecto.Schema, :embedded_schema, 0},
       {TypedEctoSchema.Overrides.Ecto.Schema, :embedded_schema, 0}},
      {{Ecto.Schema, :schema, 0}, {TypedEctoSchema.Overrides.Ecto.Schema, :schema, 0}},
      {{Ecto.Schema, :prefix, 0}, {TypedEctoSchema.Overrides.Ecto.Schema, :prefix, 0}},
      {{Ecto.Schema, :source, 0}, {TypedEctoSchema.Overrides.Ecto.Schema, :source, 0}},
      {{Ecto.Adapter.Schema, :on_conflict, 0},
       {TypedEctoSchema.Overrides.Ecto.Adapter.Schema, :on_conflict, 0}},
      {{Ecto.Adapter.Schema, :options, 0},
       {TypedEctoSchema.Overrides.Ecto.Adapter.Schema, :options, 0}},
      {{Ecto.Adapter.Schema, :placeholders, 0},
       {TypedEctoSchema.Overrides.Ecto.Adapter.Schema, :placeholders, 0}},
      {{Ecto.Adapter.Schema, :returning, 0},
       {TypedEctoSchema.Overrides.Ecto.Adapter.Schema, :returning, 0}},
      {{Ecto.Adapter.Schema, :constraints, 0},
       {TypedEctoSchema.Overrides.Ecto.Adapter.Schema, :constraints, 0}},
      {{Ecto.Adapter.Schema, :filters, 0},
       {TypedEctoSchema.Overrides.Ecto.Adapter.Schema, :filters, 0}},
      {{Ecto.Adapter.Schema, :fields, 0},
       {TypedEctoSchema.Overrides.Ecto.Adapter.Schema, :fields, 0}},
      {{Ecto.Adapter.Schema, :schema_meta, 0},
       {TypedEctoSchema.Overrides.Ecto.Adapter.Schema, :schema_meta, 0}},
      {{Ecto.Adapter.Schema, :adapter_meta, 0},
       {TypedEctoSchema.Overrides.Ecto.Adapter.Schema, :adapter_meta, 0}},
      {{Ecto.Repo, :t, 0}, {TypedEctoSchema.Overrides.Ecto.Repo, :t, 0}},
      {{Ecto.Multi, :t, 0}, {TypedEctoSchema.Overrides.Ecto.Multi, :t, 0}},
      {{Ecto.Multi, :name, 0}, {TypedEctoSchema.Overrides.Ecto.Multi, :name, 0}},
      {{Ecto.Multi, :merge, 0}, {TypedEctoSchema.Overrides.Ecto.Multi, :merge, 0}},
      {{Ecto.Multi, :fun, 1}, {TypedEctoSchema.Overrides.Ecto.Multi, :fun, 1}},
      {{Ecto.Multi, :run, 0}, {TypedEctoSchema.Overrides.Ecto.Multi, :run, 0}},
      {{Ecto.Multi, :changes, 0}, {TypedEctoSchema.Overrides.Ecto.Multi, :changes, 0}},
      {{Ecto.Adapter.Queryable, :selected, 0},
       {TypedEctoSchema.Overrides.Ecto.Adapter.Queryable, :selected, 0}},
      {{Ecto.Adapter.Queryable, :options, 0},
       {TypedEctoSchema.Overrides.Ecto.Adapter.Queryable, :options, 0}},
      {{Ecto.Adapter.Queryable, :cached, 0},
       {TypedEctoSchema.Overrides.Ecto.Adapter.Queryable, :cached, 0}},
      {{Ecto.Adapter.Queryable, :prepared, 0},
       {TypedEctoSchema.Overrides.Ecto.Adapter.Queryable, :prepared, 0}},
      {{Ecto.Adapter.Queryable, :query_cache, 0},
       {TypedEctoSchema.Overrides.Ecto.Adapter.Queryable, :query_cache, 0}},
      {{Ecto.Adapter.Queryable, :query_meta, 0},
       {TypedEctoSchema.Overrides.Ecto.Adapter.Queryable, :query_meta, 0}},
      {{Ecto.Adapter.Queryable, :adapter_meta, 0},
       {TypedEctoSchema.Overrides.Ecto.Adapter.Queryable, :adapter_meta, 0}},
      {{Ecto.Type, :composite, 0}, {TypedEctoSchema.Overrides.Ecto.Type, :composite, 0}},
      {{Ecto.Type, :base, 0}, {TypedEctoSchema.Overrides.Ecto.Type, :base, 0}},
      {{Ecto.Type, :custom, 0}, {TypedEctoSchema.Overrides.Ecto.Type, :custom, 0}},
      {{Ecto.Type, :primitive, 0}, {TypedEctoSchema.Overrides.Ecto.Type, :primitive, 0}},
      {{Ecto.Type, :t, 0}, {TypedEctoSchema.Overrides.Ecto.Type, :t, 0}},
      {{Ecto.Query.Builder, :quoted_type, 0},
       {TypedEctoSchema.Overrides.Ecto.Query.Builder, :quoted_type, 0}},
      {{Ecto.Schema.Metadata, :t, 0}, {TypedEctoSchema.Overrides.Ecto.Schema.Metadata, :t, 0}},
      {{Ecto.Schema.Metadata, :t, 1}, {TypedEctoSchema.Overrides.Ecto.Schema.Metadata, :t, 1}},
      {{Ecto.Schema.Metadata, :context, 0},
       {TypedEctoSchema.Overrides.Ecto.Schema.Metadata, :context, 0}},
      {{Ecto.Schema.Metadata, :state, 0},
       {TypedEctoSchema.Overrides.Ecto.Schema.Metadata, :state, 0}}
    ]
    defmacro __using__(opts) do
      quote do
        use TypeCheck, unquote(opts) ++ [overrides: unquote(Macro.escape(@overrides))]
      end
    end

    def overrides do
      @overrides
    end
  end
end
