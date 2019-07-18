defmodule TypedEctoSchema.TypeBuilder do
  @moduledoc false

  @default_opts null: true, enforce: false, opaque: false

  defmacro init(opts) do
    opts = Keyword.merge(@default_opts, opts)

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
        unquote(opts)
      )
    end
  end

  defmacro enforce_keys do
    quote do
      @enforce_keys @__typed_ecto_schema_enforced_keys__
    end
  end

  defmacro define_type(opts) do
    quote do
      unquote(__MODULE__).__define_type__(
        @__typed_ecto_schema_types__,
        unquote(opts)
      )
    end
  end

  defmacro __define_type__(types, opts) do
    if Keyword.get(opts, :opaque, false) do
      quote bind_quoted: [types: types] do
        @opaque t() :: %__MODULE__{unquote_splicing(types)}
      end
    else
      quote bind_quoted: [types: types] do
        @type t() :: %__MODULE__{unquote_splicing(types)}
      end
    end
  end

  def add_primary_key(mod) do
    case Module.get_attribute(mod, :primary_key) do
      {name, type, opts} ->
        add_field(mod, :field, name, type, opts)

      _ ->
        :ok
    end
  end

  def add_field(mod, macro, name, ecto_type, field_opts) when is_atom(name) do
    mod_opts = Module.get_attribute(mod, :__typed_ecto_schema_module_opts__)

    type =
      TypedEctoSchema.EctoTypeMapper.type_for(
        ecto_type,
        macro,
        Keyword.get(mod_opts, :null),
        Keyword.take(field_opts, [:null])
      )

    overriden_type = Keyword.get(field_opts, :__typed_ecto_type__, type)

    Module.put_attribute(
      mod,
      :__typed_ecto_schema_types__,
      {name, overriden_type}
    )

    if field_is_enforced?(mod_opts, field_opts),
      do: Module.put_attribute(mod, :__typed_ecto_schema_enforced_keys__, name)

    if macro == :belongs_to and Keyword.get(field_opts, :define_field, true) do
      add_field(
        mod,
        :field,
        Keyword.get(field_opts, :foreign_key, :"#{name}_id"),
        Keyword.get(field_opts, :type, :integer),
        field_opts
      )
    end
  end

  def add_field(_mod, _macro, name, _type, _opts) do
    raise ArgumentError, "a field name must be an atom, got #{inspect(name)}"
  end

  defp field_is_enforced?(mod_opts, field_opts) do
    Keyword.get(
      field_opts,
      :enforce,
      Keyword.get(mod_opts, :enforce) && is_nil(field_opts[:default])
    )
  end
end
