defmodule TypedEctoSchema.CompileDepsTest do
  # Regression test for issues #26/#38: `typed_schema` must not add
  # compile-time dependencies that plain `Ecto.Schema` doesn't have.
  #
  # Approach: compile a schema from a string with a compiler tracer attached
  # and record every module referenced at compile time (i.e. traced with
  # `env.function == nil`, which is what makes `mix xref` draw a compile
  # edge). The `join_through:` module of a `many_to_many` must not show up
  # (issue #38), while a custom `Ecto.Type` used with `field` must (that
  # dependency is inherent to Ecto and also proves the tracer setup works).
  #
  # async: false because the compiler tracer option is global.
  use ExUnit.Case, async: false

  @tracer_name __MODULE__.TracerTarget

  defmodule Tracer do
    def trace(event, env) do
      send(TypedEctoSchema.CompileDepsTest.TracerTarget, {:trace, event, env.function})
      :ok
    end
  end

  defmodule Review do
    use Ecto.Schema

    schema "reviews" do
    end
  end

  defmodule Book do
    use Ecto.Schema

    schema "books" do
    end
  end

  defmodule Country do
    use Ecto.Type

    def type, do: :string
    def cast(value), do: {:ok, value}
    def load(value), do: {:ok, value}
    def dump(value), do: {:ok, value}
  end

  test "schema function options do not become compile-time dependencies" do
    compile_time_refs =
      compile_time_refs("""
      defmodule TypedEctoSchema.CompileDepsTest.User do
        use TypedEctoSchema

        typed_schema "users" do
          field(:country, TypedEctoSchema.CompileDepsTest.Country)

          many_to_many(:reviews, TypedEctoSchema.CompileDepsTest.Review,
            join_through: TypedEctoSchema.CompileDepsTest.Book
          )
        end
      end
      """)

    refute Book in compile_time_refs
    assert Country in compile_time_refs
  end

  defp compile_time_refs(source) do
    original_tracers = Code.get_compiler_option(:tracers)
    Process.register(self(), @tracer_name)
    Code.put_compiler_option(:tracers, [Tracer])

    try do
      Code.compile_string(source)
    after
      Code.put_compiler_option(:tracers, original_tracers)
      Process.unregister(@tracer_name)
    end

    collect_compile_time_refs(MapSet.new())
  end

  defp collect_compile_time_refs(acc) do
    receive do
      {:trace, event, nil} ->
        case module_from_event(event) do
          nil -> collect_compile_time_refs(acc)
          module -> collect_compile_time_refs(MapSet.put(acc, module))
        end

      {:trace, _event, _function} ->
        collect_compile_time_refs(acc)
    after
      0 -> acc
    end
  end

  defp module_from_event({:alias_reference, _meta, module}), do: module
  defp module_from_event({:remote_function, _meta, module, _name, _arity}), do: module
  defp module_from_event({:remote_macro, _meta, module, _name, _arity}), do: module
  defp module_from_event({:struct_expansion, _meta, module, _keys}), do: module
  defp module_from_event({:require, _meta, module, _opts}), do: module
  defp module_from_event(_event), do: nil
end
