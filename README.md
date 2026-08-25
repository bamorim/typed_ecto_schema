# TypedEctoSchema

[![Build Status](https://github.com/bamorim/typed_ecto_schema/actions/workflows/ci.yaml/badge.svg)](https://github.com/bamorim/typed_ecto_schema/actions)
[![Coverage Status](https://coveralls.io/repos/github/bamorim/typed_ecto_schema/badge.svg?branch=master)](https://coveralls.io/github/bamorim/typed_ecto_schema?branch=master)

TypedEctoSchema provides a DSL on top of `Ecto.Schema` to define schemas with typespecs without all
the boilerplate code.

For example, if you want to add type information about your `Ecto.Schema`, you normally do something
like this:

```elixir
defmodule Person do
  use Ecto.Schema

  @enforce_keys [:name]

  schema "people" do
    field(:name, :string)
    field(:age, :integer)
    field(:happy, :boolean, default: true)
    field(:phone, :string)
    belongs_to(:company, Company)
    timestamps(type: :naive_datetime_usec)
  end

  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          name: String.t(),
          age: non_neg_integer() | nil,
          happy: boolean(),
          phone: String.t() | nil,
          company_id: integer() | nil,
          company: Company.t() | Ecto.Association.NotLoaded.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }
end
```

With `typed_ecto_schema` you can just do:

```elixir
defmodule Person do
  use TypedEctoSchema

  typed_schema "people" do
    field(:name, :string, enforce: true, null: false)
    field(:age, :integer) :: non_neg_integer() | nil
    field(:happy, :boolean, default: true, null: false)
    field(:phone, :string)
    belongs_to(:company, Company)
    timestamps(type: :naive_datetime_usec)
  end
end
```

Note that the timestamps are nullable by default (a struct that was not inserted yet has `nil`
timestamps). You can opt out with `timestamps(null: false)`.

## Usage

Install it, add to your deps:

```elixir
{:typed_ecto_schema, "~> 0.5.0", runtime: false}
```

And change your `use Ecto.Schema` for `use TypedEctoSchema` and change the calls to `schema` for
`typed_schema` and `embedded_schema` to `typed_embedded_schema`.

The extra `:null` and `:enforce` options also work on the `@primary_key` attribute, so you can
have a non-nullable (and/or enforced) primary key type:

```elixir
@primary_key {:id, :binary_id, autogenerate: true, null: false}
```

### Documenting fields

Fields accept a `doc:` option. Put the `<!-- typed_ecto_schema: fields -->` marker anywhere
in the module's `@moduledoc` and it is replaced at compile time with a markdown list of every
field, its typespec and its doc:

```elixir
defmodule Person do
  @moduledoc """
  A person.

  ## Fields

  <!-- typed_ecto_schema: fields -->
  """

  use TypedEctoSchema

  typed_schema "people" do
    field(:name, :string, null: false, doc: "The person's full name")
    field(:age, :integer)
  end
end
```

renders the marker as:

```markdown
- `id` (`integer() | nil`)
- `name`: The person's full name (`String.t()`)
- `age` (`integer() | nil`)
```

The marker is the only trigger — without it, `doc:` options don't touch the `@moduledoc`.
Independently of the marker, the generated `t/0` gets a `@typedoc` with the same list (unless
the module defines its own, which is kept and gets the same marker interpolation). See the
[online documentation](https://hexdocs.pm/typed_ecto_schema) for the full details.

### Additional named types (experimental)

> **Note:** this feature is experimental and its behavior may change in future releases.

By passing the opt-in `additional_types: true` option to `typed_schema` or
`typed_embedded_schema`, each `Ecto.Enum` field also generates a public type named after the
field, containing the union of its values:

```elixir
defmodule Person do
  use TypedEctoSchema

  typed_schema "people", additional_types: true do
    field(:role, Ecto.Enum, values: [:admin, :user])
  end
end
```

This defines `@type role() :: :admin | :user`, which can be referenced from other modules as
`Person.role()`. Keyword values (`values: [foo: 1, bar: 2]`) generate the union of the atom keys
and `{:array, Ecto.Enum}` fields generate the union of the element values.

Watch out: the type is named after the field, but for list fields it represents a **single
element**, not the list. Since list fields usually have plural names, the name can be
misleading — `field(:roles, {:array, Ecto.Enum}, values: [:admin, :user])` defines
`@type roles() :: :admin | :user` (one role), and when you need the list type you write
`list(Person.roles())`.

Fields whose values
can't be resolved at compile time and fields named `t` (which would conflict with the schema's
own `t/0`) are silently skipped; other name collisions with existing types error at compile time.

It can also be enabled globally through compile-time application config (the schema-level
option still wins in both directions):

```elixir
# config/config.exs
config :typed_ecto_schema, additional_types: true
```

When the PolymorphicEmbed integration is enabled (see below), `polymorphic_embeds_one/2` and
`polymorphic_embeds_many/2` fields also generate a named type with the union of the modules in
their `types:` option — e.g. `polymorphic_embeds_one(:channel, types: [sms: SMS, email: Email])`
defines `@type channel() :: SMS.t() | Email.t()`. The single-element rule above applies to
`polymorphic_embeds_many/2` too: a `:channels` field defines `@type channels() :: SMS.t() |
Email.t()` — the type of one channel, without the `list(...)` wrapper.

Check the [online documentation](https://hexdocs.pm/typed_ecto_schema) for further details.

## PolymorphicEmbed support (experimental)

[`polymorphic_embed`](https://github.com/mathieuprog/polymorphic_embed)'s
`polymorphic_embeds_one/2` and `polymorphic_embeds_many/2` are supported inside
`typed_schema` blocks behind a compile-time flag, disabled by default:

```elixir
# config/config.exs
config :typed_ecto_schema, polymorphic_embed: true
```

The calls are recognized purely by name (so `polymorphic_embed` never becomes a dependency
of this library) — the flag exists because another library could define same-named macros
with different behavior, so only enable it if you use `polymorphic_embed`. With the flag
disabled the calls behave exactly as before. The flag must live in compile-time config
(`config.exs`, not `runtime.exs`) and requires Elixir 1.14+. This integration is
experimental and may change in a future release.

Once enabled, the typespec is inferred as the union of the modules listed in the
`:types` option:

```elixir
defmodule Reminder do
  use TypedEctoSchema

  import PolymorphicEmbed

  typed_schema "reminders" do
    polymorphic_embeds_one(:channel,
      types: [sms: SMS, email: Email],
      on_replace: :update
    )
  end
end
```

This generates `channel: (SMS.t() | Email.t()) | nil`, while `polymorphic_embeds_many`
generates a list of the union instead. The `::` type override and the `:null` and `:enforce`
options work just like they do for `field/3` (and are stripped before the real
`polymorphic_embed` macro runs):

```elixir
# SMS.t() | Email.t() (without `| nil`), and :channel is added to @enforce_keys
polymorphic_embeds_one(:channel,
  types: [sms: SMS, email: Email],
  on_replace: :update,
  null: false,
  enforce: true
)
```

As with `embeds_many`, `:null` has no effect on `polymorphic_embeds_many`, since it is
always initialized to an empty list. When the `:types` option cannot be resolved at
compile time (for example, when it is a module attribute), the type falls back to `any()`.

Since `polymorphic_embed` is not a dependency of this library, you still need to add it to
your own deps and import it in your schema modules yourself.

## Credits

This project started as a fork of the awesome [`typed_struct`].

That being said, I'd like to give some special thanks to

- [Jean-Philippe Cugnet](https://github.com/ejpcmac) for laying the ground for this work.
- [Carlos Brito Lage](https://github.com/cblage) for helping me with planning and ideas about the
  DSL.

[`typed_struct`]: https://github.com/ejpcmac/typed_struct
