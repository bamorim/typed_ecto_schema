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
{:typed_ecto_schema, "~> 0.4.3", runtime: false}
```

And change your `use Ecto.Schema` for `use TypedEctoSchema` and change the calls to `schema` for
`typed_schema` and `embedded_schema` to `typed_embedded_schema`.

The extra `:null` and `:enforce` options also work on the `@primary_key` attribute, so you can
have a non-nullable (and/or enforced) primary key type:

```elixir
@primary_key {:id, :binary_id, autogenerate: true, null: false}
```

Check the [online documentation](https://hexdocs.pm/typed_ecto_schema) for further details.

## PolymorphicEmbed support

[`polymorphic_embed`](https://github.com/mathieuprog/polymorphic_embed)'s
`polymorphic_embeds_one/2` and `polymorphic_embeds_many/2` work out of the box inside
`typed_schema` blocks. The typespec is inferred as the union of the modules listed in the
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
options work just like they do for `field/3`. When the `:types` option cannot be resolved at
compile time (for example, when it is a module attribute), the type falls back to `any()`.

Note that `polymorphic_embed` is not a dependency of this library: the calls are recognized
by name, so you still need to add it to your own deps and import it yourself.

## Credits

This project started as a fork of the awesome [`typed_struct`].

That being said, I'd like to give some special thanks to

- [Jean-Philippe Cugnet](https://github.com/ejpcmac) for laying the ground for this work.
- [Carlos Brito Lage](https://github.com/cblage) for helping me with planning and ideas about the
  DSL.

[`typed_struct`]: https://github.com/ejpcmac/typed_struct
