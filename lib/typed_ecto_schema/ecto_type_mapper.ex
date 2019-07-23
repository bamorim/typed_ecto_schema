defmodule TypedEctoSchema.EctoTypeMapper do
  @moduledoc false

  alias Ecto.Association.NotLoaded

  @schema_many_function_name [:embeds_many, :has_many]

  @schema_assoc_function_name [
    :has_many,
    :has_one,
    :belongs_to
  ]

  @module_for_ecto_type %{
    string: String,
    decimal: Decimal,
    date: Date,
    time: Time,
    time_usec: Time,
    naive_datetime: NaiveDateTime,
    naive_datetime_usec: NaiveDateTime,
    utc_datetime: DateTime,
    utc_datetime_usec: DateTime
  }

  @module_for_ecto_type_keys Map.keys(@module_for_ecto_type)
  @direct_types [:integer, :float, :boolean, :map, :binary]

  @type function_name ::
          :field
          | :embeds_one
          | :embeds_many
          | :has_one
          | :has_many
          | :belongs_to

  @type field_option :: {:null, boolean()}
  @type field_options :: list(field_option)

  @spec type_for(Ecto.Type.t(), function_name(), boolean(), field_options()) ::
          Macro.t()
  def type_for(ecto_type, function_name, nullable_default, opts) do
    ecto_type
    |> base_type_for()
    |> wrap_in_list_if_many(function_name)
    |> add_not_loaded_if_assoc(function_name)
    |> add_nil_if_nullable(field_is_nullable?(nullable_default, function_name, opts))
  end

  # Gets the base type for a given Ecto.Type.t()
  @spec base_type_for(Ecto.Type.t()) :: Macro.t()
  defp base_type_for(atom) when atom in @module_for_ecto_type_keys do
    quote do
      unquote(Map.get(@module_for_ecto_type, atom)).t()
    end
  end

  defp base_type_for(atom) when atom in @direct_types do
    quote do
      unquote(atom)()
    end
  end

  defp base_type_for(:binary_id) do
    quote do
      binary()
    end
  end

  defp base_type_for(:id) do
    quote do
      integer()
    end
  end

  defp base_type_for({:array, type}) do
    quote do
      list(unquote(base_type_for(type)))
    end
  end

  defp base_type_for({:map, type}) do
    quote do
      %{optional(any()) => unquote(base_type_for(type))}
    end
  end

  defp base_type_for(atom) when is_atom(atom) do
    case to_string(atom) do
      "Elixir." <> _ ->
        quote do
          unquote(atom).t()
        end

      _ ->
        quote do
          any()
        end
    end
  end

  defp base_type_for(_) do
    quote do
      any()
    end
  end

  ##
  ## Type Transformation Helpers
  ##

  @spec wrap_in_list_if_many(Macro.t(), function_name()) :: Macro.t()
  defp wrap_in_list_if_many(type, function_name)
       when function_name in @schema_many_function_name do
    quote do
      list(unquote(type))
    end
  end

  defp wrap_in_list_if_many(type, _), do: type

  @spec add_not_loaded_if_assoc(Macro.t(), function_name()) :: Macro.t()
  defp add_not_loaded_if_assoc(type, function_name)
       when function_name in @schema_assoc_function_name do
    quote(do: unquote(type) | unquote(NotLoaded).t())
  end

  defp add_not_loaded_if_assoc(type, _), do: type

  @spec add_nil_if_nullable(Macro.t(), nullable :: boolean) :: Macro.t()
  defp add_nil_if_nullable(type, false), do: type
  defp add_nil_if_nullable(type, true), do: quote(do: unquote(type) | nil)

  ##
  ## Field Information Helpers
  ##

  @spec field_is_nullable?(
          default :: boolean(),
          function_name(),
          field_options()
        ) :: boolean()
  defp field_is_nullable?(_default, function_name, _opts)
       when function_name in @schema_many_function_name,
       do: false

  defp field_is_nullable?(_default, function_name, _args)
       when function_name in @schema_assoc_function_name,
       do: true

  defp field_is_nullable?(default, _function_name, opts),
    do: Keyword.get(opts, :null, default)
end
