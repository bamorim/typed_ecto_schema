defmodule TypedEctoSchema.TestMacros do
  @moduledoc false

  defmacro add_field(name, type) do
    quote do
      field(unquote(name), unquote(type))
    end
  end
end
