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

  @polymorphic_embeds_function_names [:polymorphic_embeds_one, :polymorphic_embeds_many]

  # The only options `TypeBuilder.add_field/5` reads. Only these are forwarded
  # to it, because injecting the full options list into the module body would
  # evaluate every value in it at compile time, turning module aliases in
  # options like `:join_through` into compile-time dependencies (issue #38).
  @type_builder_option_names [
    :__typed_ecto_type__,
    :enforce,
    :null,
    :default,
    :values,
    :define_field,
    :foreign_key,
    :type,
    :doc
  ]

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
    # FIX for issue #52: Handle both compile-time keyword lists and runtime AST variable references
    {ecto_opts, builder_opts} =
      if Keyword.keyword?(opts) do
        # If opts is a compile-time keyword list, split keys at compile time.
        # The taken values stay as their original AST (not escaped), so things
        # like `values: @some_attribute` still resolve in the module body.
        {Keyword.drop(opts, [:__typed_ecto_type__, :enforce, :null, :doc]),
         Keyword.take(opts, @type_builder_option_names)}
      else
        # If opts is an AST variable reference, generate code to split keys at runtime
        {quote do
           Keyword.drop(unquote(opts), [:__typed_ecto_type__, :enforce, :null, :doc])
         end,
         quote do
           Keyword.take(unquote(opts), unquote(@type_builder_option_names))
         end}
      end

    quote do
      unquote(function_name)(unquote(name), unquote(type), unquote(ecto_opts))

      unquote(TypeBuilder).add_field(
        __MODULE__,
        unquote(function_name),
        unquote(name),
        unquote(Macro.escape(type)),
        unquote(builder_opts)
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

  # Matches `polymorphic_embeds_one/2` and `polymorphic_embeds_many/2` from the
  # `polymorphic_embed` library purely by name, so it never becomes a dependency.
  # Because of that, the integration is gated behind a compile-time flag and
  # off by default, in case another library defines same-named macros with
  # different behavior. The original call is emitted untouched (minus our extra
  # options) so the real macro still runs.
  defp transform_expression({function_name, _, [name, opts]} = expr, env)
       when function_name in @polymorphic_embeds_function_names do
    cond do
      not polymorphic_embed_enabled?(env) ->
        expand_expression(expr, env)

      Keyword.keyword?(opts) ->
        ecto_opts = Keyword.drop(opts, [:__typed_ecto_type__, :enforce, :null, :doc])

        quote do
          unquote(function_name)(unquote(name), unquote(ecto_opts))

          unquote(TypeBuilder).add_field(
            __MODULE__,
            unquote(function_name),
            unquote(name),
            unquote(Macro.escape(polymorphic_embeds_type(opts))),
            unquote(Keyword.take(opts, [:__typed_ecto_type__, :enforce, :null, :default, :doc]))
          )
        end

      true ->
        expr
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

  defp transform_expression({:timestamps, _, [opts]}, _env) do
    ecto_opts =
      if Keyword.keyword?(opts) do
        Keyword.drop(opts, [:enforce, :null])
      else
        quote do
          Keyword.drop(unquote(opts), [:enforce, :null])
        end
      end

    quote do
      timestamps(unquote(ecto_opts))

      unquote(TypeBuilder).add_timestamps(
        __MODULE__,
        Keyword.merge(Module.get_attribute(__MODULE__, :timestamps_opts, []), unquote(opts))
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

  defp transform_expression({:"::", _, [{function_name, _, [name, opts]}, type]} = expr, env)
       when function_name in @polymorphic_embeds_function_names do
    cond do
      not polymorphic_embed_enabled?(env) ->
        expand_expression(expr, env)

      Keyword.keyword?(opts) ->
        transform_expression(
          {function_name, [], [name, [{:__typed_ecto_type__, Macro.escape(type)} | opts]]},
          env
        )

      true ->
        expr
    end
  end

  defp transform_expression({:"::", _, [{:field, _, [name]}, type]}, env) do
    transform_expression(
      {:field, [], [name, :string, [__typed_ecto_type__: Macro.escape(type)]]},
      env
    )
  end

  defp transform_expression(unknown, env) do
    expand_expression(unknown, env)
  end

  defp expand_expression(unknown, env) do
    expanded = Macro.expand(unknown, env)

    case expanded do
      {:__block__, block_context, calls} ->
        new_calls = Enum.map(calls, &transform_expression(&1, env))
        {:__block__, block_context, new_calls}

      ^unknown ->
        unknown

      call ->
        transform_expression(call, env)
    end
  end

  # Reads the flag at the user's compile time. `Application.compile_env/4`
  # registers the read so schemas get recompiled when the config changes.
  defp polymorphic_embed_enabled?(env) do
    Application.compile_env(env, :typed_ecto_schema, :polymorphic_embed, false)
  end

  # Infers the typespec for a polymorphic embed from the `:types` option AST,
  # without resolving the modules (which would add compile-time dependencies).
  # Falls back to `any()` when the types are not statically known.
  defp polymorphic_embeds_type(opts) do
    types = Keyword.get(opts, :types, [])

    module_types =
      if is_list(types) do
        Enum.map(types, &polymorphic_embed_module_type/1)
      else
        []
      end

    if module_types != [] and Enum.all?(module_types) do
      type_union(module_types)
    else
      quote(do: any())
    end
  end

  defp polymorphic_embed_module_type({type_name, type_opts})
       when is_atom(type_name) and is_list(type_opts) do
    if Keyword.keyword?(type_opts) do
      module_type(Keyword.get(type_opts, :module))
    end
  end

  defp polymorphic_embed_module_type({type_name, module}) when is_atom(type_name) do
    module_type(module)
  end

  defp polymorphic_embed_module_type(_), do: nil

  defp module_type({:__aliases__, _, _} = module), do: quote(do: unquote(module).t())

  defp module_type(module) when is_atom(module) and not is_nil(module),
    do: quote(do: unquote(module).t())

  defp module_type(_), do: nil

  defp type_union([type]), do: type

  defp type_union([type | rest]) do
    quote(do: unquote(type) | unquote(type_union(rest)))
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
