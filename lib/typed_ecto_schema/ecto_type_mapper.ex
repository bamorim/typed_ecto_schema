defmodule TypedEctoSchema.EctoTypeMapper do
  @moduledoc false

  @schema_many_function_name [:embeds_many, :has_many, :many_to_many]

  @schema_assoc_function_name [
    :has_many,
    :has_one,
    :belongs_to,
    :many_to_many
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

  @type field_option :: {:null, boolean()} | {:values, list(atom())}
  @type field_options :: list(field_option)

  @spec type_for(Ecto.Type.t(), function_name(), boolean(), field_options()) ::
          Macro.t()
  def type_for(ecto_type, function_name, nullable_default, opts) do
    ecto_type
    |> base_type_for(opts)
    |> wrap_embeds_many(function_name)
    |> wrap_assoc_type(function_name)
    |> add_nil_if_nullable(field_is_nullable?(nullable_default, function_name, opts))
  end

  # Gets the base type for a given Ecto.Type.t() or an AST representing a referenced type
  @spec base_type_for(Ecto.Type.t() | {String.t(), Ecto.Type.t()} | Macro.t(), field_options()) ::
          Macro.t()
  defp base_type_for({source, actual_type}, opts) when is_binary(source) do
    base_type_for(actual_type, opts)
  end

  defp base_type_for(atom, _opts) when atom in @module_for_ecto_type_keys do
    quote do
      unquote(Map.get(@module_for_ecto_type, atom)).t()
    end
  end

  defp base_type_for(atom, _opts) when atom in @direct_types do
    quote do
      unquote(atom)()
    end
  end

  defp base_type_for(:binary_id, _opts) do
    quote do
      binary()
    end
  end

  defp base_type_for(:id, _opts) do
    quote do
      integer()
    end
  end

  defp base_type_for({:array, type}, opts) do
    quote do
      list(unquote(base_type_for(type, opts)))
    end
  end

  defp base_type_for({:map, type}, opts) do
    quote do
      %{optional(any()) => unquote(base_type_for(type, opts))}
    end
  end

  defp base_type_for({:__aliases__, _, [:Ecto, :Enum]}, opts) do
    opts
    |> Keyword.get(:values, [])
    |> disjunction_typespec()
  end

  defp base_type_for({:__aliases__, _, _} = ast, _opts) do
    quote do
      unquote(ast).t()
    end
  end

  defp base_type_for(atom, opts) when is_atom(atom) do
    case to_string(atom) do
      "Elixir.Ecto.Enum" ->
        opts
        |> Keyword.get(:values, [])
        |> disjunction_typespec()

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

  defp base_type_for(_, _opts) do
    quote do
      any()
    end
  end

  ##
  ## Type Transformation Helpers
  ##

  @spec disjunction_typespec(list(atom())) :: Macro.t()
  defp disjunction_typespec([sole_item]) when is_atom(sole_item) do
    sole_item
  end

  defp disjunction_typespec([first, last]) when is_atom(first) and is_atom(last) do
    quote do
      unquote(first) | unquote(last)
    end
  end

  defp disjunction_typespec([head | tail]) when is_atom(head) do
    quote do
      unquote(head) | unquote(disjunction_typespec(tail))
    end
  end

  # Fallback for `Ecto.Enum` with ill-defined `:values`
  defp disjunction_typespec(_) do
    quote do
      any()
    end
  end

  @spec wrap_assoc_type(Macro.t(), function_name()) :: Macro.t()
  defp wrap_assoc_type(type, function_name) when function_name in @schema_assoc_function_name do
    quote do
      unquote(Ecto.Schema).unquote(function_name)(unquote(type))
    end
  end

  defp wrap_assoc_type(type, _function_name) do
    type
  end

  @spec wrap_embeds_many(Macro.t(), function_name()) :: Macro.t()
  defp wrap_embeds_many(type, :embeds_many) do
    quote do
      list(unquote(type))
    end
  end

  defp wrap_embeds_many(type, _), do: type

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
