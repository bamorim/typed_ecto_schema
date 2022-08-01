defmodule TypedEctoSchema.TypeCheckGen do
  def generate(prefix \\ TypedEctoSchema.Overrides, typecheck_module \\ TypedEctoSchema.TypeCheck) do
    load_modules_starting_with!(["Elixir.Ecto", "Elixir.Decimal"])

    modules_to_override = for {module, _} <- :code.all_loaded(),
      from_libs?(module, [:ecto, :decimal]),
      def_types?(module),
      do: {module, Module.concat(prefix, module)}

    for {source, target} <- modules_to_override do
      source
      |> generate_override_module(target, typecheck_module)
      |> write_file(target)
    end

    modules_to_override
    |> generate_typecheck_module(typecheck_module)
    |> write_file(typecheck_module)
  end

  def generate_typecheck_module(modules_to_override, typecheck_module) do
    overrides = List.flatten(for {source, target} <- modules_to_override, do: overrides_for(source, target))

    code =
      quote do
      if Code.ensure_loaded?(TypeCheck) do
        defmodule unquote(typecheck_module) do
          @moduledoc :REPLACE_WITH_DOCS

          @overrides unquote(Macro.escape(overrides))

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
    end
    |> Macro.to_string()

    new_doc = ~S[
    """
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
    ]

    String.replace(code, ":REPLACE_WITH_DOCS", "#{String.trim(new_doc)}\n")
  end

  defp overrides_for(source, target) do
    {:ok, types} = Code.Typespec.fetch_types(source)

    for {type, {name, _, args}} <- types, type in [:type, :opaque] do
      {{source, name, length(args)}, {target, name, length(args)}}
    end
  end

  def generate_override_module(source, target, typecheck_module) do
    {:ok, types} = Code.Typespec.fetch_types(source)

    overrides =
      for {type_type, {name, type_def, args}} <- types do
        type_def = lazify_user_types(type_def)
        type_code = Code.Typespec.type_to_quoted({name, type_def, args})

        {:@, [context: Elixir],
        [{:"#{type_type}!", [context: Elixir], [type_code]}]}
      end

    quote do
      if Code.ensure_loaded?(TypeCheck) do
        defmodule unquote(target) do
          @moduledoc false

          use unquote(typecheck_module)

          unquote_splicing(overrides)
        end
      end
    end
  end

  defp load_modules_starting_with!(prefixes) do
    for {module_name, _, _} <- :code.all_available() do
      module_name = to_string(module_name)
      if Enum.any?(prefixes, &String.starts_with?(module_name, &1)) do
        Code.ensure_loaded(String.to_atom(module_name))
      end
    end
  end

  defp from_libs?(module, libs) do
    lib_sources = Enum.map(libs, &Mix.Project.deps_paths()[&1])

    try do
      source = module.__info__(:compile)[:source]
      Enum.any?(lib_sources, &child_path?(&1, source))
    rescue
      _ -> false
    end
  end

  defp def_types?(module) do
    try do
      match?({:ok, [_ | _]}, Code.Typespec.fetch_types(module))
    rescue
      _ -> false
    end
  end

  defp child_path?(parent, child) do
    List.starts_with?(Path.split(child), Path.split(parent))
  end

  # Later we could find cycles first, but for now let's put lazy in all of them
  defp lazify_user_types({:user_type, line, name, args}) do
    {:user_type, line, :lazy, [{:user_type, line, name, lazify_args(args)}]}
  end

  defp lazify_user_types({type, line, name, args}) do
    {type, line, name, lazify_args(args)}
  end

  defp lazify_user_types(other), do: other

  defp lazify_args(args) when is_list(args), do: Enum.map(args, &lazify_user_types/1)
  defp lazify_args(args), do: args

  defp write_file(code, module) when is_binary(code) do
    path = Path.join([File.cwd!(), "lib", "#{Macro.underscore(module)}.ex"])

    File.mkdir_p!(Path.dirname(path))
    File.write!(path, code)
  end

  defp write_file(code, module) do
    write_file(Macro.to_string(code), module)
  end
end
