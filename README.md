# TypedEctoSchema

[![Build Status](https://github.com/bamorim/typed_ecto_schema/actions/workflows/ci.yaml/badge.svg)](https://github.com/bamorim/typed_ecto_schema/actions)
[![Coverage Status](https://coveralls.io/repos/github/bamorim/typed_ecto_schema/badge.svg?branch=master)](https://coveralls.io/github/bamorim/typed_ecto_schema?branch=master)
[![Hex.pm](https://img.shields.io/hexpm/v/typed_ecto_schema.svg)](https://hex.pm/packages/typed_ecto_schema)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/typed_ecto_schema)

TypedEctoSchema provides a DSL on top of `Ecto.Schema` to define schemas with typespecs
without all the boilerplate code.

To add type information to an `Ecto.Schema`, you normally have to keep the fields, the
`@enforce_keys` and a hand-written `@type t()` in sync, repeating every field name three
times:

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

With `typed_ecto_schema` the same schema — typespec, enforced keys and all — is just:

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

## Installation

Add it to your deps:

```elixir
{:typed_ecto_schema, "~> 0.5.0", runtime: false}
```

Then replace `use Ecto.Schema` with `use TypedEctoSchema`, and the calls to `schema` with
`typed_schema` and `embedded_schema` with `typed_embedded_schema`.

## Features

The full documentation lives on [hexdocs](https://hexdocs.pm/typed_ecto_schema). At a
glance:

- [Automatic typespec inference](https://hexdocs.pm/typed_ecto_schema/TypedEctoSchema.html#module-type-inference)
  for fields, associations, embeds and the fields Ecto generates behind the scenes
  (primary key, foreign keys, timestamps, `__meta__`).
- [`::` overrides](https://hexdocs.pm/typed_ecto_schema/TypedEctoSchema.html#module-overriding-the-typespec)
  to narrow or replace any inferred typespec inline.
- [`:null` and `:enforce` options](https://hexdocs.pm/typed_ecto_schema/TypedEctoSchema.html#module-field-options)
  on fields, associations, embeds, `timestamps()` and the
  [`@primary_key` attribute](https://hexdocs.pm/typed_ecto_schema/TypedEctoSchema.html#module-generated-fields),
  controlling nullability and `@enforce_keys`.
- [Field documentation](https://hexdocs.pm/typed_ecto_schema/TypedEctoSchema.html#module-documenting-fields)
  via the `:doc` option, rendered into your `@moduledoc` through a marker and into a
  generated `@typedoc`.
- Experimental:
  [named types for `Ecto.Enum` fields](https://hexdocs.pm/typed_ecto_schema/TypedEctoSchema.html#module-additional-named-types-experimental)
  and a
  [`polymorphic_embed` integration](https://hexdocs.pm/typed_ecto_schema/TypedEctoSchema.html#module-polymorphicembed-integration-experimental).

There is also a [cheatsheet](https://hexdocs.pm/typed_ecto_schema/cheatsheet.html) with
every option at a glance, and a
[changelog](https://hexdocs.pm/typed_ecto_schema/changelog.html).

## Credits

This project started as a fork of the awesome [`typed_struct`].

That being said, I'd like to give some special thanks to

- [Jean-Philippe Cugnet](https://github.com/ejpcmac) for laying the ground for this work.
- [Carlos Brito Lage](https://github.com/cblage) for helping me with planning and ideas about the
  DSL.

[`typed_struct`]: https://github.com/ejpcmac/typed_struct
