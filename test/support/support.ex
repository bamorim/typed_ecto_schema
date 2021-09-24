defmodule TypedEctoSchema.TestMacros do
  @moduledoc false

  defmacro add_single_field(name, type) do
    quote do
      field(unquote(name), unquote(type))
    end
  end

  defmacro add_two_fields(name0, type0, name1, type1) do
    quote do
      field(unquote(name0), unquote(type0))
      field(unquote(name1), unquote(type1))
    end
  end
end
