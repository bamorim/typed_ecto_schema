defmodule TypedEctoSchema.SyntaxSugar do
  @moduledoc false
  # Defines the syntax sugar we apply on top of Ecto's DSL
  # This works by transforming calls to Ecto's own macros to also call
  # Our Type Builder

  alias TypedEctoSchema.SyntaxSugar
  alias TypedEctoSchema.TypeBuilder

  @schema_function_names [
    :field,
    :embeds_one,
    :embeds_many,
    :has_one,
    :has_many,
    :belongs_to,
    :many_to_many
  ]

  @embeds_function_names [:embeds_one, :embeds_many]

  @spec apply_to_block(Macro.t(), Macro.Env.t()) :: Macro.t()
  def apply_to_block(block, env) do
    calls =
      case block do
        {:__block__, _, calls} ->
          calls

        call ->
          [call]
      end

    new_calls = Enum.map(calls, &transform_expression(&1, env))

    {:__block__, [], new_calls}
  end

  defp transform_expression({function_name, ctx, [name, schema, [do: block]]}, env)
       when function_name in @embeds_function_names do
    transform_expression({function_name, ctx, [name, schema, [], [do: block]]}, env)
  end

  @spec transform_expression(Macro.t(), Macro.Env.t()) :: Macro.t()
  defp transform_expression({function_name, _, [name, type, opts]}, _env)
       when function_name in @schema_function_names do
    ecto_opts = Keyword.drop(opts, [:__typed_ecto_type__, :enforce, :null])

    quote do
      unquote(function_name)(unquote(name), unquote(type), unquote(ecto_opts))

      unquote(TypeBuilder).add_field(
        __MODULE__,
        unquote(function_name),
        unquote(name),
        unquote(Macro.escape(type)),
        unquote(opts)
      )
    end
  end

  defp transform_expression({function_name, _, [name, type]}, _env)
       when function_name in @schema_function_names do
    quote do
      unquote(function_name)(unquote(name), unquote(type))

      unquote(TypeBuilder).add_field(
        __MODULE__,
        unquote(function_name),
        unquote(name),
        unquote(Macro.escape(type)),
        []
      )
    end
  end

  defp transform_expression({:field, _, [name]}, _env) do
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

  defp transform_expression({:timestamps, _, [opts]} = call, _env) do
    quote do
      unquote(call)

      unquote(TypeBuilder).add_timestamps(
        __MODULE__,
        Keyword.merge(@timestamps_opts, unquote(opts))
      )
    end
  end

  defp transform_expression({function_name, _, [name, schema, opts, [do: block]]}, _env)
       when function_name in @embeds_function_names do
    quote do
      {schema, opts} =
        unquote(SyntaxSugar).__embeds_module__(
          __ENV__,
          unquote(Macro.escape(schema)),
          unquote(opts),
          unquote(Macro.escape(block))
        )

      unquote(function_name)(unquote(name), schema, opts)

      unquote(TypeBuilder).add_field(
        __MODULE__,
        unquote(function_name),
        unquote(name),
        schema,
        opts
      )
    end
  end

  defp transform_expression({:timestamps, ctx, []}, env) do
    transform_expression({:timestamps, ctx, [[]]}, env)
  end

  defp transform_expression({:"::", _, [{function_name, _, [name, ecto_type, opts]}, type]}, env)
       when function_name in @schema_function_names do
    transform_expression(
      {function_name, [], [name, ecto_type, [{:__typed_ecto_type__, Macro.escape(type)} | opts]]},
      env
    )
  end

  defp transform_expression({:"::", _, [{function_name, _, [name, ecto_type]}, type]}, env)
       when function_name in @schema_function_names do
    transform_expression(
      {function_name, [], [name, ecto_type, [__typed_ecto_type__: Macro.escape(type)]]},
      env
    )
  end

  defp transform_expression({:"::", _, [{:field, _, [name]}, type]}, env) do
    transform_expression(
      {:field, [], [name, :string, [__typed_ecto_type__: Macro.escape(type)]]},
      env
    )
  end

  defp transform_expression(unknown, env) do
    expanded = Macro.expand(unknown, env)

    case expanded do
      ^unknown ->
        unknown

      {:__block__, block_context, calls} ->
        new_calls = Enum.map(calls, &transform_expression(&1, env))
        {:__block__, block_context, new_calls}

      call ->
        transform_expression(call, env)
    end
  end

  @doc false
  def __embeds_module__(env, {:__aliases__, _, name}, opts, block) do
    {pk, opts} = Keyword.pop(opts, :primary_key, {:id, :binary_id, autogenerate: true})

    block =
      quote do
        use TypedEctoSchema

        @primary_key unquote(Macro.escape(pk))
        typed_embedded_schema do
          unquote(block)
        end
      end

    module = Module.concat(env.module, Module.concat(name))
    Module.create(module, block, env)
    {module, opts}
  end
end
