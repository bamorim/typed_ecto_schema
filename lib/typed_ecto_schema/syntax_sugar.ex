defmodule TypedEctoSchema.SyntaxSugar do
  @moduledoc false
  # Defines the syntax sugar we apply on top of Ecto's DSL
  # This works by transforming calls to Ecto's own macros to also call
  # Our Type Builder

  alias TypedEctoSchema.TypeBuilder

  @schema_function_names [
    :field,
    :embeds_one,
    :embeds_many,
    :has_one,
    :has_many,
    :belongs_to
  ]

  @spec apply_to_block(Macro.t()) :: Macro.t()
  def apply_to_block(block) do
    calls =
      case block do
        {:__block__, _, calls} ->
          calls

        call ->
          [call]
      end

    new_calls = Enum.map(calls, &transform_expression/1)

    {:__block__, [], new_calls}
  end

  @spec transform_expression(Macro.t()) :: Macro.t()
  defp transform_expression({function_name, _, [name, type, opts]})
       when function_name in @schema_function_names do
    ecto_opts = Keyword.drop(opts, [:__typed_ecto_type__, :enforce])

    quote do
      unquote(function_name)(unquote(name), unquote(type), unquote(ecto_opts))

      unquote(TypeBuilder).add_field(
        __MODULE__,
        unquote(function_name),
        unquote(name),
        unquote(type),
        unquote(opts)
      )
    end
  end

  defp transform_expression({function_name, _, [name, type]})
       when function_name in @schema_function_names do
    quote do
      unquote(function_name)(unquote(name), unquote(type))

      unquote(TypeBuilder).add_field(
        __MODULE__,
        unquote(function_name),
        unquote(name),
        unquote(type),
        []
      )
    end
  end

  defp transform_expression({:field, _, [name]}) do
    quote do
      field(unquote(name))

      unquote(TypeBuilder).add_field(
        __MODULE__,
        :field,
        unquote(name),
        :string,
        []
      )
    end
  end

  defp transform_expression(
         {:::, _, [{function_name, _, [name, ecto_type, opts]}, type]}
       )
       when function_name in @schema_function_names do
    transform_expression(
      {function_name, [],
       [name, ecto_type, [{:__typed_ecto_type__, Macro.escape(type)} | opts]]}
    )
  end

  defp transform_expression(
         {:::, _, [{function_name, _, [name, ecto_type]}, type]}
       )
       when function_name in @schema_function_names do
    transform_expression(
      {function_name, [],
       [name, ecto_type, [__typed_ecto_type__: Macro.escape(type)]]}
    )
  end

  defp transform_expression({:::, _, [{:field, _, [name]}, type]}) do
    transform_expression(
      {:field, [], [name, :string, [__typed_ecto_type__: Macro.escape(type)]]}
    )
  end

  defp transform_expression(other), do: other
end
