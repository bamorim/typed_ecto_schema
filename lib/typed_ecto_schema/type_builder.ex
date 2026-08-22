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
          | :polymorphic_embeds_one
          | :polymorphic_embeds_many

  @typep schema_option ::
           {:null, boolean()}
           | {:enforce, boolean()}
           | {:opaque, boolean()}
           | {:additional_types, boolean()}

  @type schema_options :: list(schema_option)

  @type field_option :: {atom(), any()}

  @type field_options :: list(field_option)

  @default_schema_opts null: true, enforce: false, opaque: false, additional_types: false

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

      Module.register_attribute(
        __MODULE__,
        :__typed_ecto_schema_enum_types__,
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

      unquote(__MODULE__).__define_enum_types__(@__typed_ecto_schema_enum_types__)
    end
  end

  defmacro __define_enum_types__(enum_types) do
    quote bind_quoted: [enum_types: enum_types] do
      for {name, type} <- Enum.reverse(enum_types) do
        @type unquote(name)() :: unquote(type)
      end
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

  @enhanced_field_opts [:null, :enforce]

  # Strips the enhanced field options from `@primary_key` before `Ecto.Schema`
  # reads it (it would raise on them), keeping the original for `add_primary_key/1`.
  @spec strip_primary_key_opts(module()) :: :ok
  def strip_primary_key_opts(module) do
    case Module.get_attribute(module, :primary_key) do
      {name, type, field_opts} = primary_key ->
        Module.put_attribute(module, :__typed_ecto_schema_primary_key__, primary_key)

        Module.put_attribute(
          module,
          :primary_key,
          {name, type, Keyword.drop(field_opts, @enhanced_field_opts)}
        )

        :ok

      _ ->
        :ok
    end
  end

  @spec add_primary_key(module()) :: :ok
  def add_primary_key(module) do
    primary_key =
      Module.get_attribute(module, :__typed_ecto_schema_primary_key__) ||
        Module.get_attribute(module, :primary_key)

    case primary_key do
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
    field_opts = Keyword.take(opts, [:null, :enforce])

    with field when not is_boolean(field) <- Keyword.get(opts, :inserted_at, :inserted_at) do
      add_field(module, :field, field, type, field_opts)
    end

    with field when not is_boolean(field) <- Keyword.get(opts, :updated_at, :updated_at) do
      add_field(module, :field, field, type, field_opts)
    end
  end

  @spec add_field(
          module(),
          function_name(),
          atom(),
          Ecto.Type.t() | Macro.t(),
          field_options()
        ) :: :ok
  def add_field(mod, function_name, name, ecto_type, field_opts)
      when is_atom(name) do
    schema_opts = Module.get_attribute(mod, :__typed_ecto_schema_module_opts__)

    type =
      case Keyword.fetch(field_opts, :__typed_ecto_type__) do
        {:ok, overriden_type} ->
          overriden_type

        :error ->
          TypedEctoSchema.EctoTypeMapper.type_for(
            ecto_type,
            function_name,
            Keyword.get(schema_opts, :null),
            Keyword.take(field_opts, [:null, :values])
          )
      end

    Module.put_attribute(
      mod,
      :__typed_ecto_schema_types__,
      {name, type}
    )

    if field_is_enforced?(schema_opts, field_opts),
      do: Module.put_attribute(mod, :__typed_ecto_schema_enforced_keys__, name)

    if Keyword.get(schema_opts, :additional_types, false),
      do: add_enum_type(mod, name, ecto_type, field_opts)

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

  # Fields named `t` are skipped since the type would collide with the schema's own `t/0`.
  @spec add_enum_type(module(), atom(), Ecto.Type.t(), field_options()) :: :ok
  defp add_enum_type(mod, name, ecto_type, field_opts) do
    if name != :t and enum_type?(ecto_type) do
      case enum_values_type(Keyword.get(field_opts, :values)) do
        {:ok, type} ->
          Module.put_attribute(mod, :__typed_ecto_schema_enum_types__, {name, type})

        :error ->
          :ok
      end
    end

    :ok
  end

  @spec enum_type?(Ecto.Type.t() | Macro.t()) :: boolean()
  defp enum_type?({:array, type}), do: enum_type?(type)
  defp enum_type?({:__aliases__, _, [:Ecto, :Enum]}), do: true
  defp enum_type?(Ecto.Enum), do: true
  defp enum_type?(_), do: false

  @spec enum_values_type(any()) :: {:ok, Macro.t()} | :error
  defp enum_values_type([_ | _] = values) do
    cond do
      Enum.all?(values, &is_atom/1) -> {:ok, atoms_to_union(values)}
      Keyword.keyword?(values) -> {:ok, atoms_to_union(Keyword.keys(values))}
      true -> :error
    end
  end

  defp enum_values_type(_values), do: :error

  @spec atoms_to_union(nonempty_list(atom())) :: Macro.t()
  defp atoms_to_union([atom]), do: atom

  defp atoms_to_union([head | tail]) do
    quote do
      unquote(head) | unquote(atoms_to_union(tail))
    end
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
