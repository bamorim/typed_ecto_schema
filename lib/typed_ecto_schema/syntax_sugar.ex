defmodule TypedEctoSchema.SyntaxSugar do
  @moduledoc false
  # Defines the syntax sugar we apply on top of Ecto's DSL
  # This works by transforming calls to Ecto's own macros to also call
  # Our Type Builder

  alias TypedEctoSchema.TypeBuilder

  @schema_macros [
    :field,
    :embeds_one,
    :embeds_many,
    :has_one,
    :has_many,
    :belongs_to
  ]

  def apply_to_block(block) do
    calls =
      case block do
        {:__block__, _, calls} ->
          calls

        call ->
          [call]
      end

    new_calls = Enum.map(calls, &apply_syntax_sugar/1)

    {:__block__, [], new_calls}
  end

  defp apply_syntax_sugar({macro, _, [name, type, opts]})
       when macro in @schema_macros do
    ecto_opts = Keyword.drop(opts, [:__typed_ecto_type__, :enforce])

    quote do
      unquote(macro)(unquote(name), unquote(type), unquote(ecto_opts))

      unquote(TypeBuilder).add_field(
        __MODULE__,
        unquote(macro),
        unquote(name),
        unquote(type),
        unquote(opts)
      )
    end
  end

  defp apply_syntax_sugar({macro, _, [name, type]})
       when macro in @schema_macros do
    quote do
      unquote(macro)(unquote(name), unquote(type))

      unquote(TypeBuilder).add_field(
        __MODULE__,
        unquote(macro),
        unquote(name),
        unquote(type),
        []
      )
    end
  end

  defp apply_syntax_sugar({:field, _, [name]}) do
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

  defp apply_syntax_sugar({:::, _, [{macro, _, [name, ecto_type, opts]}, type]})
       when macro in @schema_macros do
    apply_syntax_sugar(
      {macro, [],
       [name, ecto_type, [{:__typed_ecto_type__, Macro.escape(type)} | opts]]}
    )
  end

  defp apply_syntax_sugar({:::, _, [{macro, _, [name, ecto_type]}, type]})
       when macro in @schema_macros do
    apply_syntax_sugar(
      {macro, [], [name, ecto_type, [__typed_ecto_type__: Macro.escape(type)]]}
    )
  end

  defp apply_syntax_sugar({:::, _, [{:field, _, [name]}, type]}) do
    apply_syntax_sugar(
      {:field, [], [name, :string, [__typed_ecto_type__: Macro.escape(type)]]}
    )
  end

  defp apply_syntax_sugar(other), do: other
end
