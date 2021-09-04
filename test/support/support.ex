defmodule TypedEctoSchema.TestMacros do
  defmacro add_field(name, type) do
    quote do
      field(unquote(name), unquote(type))
    end
  end
end
