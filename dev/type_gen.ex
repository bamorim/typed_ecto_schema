defmodule TypedEctoSchema.TypeCheckGen do
  def generate(prefix \\ TypedEctoSchema.Overrides, typecheck_module \\ TypedEctoSchema.TypeCheck) do
    load_modules_starting_with!(["Elixir.Ecto", "Elixir.Decimal"])

    modules_to_override =
      for {module, _} <- :code.all_loaded(),
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
    overrides =
      List.flatten(for {source, target} <- modules_to_override, do: overrides_for(source, target))

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

    to_lazify = fetch_lazy_types(types)

    overrides =
      for {type_type, {name, type_def, args}} <- types do
        type_def = lazify_user_types(type_def, to_lazify)
        type_code = Code.Typespec.type_to_quoted({name, type_def, args})

        {:@, [context: Elixir], [{:"#{type_type}!", [context: Elixir], [type_code]}]}
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

  defp fetch_lazy_types(types) do
    graph = :digraph.new()

    ids =
      for {_, {name, type, args}} <- types do
        id = {name, length(args)}
        :digraph.add_vertex(graph, id)
        refs = [] |> find_references(type) |> Enum.uniq()

        for ref <- refs do
          :digraph.add_vertex(graph, ref)
          :digraph.add_edge(graph, id, ref)
        end

        id
      end

    # Heuristic: make the most connected nodes lazy first
    ids = Enum.sort_by(ids, &{elem(&1, 1), -length(:digraph.edges(graph, &1))})

    result =
      for id <- ids, reduce: MapSet.new() do
        acc ->
          if :digraph.get_cycle(graph, {:t, 0}) do
            :digraph.del_vertex(graph, id)
            MapSet.put(acc, id)
          else
            acc
          end
      end

    :digraph.delete(graph)

    result
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

  def find_references(refs, {type, _line, name, args}) do
    refs =
      case type do
        :user_type -> [{name, length(args)} | refs]
        _ -> refs
      end

    find_arg_references(refs, args)
  end

  def find_references(refs, _), do: refs

  defp find_arg_references(refs, []), do: refs

  defp find_arg_references(refs, args) when is_list(args) do
    Enum.reduce(args, refs, &find_references(&2, &1))
  end

  defp find_arg_references(refs, _args), do: refs

  defp lazify_user_types({:user_type, line, name, args}, to_lazify) do
    if MapSet.member?(to_lazify, {name, length(args)}) do
      {:user_type, line, :lazy, [{:user_type, line, name, lazify_args(args, to_lazify)}]}
    else
      {:user_type, line, name, lazify_args(args, to_lazify)}
    end
  end

  defp lazify_user_types({type, line, name, args}, to_lazify) do
    {type, line, name, lazify_args(args, to_lazify)}
  end

  defp lazify_user_types(other, _to_lazify), do: other

  defp lazify_args(args, to_lazify) when is_list(args) do
    Enum.map(args, &lazify_user_types(&1, to_lazify))
  end

  defp lazify_args(args, _to_lazify), do: args

  defp write_file(code, module) when is_binary(code) do
    path = Path.join([File.cwd!(), "lib", "#{Macro.underscore(module)}.ex"])

    File.mkdir_p!(Path.dirname(path))
    File.write!(path, code)
  end

  defp write_file(code, module) do
    write_file(Macro.to_string(code), module)
  end
end
