defmodule TypedEctoSchema.TypeBuilder do
  @moduledoc false

  alias Ecto.Schema.Metadata

  @type function_name ::
          :field
          | :embeds_one
          | :embeds_many
          | :has_one
          | :has_many
          | :belongs_to
          | :many_to_many

  @typep schema_option ::
           {:null, boolean()}
           | {:enforce, boolean()}
           | {:opaque, boolean()}

  @type schema_options :: list(schema_option)

  @type field_option :: {atom(), any()}

  @type field_options :: list(field_option)

  @default_schema_opts null: true, enforce: false, opaque: false

  defmacro init(schema_opts) do
    schema_opts = Keyword.merge(@default_schema_opts, schema_opts)

    quote do
      Module.register_attribute(
        __MODULE__,
        :__typed_ecto_schema_types__,
        accumulate: true
      )

      Module.register_attribute(
        __MODULE__,
        :__typed_ecto_schema_enforced_keys__,
        accumulate: true
      )

      Module.put_attribute(
        __MODULE__,
        :__typed_ecto_schema_module_opts__,
        unquote(schema_opts)
      )
    end
  end

  defmacro enforce_keys do
    quote do
      @enforce_keys @__typed_ecto_schema_enforced_keys__
    end
  end

  defmacro define_type(schema_opts) do
    quote do
      unquote(__MODULE__).__define_type__(
        @__typed_ecto_schema_types__,
        unquote(schema_opts)
      )
    end
  end

  defmacro __define_type__(types, schema_opts) do
    if Keyword.get(schema_opts, :opaque, false) do
      quote bind_quoted: [types: types] do
        @opaque t() :: %__MODULE__{unquote_splicing(types)}
      end
    else
      quote bind_quoted: [types: types] do
        @type t() :: %__MODULE__{unquote_splicing(types)}
      end
    end
  end

  @spec add_primary_key(module()) :: :ok
  def add_primary_key(module) do
    case Module.get_attribute(module, :primary_key) do
      {name, type, field_opts} ->
        add_field(module, :field, name, type, field_opts)
        :ok

      _ ->
        :ok
    end
  end

  @spec add_meta(module()) :: :ok
  def add_meta(module) do
    Module.put_attribute(
      module,
      :__typed_ecto_schema_types__,
      {:__meta__,
       quote do
         unquote(Metadata).t()
       end}
    )
  end

  @spec add_timestamps(module(), list({atom(), any()})) :: :ok
  def add_timestamps(module, opts) do
    type = Keyword.get(opts, :type, :naive_datetime)

    with field when not is_boolean(field) <- Keyword.get(opts, :inserted_at, :inserted_at) do
      add_field(module, :field, field, type, [])
    end

    with field when not is_boolean(field) <- Keyword.get(opts, :updated_at, :updated_at) do
      add_field(module, :field, field, type, [])
    end
  end

  @spec add_field(
          module(),
          function_name(),
          atom(),
          Ecto.Type.t(),
          field_options()
        ) :: :ok
  def add_field(mod, function_name, name, ecto_type, field_opts)
      when is_atom(name) do
    schema_opts = Module.get_attribute(mod, :__typed_ecto_schema_module_opts__)

    type =
      TypedEctoSchema.EctoTypeMapper.type_for(
        ecto_type,
        function_name,
        Keyword.get(schema_opts, :null),
        Keyword.take(field_opts, [:null, :values])
      )

    overriden_type = Keyword.get(field_opts, :__typed_ecto_type__, type)

    Module.put_attribute(
      mod,
      :__typed_ecto_schema_types__,
      {name, overriden_type}
    )

    if field_is_enforced?(schema_opts, field_opts),
      do: Module.put_attribute(mod, :__typed_ecto_schema_enforced_keys__, name)

    if function_name == :belongs_to and
         Keyword.get(field_opts, :define_field, true) do
      add_field(
        mod,
        :field,
        Keyword.get(field_opts, :foreign_key, :"#{name}_id"),
        Keyword.get(field_opts, :type, Module.get_attribute(mod, :foreign_key_type, :integer)),
        field_opts
      )
    end

    :ok
  end

  def add_field(_mod, _macro, name, _type, _opts) do
    raise ArgumentError, "a field name must be an atom, got #{inspect(name)}"
  end

  @spec field_is_enforced?(schema_options(), field_options()) :: boolean()
  defp field_is_enforced?(schema_opts, field_opts) do
    Keyword.get(
      field_opts,
      :enforce,
      schema_opts[:enforce] && is_nil(field_opts[:default])
    )
  end
end
