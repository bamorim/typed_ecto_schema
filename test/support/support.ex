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

defmodule TypedEctoSchema.OtherPolymorphicLib do
  @moduledoc false
  # Simulates an unrelated library that happens to define macros with the same
  # names as polymorphic_embed's, but with different behavior (here they even
  # consume the `:null` option themselves).

  defmacro polymorphic_embeds_one(name, opts) do
    quote do
      field(unquote(name), :string, unquote(opts))
    end
  end
end
